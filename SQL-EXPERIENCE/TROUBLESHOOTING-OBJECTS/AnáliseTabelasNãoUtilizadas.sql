-- Referência: Gustavo MVP
-- Não raras às vezes
-- aparecem situações nas quais a existência de uma ou mais tabelas é questionável. Isso é bem comum de acontecer, pois, as
-- aplicações evoluem e é normal que novas tabelas surjam e tabelas mais antigas deixem de ser utilizadas. Há também casos onde
-- um acesso indevido (leia­se desenvolvedores com acesso a produção) acaba produzindo aquelas tabelas com o intuito de fazer
-- algum teste rápido na área de produção (normalmente o teste é concluído, mas as tabelas não são excluídas e podem ficar lá
-- durante anos). O fato é que mais tabelas incorrem em mais espaço, mais rotinas de administração, maior janela de backup e
-- certamente um desperdício de recursos.

---------------------------------------------------------------------------------------------------------------------------------------
-- Com DMV é possível ver tabela que não sofreu nenhum acesso quer seja de leitura ou de gravação.
-- Abaixo exemplo:
---------------------------------------------------------------------------------------------------------------------------------------
use GesCooper90
go
SELECT Name FROM sys.tables As T
WHERE NOT EXISTS 
(
	SELECT * FROM sys.dm_db_index_usage_stats As U
	WHERE T.object_id = U.object_id AND U.database_id = DB_ID()
)

/*###############################################	A T E N Ç Ã O	####################################################################
--A estratégia é interessante, mas é preciso lembrar que a sys.dm_db_index_usage_stats, assim como toda DMV, é
--automaticamente zerada quando o SQL Server é reiniciado. Se uma tabela é utilizada na produção de relatórios mensais,
--trimestrais, anuais, etc e houver a reinicialização do SQL Server entre esses intervalos, é possível inferir erroneamente que uma
--tabela não é utilizada (mesmo que ela seja).
#######################################################################################################################################*/


----------------------------------------------------------------------------------------------------------------------------------------
-- Elimina dinamicamente as tabelas sem registros e com determinada data de criação
-- Necessário validar campo modify_date onde é registrado data da última modificação do objeto.
----------------------------------------------------------------------------------------------------------------------------------------
DECLARE @yearDateCreate INT,
		@restante INT,
		@exclusao varchar(200),
		@tables varchar(100)

		SET @yearDateCreate = 2012	-- filtro de teste
		SET @restante = 
					(SELECT count(x.totaisRestantes)
					 FROM
						(SELECT O.name as totaisRestantes
						 FROM SYS.OBJECTS AS O INNER JOIN SYS.DM_DB_PARTITION_STATS AS S
									ON O.OBJECT_ID=S.OBJECT_ID
						  WHERE O.TYPE='U'
						  and YEAR(O.create_date) = @yearDateCreate
						  GROUP BY O.NAME
						  HAVING SUM(S.ROW_COUNT) = 0
						  ) as x
					 )
		print 'Tabelas vazias dropadas: '
		WHILE (@restante > 0)
		BEGIN
			SELECT top(1) @tables = O.NAME
				FROM SYS.OBJECTS AS O 
					INNER JOIN SYS.DM_DB_PARTITION_STATS AS S
						ON O.OBJECT_ID=S.OBJECT_ID
			WHERE O.TYPE='U'
			and YEAR(O.create_date) = @yearDateCreate
			GROUP BY O.NAME
			HAVING SUM(S.ROW_COUNT) = 0

			set @exclusao = ('drop table ' + @tables)

			execute (@exclusao);
			
			print '-> '+ @tables
			-- após o drop o valor de decremento é atualizado
			SET @restante = 
					(SELECT count(x.totaisRestantes)
					 FROM
						(SELECT O.name as totaisRestantes
						 FROM SYS.OBJECTS AS O INNER JOIN SYS.DM_DB_PARTITION_STATS AS S
									ON O.OBJECT_ID=S.OBJECT_ID
						  WHERE O.TYPE='U'
						  and YEAR(O.create_date) = @yearDateCreate
						  GROUP BY O.NAME
						  HAVING SUM(S.ROW_COUNT) = 0
						  ) as x
					 )																	
		END

------------------------------------------------------------------------------------------------------------------
-- Exemplo de tabelas sem sentido
------------------------------------------------------------------------------------------------------------------
SELECT O.NAME, O.modify_date, SUM(S.ROW_COUNT) as totalRegistros
FROM SYS.OBJECTS AS O INNER JOIN SYS.DM_DB_PARTITION_STATS AS S
			ON O.OBJECT_ID=S.OBJECT_ID
			WHERE O.TYPE='U'
			--and YEAR(O.modify_date) <= 2012
			GROUP BY O.NAME, O.modify_date -- campo mostra última vez que tabela sofreu DML
			HAVING SUM(S.ROW_COUNT) = 0


