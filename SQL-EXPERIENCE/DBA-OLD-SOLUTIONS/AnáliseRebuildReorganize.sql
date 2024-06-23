-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ##  REFERÊNCIAS  ##
-- https://www.dirceuresende.com/blog/entendendo-o-funcionamento-dos-indices-no-sql-server/
-- https://www.fabriciolima.net/blog/2011/02/16/monitorando-a-fragmentacao-dos-indices/
-- http://www.dbinternals.com.br/?p=824
-- https://thiagotimm.wordpress.com/2014/04/28/indices-fragmentacao-rebuild-ou-reorganize/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- **************		Recomendação Microsoft:			******************************************************************************************
--Documentação Microsoft:
--“The workload performance increase realized in the small?scale environment ranged from 60 percent at the low level of fragmentation to more than
--460 percent at the highest level of fragmentation. The workload performance increased realized for the large?scale environment ranged from 13
--percent at the low fragmentation level to 40 percent at the medium fragmentation level”
-- avg_fragmentation_in_percent > 5% and 30% ALTER INDEX REBUILD WITH (ONLINE = ON)*
-- ************************************************************************************************************************************************
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FAUSTO BRANCO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
declare @database varchar(50) = 'integraticravil'
declare @comando varchar(max)

set @comando = '
Select t.name AS TableName, 
       ind.name AS IndexName, 
       indexstats.index_depth,
       indexstats.index_level,
       indexstats.avg_fragmentation_in_percent,
       indexstats.avg_page_space_used_in_percent,
       indexstats.page_count,
       Case when indexstats.avg_fragmentation_in_percent between 5 and 30 Then
             ''Reorganize''
     	 else
             ''Rebuild''
       End as Action
  From ['+@database+'].sys.dm_db_index_physical_stats(DB_id('''+@database+'''), NULL, NULL, NULL, ''DETAILED'') indexstats 
       Inner Join ['+@database+'].sys.indexes ind 
	   On ind.object_id = indexstats.object_id 
       And ind.index_id = indexstats.index_id 
	   inner join ['+@database+'].sys.tables as t
	   on t.object_id = ind.object_id
 Where indexstats.alloc_unit_type_desc = ''IN_ROW_DATA''
   And indexstats.page_count > 1000
   And indexstats.avg_fragmentation_in_percent >= 5
   And indexstats.index_level = 0
   And indexstats.avg_page_space_used_in_percent < 75
 Order by ind.name, index_level, indexstats.avg_fragmentation_in_percent DESC
 '
 execute (@comando)


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- FABRÍCIO LIMA
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go

select * from Management.HistoryIndexFragmentation as h
where h.PageCount > 1000  -- eliminar ínndices pequenos
and h.DateReference >= cast(floor(cast(GETDATE() as float)) as datetime)
and h.AvgFragmentationInPercent > 20
and h.DatabaseName = 'Maintenance'
order by h.TableName, h.IndexId_id


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DIRCEU RESENDE
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    OBJECT_NAME(B.object_id) AS TableName,
    B.name AS IndexName,
    A.index_type_desc AS IndexType,
    A.avg_fragmentation_in_percent
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED')	A
    INNER JOIN sys.indexes							B	WITH(NOLOCK) ON B.object_id = A.object_id AND B.index_id = A.index_id
WHERE
    A.avg_fragmentation_in_percent > 20
    AND OBJECT_NAME(B.object_id) NOT LIKE '[_]%'
    AND A.index_type_desc != 'HEAP'
ORDER BY
    A.avg_fragmentation_in_percent DESC


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--THIAGO TIMM
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go

select 'alter index '+idx.name+' on '+object_name(dmv.object_id,dmv.database_id)
+case when avg_fragmentation_in_percent > 30 then ' rebuild' else ' reorganize' end
from sys.dm_db_index_physical_stats(db_id(), null, null, null, null) dmv
	left join sys.indexes idx 
		on		idx.object_id=dmv.object_id
			and idx.index_id = dmv.index_id
where index_type_desc <> 'HEAP'
	and avg_fragmentation_in_percent > 20
	--and dmv.page_count > 1000

-- alter index PK_CMVTransf on HistoricoCMVTransf rebuild

/*
	*******************************************************	EXEMPLO PRÁTICO *******************************************************
*/
select
t1.DatabaseName, t1.SchemaName, t1.TableName, t1.IndexName, IndexTypeDesc, t1.AvgFragmentationInPercent
, t1.AvgPageSpaceUsedInPercent, t1.IndexLevel, t1.IndexDepth
, t1.PageCount , t1.RecordCount, t1.IndexUsage, t1.IndexUserScans, t1.IndexUserScans, t1.IndexUserLookups
from Management.HistoryIndexFragmentation as t1
where t1.DateReference >= '20180301' and t1.DateReference < '20180302'
and t1.DatabaseId = 6
and t1.AvgFragmentationInPercent > 5
and t1.PageCount > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0
--and t1.AvgPageSpaceUsedInPercent > 75

order by t1.TableName asc, t1.AvgFragmentationInPercent desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando o script
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
select
'ALTER INDEX '+ t1.IndexName +' ON '+ t1.DatabaseName + '.' + t1.SchemaName + '.' + t1.TableName + ' '
+ case when t1.AvgFragmentationInPercent < 30 then 'REORGANIZE'
	   else 'REBUILD'
  end
+ '; BACKUP LOG GesCooper90 TO DISK = ''G:\Backup\GesCooper90_log.TRN'' WITH INIT;' + ' --Frag. = '
+ cast(t1.AvgFragmentationInPercent as varchar(50)) + '%' + ' - PageCont = '+ cast(t1.PageCount as varchar(50))

from Management.HistoryIndexFragmentation as t1
where t1.DateReference >= '20180301' and t1.DateReference < '20180302'
and t1.DatabaseId = 6
and t1.AvgFragmentationInPercent > 5
and t1.PageCount > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0
order by t1.PageCount desc --, t1.AvgFragmentationInPercent desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo de resultSet
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ALTER INDEX PK__MOVESTOQUELEVEL1__2D52A092 ON GesCooper90.dbo.MOVESTOQUELEVEL1 REBUILD; BACKUP LOG GesCooper90 TO DISK = 'G:\Backup\GesCooper90_log.TRN' WITH INIT; --Frag. = 36.58% - PageCont = 21596144