-----------------------------------------------------------------------------------------------------------------
-- https://dbabrasil.net.br/dicas-para-um-dba-iniciante-identificando-indices-nao-utilizados-no-sql-server/
-- análise de uso do índice
-----------------------------------------------------------------------------------------------------------------
SELECT Object_name(dmi.object_id) AS tbl_name,
       i.NAME                     AS idx_name,
       dmi.*,
	   'DROP INDEX [dbo].[' + Object_name(dmi.object_id) + '].[' + i.NAME + ']' AS command_drop
FROM   sys.dm_db_index_usage_stats dmi
       JOIN sys.indexes i
         ON dmi.index_id = i.index_id
            AND dmi.object_id = i.object_id
WHERE  database_id = Db_id()
       AND Object_name(dmi.object_id) IN ('ESPMD', 'PSSOA', 'RESPC', 'AGEEP', 'UNDSD', 'MEDIC', 'ENCAM', 'CNSUL' )
	   AND dmi.user_updates > dmi.user_seeks 
	   AND dmi.user_seeks = 0
ORDER  BY user_updates DESC


-- muitos updates em que tem mais do que seeks, já é muito 


-----------------------------------------------------------------------------------------------------------------
-- Candidatos para REBUILD ou REORGANIZE (usado na Careplus)
-----------------------------------------------------------------------------------------------------------------
declare @database varchar(50) = 'H_HEALTHMAP_CAREPLUS_TDE'
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
       End as Action,
       ''ALTER INDEX ''+ ind.name +'' ON '+@database+'.dbo.'' + t.name + '' ''
        + Case when indexstats.avg_fragmentation_in_percent between 5 and 30 Then
             ''REORGANIZE;''
     	    else
             ''REBUILD;''
          End as command
  From ['+@database+'].sys.dm_db_index_physical_stats(DB_id('''+@database+'''), NULL, NULL, NULL, ''DETAILED'') indexstats 
       Inner Join ['+@database+'].sys.indexes ind 
	   On ind.object_id = indexstats.object_id 
       And ind.index_id = indexstats.index_id 
	   inner join ['+@database+'].sys.tables as t
	   on t.object_id = ind.object_id
 Where indexstats.alloc_unit_type_desc = ''IN_ROW_DATA'' and indexstats.index_type_desc != ''HEAP''
   And indexstats.page_count > 1000
   And indexstats.avg_fragmentation_in_percent >= 5
   And indexstats.index_level = 0
   And indexstats.avg_page_space_used_in_percent < 75
 Order by ind.name, index_level, indexstats.avg_fragmentation_in_percent DESC
 '

execute (@comando)






