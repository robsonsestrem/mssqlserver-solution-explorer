SET STATISTICS IO ON

SET STATISTICS TIME ON
/*
para as tabelas com mais de 500 tuplas, o statistics update é realizado 
quando o valor na coluna rowmodctr da tabela sys.sysindexes passar de
500 + 20% do total da tabela a ser atualizada.
*/
--------------------------------------------------------------------------------------------------------
--Atualiza as statistics, porém da base toda.
--------------------------------------------------------------------------------------------------------
BEGIN TRAN
EXEC sp_updatestats; 


--------------------------------------------------------------------------------------------------------
-- Atualiza somente da tabela
--------------------------------------------------------------------------------------------------------
BEGIN TRAN
UPDATE STATISTICS MOVESTOQUE -- Atualiza tabela inteira
WITH FULLSCAN, ALL
GO


--------------------------------------------------------------------------------------------------------
--Atualiza com o nome da statistics
--------------------------------------------------------------------------------------------------------
update statistics MOVESTOQUE IMOVESTOQUE27


--------------------------------------------------------------------------------------------------------
-- Campos pertencentes de cada statistics
-- Busca todas statísticas criadas com o devido campo de uma tabela
--------------------------------------------------------------------------------------------------------
EXEC sp_helpstats 'MOVESTOQUE', 'all' 


--------------------------------------------------------------------------------------------------------
--Lista objetos de estatísticas para as tabelas do banco
--O campo auto_created armazena o valor “1”, confirmando a criação automática
--------------------------------------------------------------------------------------------------------
USE GesCooper90
GO
SELECT * FROM sys.stats
WHERE object_id = OBJECT_ID('CONTABIL')


--------------------------------------------------------------------------------------------------------
--Identificar última atualização das statistics
--------------------------------------------------------------------------------------------------------
SELECT 
	deriva.column_id,
	deriva.coluna,
	deriva.[Table Name],
	deriva.[Stat Id],
	deriva.[Stat Name],
	deriva.Last_Updated,
	deriva.auto_created,
	deriva.user_created,
	deriva.has_filter
FROM

(SELECT t.name as [Table Name]
	   , c.name as coluna
	   , c.column_id
       , s.name as [Stat Name]
       , stats_id as [Stat Id]
       , stats_date(s.object_id, stats_id) as Last_Updated
       , s.auto_created -- se for 1 foi automático
       , s.user_created -- se for 1 foi criado pelo usuário
       , s.has_filter   -- 1 é quando é criado um índice nonclustered com a cláusula where(filtrado)
FROM sys.stats as s
inner join sys.tables as t 
on s.object_id = t.object_id inner join sys.columns as c
on c.object_id = t.object_id
where t.name = 'MOVESTOQUE'
and c.name in ('NfDatEmis')

) AS deriva

ORDER BY deriva.Last_Updated


--------------------------------------------------------------------------------------------------------
-- indica a quantidade de mudanças (insert, update, delete) desde
-- a última atualização.
-- A coluna rowmodctr da view de compatibilidade sysindexes
--------------------------------------------------------------------------------------------------------
select
 i.id as ObjectId, 
 t.name as TableName,
 i.indid as Index_Stat_Id,    -- id de statistics na tabela sysindexes
 i.name as Index_Stat_Name,   -- nome de statistics para coluna da tabela 
 i.rowmodctr as Status_DML,	  -- número de alterações que sofreu desde última atualização
 i.rows as Total_Rows_Column, -- Nº de linhas que tem statistics por coluna
 i.dpages
from sysindexes i 
join sys.tables t on i.id = t.object_id
where t.name = 'MOVESTOQUE'


--------------------------------------------------------------------------------------------------------
--Outra forma de verificar última atualização de um campo da tabela, 
--Obs.: trazer nome da estatística no parâmetro
--Note que utilizamos a opção with stat_header para exibir apenas o cabeçalho do objeto
--------------------------------------------------------------------------------------------------------
DBCC SHOW_STATISTICS ('MOVESTOQUE', _WA_Sys_0000000D_2A7633E7) with stat_header;
GO    
-- Rows nesta consulta significa nº de tuplas que tinha na última update statistics

-->>>3 formas de criação de estatísticas:
--<> Automática: quando criada automaticamente pelo query processor;
--<> Explícita: quando criada explicitamente pelo usuário (CREATE STATISTICS);
--<> Implícita: quando criada como decorrência da criação de índices.

-- Quando o contador do rowmodctr atingir 20% do total de tuplas do campo + 500 de 
-- mudanças, o automático deve zerar o rowmodctr,  senão fazer manualmente.





--------------------------------------------------------------------------------------------------------
/* exemplo do MSDN
USE AdventureWorks2012;
GO
UPDATE STATISTICS Production.Product(Products)
    WITH FULLSCAN;
GO
--------------------------------------------------------------------------------------------------------
UPDATE STATISTICS table_or_indexed_view_name 
nome da tabela ou nome do statistcs ou da view	
*/

