--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Usando windows function para trazer a última atualização dos dados
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go

;with conjunto
as
(
select LAST_VALUE(t1.DateReference) OVER (ORDER BY t1.DateReference ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS 'LAST_VAL', t1.DateReference,
t1.DatabaseName, t1.SchemaName, t1.TableName, t1.IndexName, IndexTypeDesc, t1.AvgFragmentationInPercent
, t1.AvgPageSpaceUsedInPercent, t1.IndexLevel, t1.IndexDepth
, t1.[PageCount] , t1.RecordCount, t1.IndexUsage, t1.IndexUserScans, t1.IndexUserSeeks, t1.IndexUserLookups
from Management.HistoryIndexFragmentation as t1
where t1.DatabaseName = 'IntegraTICravil'
and t1.AvgFragmentationInPercent > 5
and t1.PageCount > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0

)
select * from conjunto as x
where x.DateReference = x.LAST_VAL
order by x.TableName asc, x.AvgFragmentationInPercent desc
--and t1.AvgPageSpaceUsedInPercent > 75


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando o script - Modelo 1
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
;with conjunto
as
(
select
'ALTER INDEX '+ t1.IndexName +' ON '+ t1.DatabaseName + '.' + t1.SchemaName + '.' + t1.TableName + ' '
+ case when t1.AvgFragmentationInPercent < 30 then 'REORGANIZE'
	   else 'REBUILD'
  end
+ '; BACKUP LOG IntegraTICravil TO DISK = ''G:\Backup\IntegraTICravil_log.TRN'' WITH INIT;'
AS SCRIPTS
, LAST_VALUE(t1.DateReference) OVER (ORDER BY t1.DateReference ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS 'LAST_VAL', t1.DateReference, t1.PageCount, t1.AvgFragmentationInPercent
from Management.HistoryIndexFragmentation as t1
where t1.DatabaseName = 'IntegraTICravil'
and t1.AvgFragmentationInPercent > 5
and t1.PageCount > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0

)
select x.SCRIPTS, x.PageCount, x.AvgFragmentationInPercent, x.DateReference
from conjunto as x
where x.DateReference = x.LAST_VAL
order by x.PageCount desc -- buscando os maiores índices por 1º


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando o script - Modelo 2
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select 
'ALTER INDEX '+ x.IndexName +' ON '+ x.DatabaseName + '.' + x.SchemaName + '.' + x.TableName + ' '
+ case when x.AvgFragmentationInPercent < 30 then 'REORGANIZE'
	   else 'REBUILD'
  end
--+ '; BACKUP LOG IntegraTICravil TO DISK = ''G:\Backup\IntegraTICravil_log.TRN'' WITH INIT;'
AS SCRIPTS, x.DateReference, x.[PageCount], x.AvgFragmentationInPercent
from 
(
select   max(t1.DateReference) OVER(ORDER BY t1.DateReference ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) 'Rows', t1.DateReference,
t1.AllocUnitTypeDesc, t1.AvgFragmentationInPercent, t1.AvgPageSpaceUsedInPercent
, t1.DatabaseId, t1.DatabaseName, t1.[FillFactor], t1.FragmentCount, t1.IndexDepth, t1.IndexId_id
, t1.IndexLevel, t1.IndexName, t1.IndexTypeDesc, t1.IndexUsage, t1.IndexUserLookups
, t1.IndexUserScans, t1.IndexUserSeeks, t1.IsMsShipped, t1.IsPrimaryKey, t1.[PageCount], t1.RecordCount
, t1.SchemaName, t1.ServerName, t1.TableName
from Management.HistoryIndexFragmentation as t1
where t1.DatabaseName = 'IntegraTICravil'
and t1.AvgFragmentationInPercent > 3
and t1.[PageCount] > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0
) as x
where x.DateReference = x.[Rows]
order by x.PageCount desc -- buscando os maiores índices por 1º