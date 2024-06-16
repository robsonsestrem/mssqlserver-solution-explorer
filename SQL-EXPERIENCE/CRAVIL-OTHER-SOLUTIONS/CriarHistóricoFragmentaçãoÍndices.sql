-------------------------------------------------------------------------------------------------------------------------------------------
-- ##### REFEÊNCIAS ######
-- http://sqldicas.com.br/fragmentacao-das-bases/
-- http://sqldicas.com.br/seu-job-de-rebuild-demora-muito/
-- https://www.fabriciolima.net/blog/2011/02/16/monitorando-a-fragmentacao-dos-indices/
-- https://www.dirceuresende.com/blog/entendendo-o-funcionamento-dos-indices-no-sql-server/
-- https://dbasqlbr.wordpress.com/2015/03/22/como-podemos-diminuir-o-tempo-de-rebuild-de-indices/
-------------------------------------------------------------------------------------------------------------------------------------------
-- Tabela de Histórico
-------------------------------------------------------------------------------------------------------------------------------------------
USE IntegraTICravil
go
CREATE TABLE [Management].[HistoryIndexFragmentation] (
   [DateReference] DATETIME  
  , ServerName nvarchar(20)
  , DatabaseId TINYINT
  , DatabaseName NVARCHAR(128)
  , SchemaName SYSNAME
  , TableName  SYSNAME
  , IndexId_id INT
  , IndexName  SYSNAME 
  , IndexTypeDesc NVARCHAR(50)
  , [FillFactor] TINYINT
  , AvgFragmentationInPercent numeric(5, 2)
  , AvgPageSpaceUsedInPercent numeric(5, 2)
  , IndexLevel TINYINT
  , IndexDepth TINYINT
  , AllocUnitTypeDesc NVARCHAR(50)
  , [PageCount] BIGINT
  , RecordCount BIGINT
  , FragmentCount	BIGINT
  , IsMsShipped BIT
  , IndexUsage BIGINT
  , IndexUserSeeks BIGINT
  , IndexUserScans BIGINT
  , IndexUserLookups BIGINT
  , IsPrimaryKey BIT
)

-------------------------------------------------------------------------------------------------------------------------------------------
-- Busca dos dados na dmv dm_db_index_physical_stats com parâmetros 
-------------------------------------------------------------------------------------------------------------------------------------------
SELECT
   GETDATE()
  , @@SERVERNAME
  , DB_NAME(DB_ID()) as NameDatabase
  , sc.name as SchemaName
  , t.name  as TableName
  , a.index_id
  , i.name  as IndexName   
  , a.index_type_desc 
  , i.fill_factor 
  ,ROUND(a.avg_fragmentation_in_percent,2) 
  ,ROUND(a.avg_page_space_used_in_percent,2) 
  ,a.index_level 
  ,a.index_depth 
  ,a.alloc_unit_type_desc 
  ,a.page_count 
  ,a.record_count 
  ,a.fragment_count	
  ,t.is_ms_shipped 
  ,[Usage] = (s.user_seeks + s.user_scans + s.user_lookups) 
  ,s.user_seeks 
  ,s.user_scans 
  ,s.user_lookups 
  ,i.is_primary_key 
  FROM
    [integraticravil].sys.dm_db_index_usage_stats s
    INNER JOIN [integraticravil].sys.indexes i
            ON s.[object_id] = i.[object_id]
           AND s.index_id = i.index_id
    INNER JOIN [integraticravil].sys.dm_db_index_physical_stats( DB_ID('integraticravil'), null, null, null, 'detailed' ) a
            ON s.[object_id] = a.[object_id]
           AND s.index_id = a.index_id
    INNER JOIN [integraticravil].sys.tables t
            ON i.object_id = t.object_id
    INNER JOIN [integraticravil].sys.schemas sc
            ON t.schema_id = sc.schema_id
WHERE
  i.name IS NOT NULL -- HEAP INDEX  
  and s.database_id = DB_ID('integraticravil')
  and a.database_id = DB_ID('integraticravil') 
ORDER BY
  t.name, a.index_id
--
-- OU
--
--Select object_name(ind.object_id) AS TableName, 
--       ind.name AS IndexName, 
--       indexstats.index_depth,
--       indexstats.index_level,
--       indexstats.avg_fragmentation_in_percent,
--       indexstats.avg_page_space_used_in_percent,
--       indexstats.page_count,
--       Case when indexstats.avg_fragmentation_in_percent between 30 and 50 Then
--             'Reorganize'
--     	 else
--             'Rebuild'
--       End as Action
--  From sys.dm_db_index_physical_stats(DB_id(), NULL, NULL, NULL, 'DETAILED') indexstats 
--       Inner Join sys.indexes ind On ind.object_id = indexstats.object_id 
--                                 And ind.index_id = indexstats.index_id 
-- Where indexstats.alloc_unit_type_desc = 'IN_ROW_DATA'
--   And indexstats.page_count > 1000
--   And indexstats.avg_fragmentation_in_percent > 30
--   And indexstats.index_level = 0
--   And indexstats.avg_page_space_used_in_percent < 75
-- Order by ind.name, index_level, indexstats.avg_fragmentation_in_percent DESC


-------------------------------------------------------------------------------------------------------------------------------------------
-- Procedure para inserção em massa
-------------------------------------------------------------------------------------------------------------------------------------------
-- sp_LoadFragmentationIndexDB5		===>> só para o GesCooper90
-- sp_LoadFragmentationIndexDefault ===>> para outros bancos de produção e assim poder comparar