------------------------------------------------------------------------------------------------------------------
-- prova da relação de tabelas com zero registros
------------------------------------------------------------------------------------------------------------------
--select * from sys.dm_db_partition_stats as qt
--where qt.object_id = 55086

--select tb.name from sys.tables as tb
--where tb.object_id = 55086


------------------------------------------------------------------------------------------------------------------
-- tabela povoada movestoque
------------------------------------------------------------------------------------------------------------------
--select tb.name, TB.object_id
--from sys.tables as tb
--where tb.name = 'MOVESTOQUE'

--select * from sys.dm_db_partition_stats as qt
--where qt.object_id = 712389607

------------------------------------------------------------------------------------------------
--TABELAS SEM REGISTRO
------------------------------------------------------------------------------------------------
USE GesCooper90
GO
SELECT O.NAME, SUM(S.ROW_COUNT) AS TuplasTotais 
	FROM SYS.OBJECTS O 
		INNER JOIN SYS.DM_DB_PARTITION_STATS S 
			ON O.OBJECT_ID=S.OBJECT_ID
WHERE O.TYPE='U'
GROUP BY O.NAME
HAVING SUM(S.ROW_COUNT) = 0


------------------------------------------------------------------------------------------------
--TODAS TABELAS COM TOTAL DE LINHAS CADA
------------------------------------------------------------------------------------------------
SELECT O.NAME, SUM(S.ROW_COUNT) AS TuplasPorTabela
	FROM SYS.OBJECTS O 
		INNER JOIN SYS.DM_DB_PARTITION_STATS S 
			ON O.OBJECT_ID=S.OBJECT_ID
WHERE O.TYPE='U'
GROUP BY O.NAME
ORDER BY SUM(S.ROW_COUNT) DESC


------------------------------------------------------------------------------------------------
--Traz o mesmo resultado para tabelas sem registro
------------------------------------------------------------------------------------------------
SELECT DISTINCT OBJECT_NAME(object_id) AS TabelasVazias 
FROM sys.partitions
WHERE rows = 0 
and OBJECTPROPERTY(object_id,'isusertable') = 1


------------------------------------------------------------------------------------------------
-- trazendo todas com seu tamanho
-- Declara uma tabela temporária
-- A tabela será usada para coletar as métricas de todas as tabelas
-- OBS.: GUSTAVO MAIA AGUIAR
------------------------------------------------------------------------------------------------
CREATE TABLE #Resumo (
    Name NVARCHAR(128),
    Rows CHAR(11),
    Reserved VARCHAR(18),
    Data VARCHAR(18),
    Index_Size VARCHAR(18),
    Unused VARCHAR(18))

-- Declara uma variável para armazenar o nome da tabela
DECLARE @Tabela NVARCHAR(128)

-- Declara um cursor para ler todas as tabelas
DECLARE Tabelas CURSOR
FAST_FORWARD FOR
SELECT TABLE_SCHEMA + '.' + TABLE_NAME FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'

OPEN Tabelas

FETCH NEXT FROM Tabelas INTO @Tabela

WHILE @@FETCH_STATUS = 0
BEGIN
    INSERT INTO #Resumo EXEC sp_spaceused @Tabela
    FETCH NEXT FROM Tabelas INTO @Tabela    
END

CLOSE Tabelas

DEALLOCATE Tabelas

-- Retorna as métricas
SELECT Name, Rows, Reserved, Data, Index_Size, Unused FROM #Resumo

DROP TABLE #Resumo


------------------------------------------------------------------------------------------------
-- Traz o mesmo resultado do script de cima
------------------------------------------------------------------------------------------------
SELECT
    OBJECT_NAME(object_id) As Tabela, Rows As Linhas,
    SUM(Total_Pages * 8) As Reservado,
    SUM(CASE WHEN Index_ID > 1 THEN 0 ELSE Data_Pages * 8 END) As Dados,
        SUM(Used_Pages * 8) -
        SUM(CASE WHEN Index_ID > 1 THEN 0 ELSE Data_Pages * 8 END) As Indice,
    SUM((Total_Pages - Used_Pages) * 8) As NaoUtilizado
FROM
    sys.partitions As P
    INNER JOIN sys.allocation_units As A ON P.hobt_id = A.container_id
GROUP BY OBJECT_NAME(object_id), Rows
ORDER BY Tabela