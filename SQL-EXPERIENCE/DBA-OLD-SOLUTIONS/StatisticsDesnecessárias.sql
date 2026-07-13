----------------------------------------------------------------------------------------------------------------------------------------
--Al�m de estat�sticas n�o utilizados, voc� pode encontrar estat�sticas que se sobrep�em, 
--que s�o abrangidos por outras estat�sticas. O script a seguir a partir de
--Kendal Van Dyke ir� identificar todas as estat�sticas de coluna �nica que s�o cobertos 
--por uma estat�stica �ndice existente (compartilham a mesma coluna �
--esquerda) em um banco de dados e gera os comandos TSQL para solt�-los.
-- FONTES
-- http://www.kendalvandyke.com/2010/09/tuning-tip-identifying-overlapping.html
-- https://www.pythian.com/blog/sql-server-statistics-YOUR_DATABASE-and-best-practices/
----------------------------------------------------------------------------------------------------------------------------------------
use P_YOUR_DATABASE_TDE
go

;WITH autostats ( object_id, stats_id, name, column_id )
 
AS ( SELECT   sys.stats.object_id ,
 
	sys.stats.stats_id ,
 
	sys.stats.name ,
 
	sys.stats_columns.column_id
 
	FROM     sys.stats
 
	INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id
 
	AND sys.stats.stats_id = sys.stats_columns.stats_id
 
	WHERE    sys.stats.auto_created = 1
 
	AND sys.stats_columns.stats_column_id = 1
 
	)
 
SELECT  OBJECT_NAME(sys.stats.object_id) AS [Table] ,
 
sys.columns.name AS [Column] ,
 
sys.stats.name AS [Overlapped] ,
 
autostats.name AS [Overlapping] ,
 
'DROP STATISTICS [' + OBJECT_SCHEMA_NAME(sys.stats.object_id)
 
+ '].[' + OBJECT_NAME(sys.stats.object_id) + '].['
 
+ autostats.name + ']' AS Query
 
FROM    sys.stats
 
INNER JOIN sys.stats_columns ON sys.stats.object_id = sys.stats_columns.object_id
 
AND sys.stats.stats_id = sys.stats_columns.stats_id
 
INNER JOIN autostats ON sys.stats_columns.object_id = autostats.object_id
 
AND sys.stats_columns.column_id = autostats.column_id
 
INNER JOIN sys.columns ON sys.stats.object_id = sys.columns.object_id
 
AND sys.stats_columns.column_id = sys.columns.column_id
 
WHERE   sys.stats.auto_created = 0
 
AND sys.stats_columns.stats_column_id = 1
 
AND sys.stats_columns.stats_id != autostats.stats_id
 
AND OBJECTPROPERTY(sys.stats.object_id, 'IsMsShipped') = 0







