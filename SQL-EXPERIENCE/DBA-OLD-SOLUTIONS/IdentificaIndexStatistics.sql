--------------------------------------------------------------------------------------------------------------
--Lista os campos correspondentes aos índices criados
--------------------------------------------------------------------------------------------------------------
USE GesCooper90;
GO
SELECT i.name AS index_name
    ,COL_NAME(ic.object_id,ic.column_id) AS column_name
    ,ic.index_column_id  --ID da coluna de índice. index_column_id é exclusivo somente dentro de index_id.
    ,ic.key_ordinal
,ic.is_included_column
FROM sys.indexes AS i
INNER JOIN sys.index_columns AS ic 
    ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('movestoque')
ORDER BY i.name

---------------------------------------------------------------------------------------------------------------
--ver quantos índices tem na tabela
---------------------------------------------------------------------------------------------------------------
USE GesCooper90
GO
select 
i.index_id as Id, 
i.name as Nome
from sys.indexes as i inner join sys.tables as t
	on t.object_id = i.object_id
where t.name = 'CONTABIL'

---------------------------------------------------------------------------------------------------------------
--ver quantas statistics tem na tabela
---------------------------------------------------------------------------------------------------------------
select 
s.stats_id as Id,
s.name as Nome
from sys.stats as s inner join sys.tables as t
	on t.object_id = s.object_id
where t.name = 'CONTABIL'

----------------------------------------------------------------------------------------------------------------
--ver statistics para determinado campo de uma tabela
----------------------------------------------------------------------------------------------------------------
SELECT t.name as [Table Name]
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
and c.name in ('NfPedCod', 'NfFilCod', 'NfDatEmis')

---------------------------------------------------------------------------------------------------
DBCC SHOW_STATISTICS ('MOVESTOQUE', nfDatEmis) with stat_header;
GO 
---------------------------------------------------------------------------------------------------

select * from sys.columns as t
WHERE t.object_id = 712389607

select * from sys.tables as t
where t.name = 'MOVESTOQUE'

SELECT t.name as [Table Name]
       , s.name as [Stat Name]
       , stats_id as [Stat Id]
       , stats_date(s.object_id, stats_id) as [Last Updated]
       , s.auto_created -- se for 1 foi automático
       , s.user_created -- se for 1 foi criado pelo usuário
       , s.has_filter   -- 1 é quando é criado um índice nonclustered com a cláusula where(filtrado)
FROM sys.stats s
join sys.tables t on s.object_id = t.object_id
where t.name = 'MOVESTOQUE'

---------------------------------------------------------------------------------------------------------
use GesCooper_TI
select
 i.id as ObjectId, 
 t.name as TableName,
 i.indid as Index_Stat_Id,      -- id de statistics na tabela sysindexes
 i.name as Nome_statistics,		-- nome de statistics para coluna da tabela 
 i.rowmodctr as Status_DML, 
 i.rows as Total_Rows_Column,   -- Nº de linhas que tem statistics por coluna
 i.dpages
from sysindexes i 
inner join sys.tables t on i.id = t.object_id
where t.name = 'MOVESTOQUE'
and i.rowmodctr > 3543341 -- número para que isto tenha que ficar zerado
order by i.rowmodctr

--------------------------------------------------------------------------------------------------------------
--1º - Verificar qual Fill Factor atual das tabelas (Informar apenas o valor da coluna fill factor):
--------------------------------------------------------------------------------------------------------------
select sys.tables.name as tabela, sys.indexes.name as indice, 
        sys.indexes.type_desc as tipo , sys.indexes.fill_factor, sys.indexes.is_padded as padded
        from sys.indexes
inner join  sys.tables
on sys.indexes.object_id = sys.tables.object_id
where sys.indexes.is_disabled =0 and sys.indexes.type <> 0
order by tabela, tipo

--------------------------------------------------------------------------------------------------------------
--2º - Verificar a alocação de espaço da sua base
--------------------------------------------------------------------------------------------------------------
use IntegraTICravil
exec sp_spaceused

---------------------------------------------------------------------------------------------------------------