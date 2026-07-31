-- ================================================================================================================================
/*
    OBJETIVO: Scripts para análise de fragmentação de índices no SQL Server,
              com recomendações de REBUILD ou REORGANIZE baseadas em diferentes
              critérios de autores referenciados.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://www.dirceuresende.com/blog/entendendo-o-funcionamento-dos-indices-no-sql-server/
 *  https://www.fabriciolima.net/blog/2011/02/16/monitorando-a-fragmentacao-dos-indices/
 *  http://www.dbinternals.com.br/?p=824
 *  https://thiagotimm.wordpress.com/2014/04/28/indices-fragmentacao-rebuild-ou-reorganize/
 */
-- ================================================================================================================================
-- RECOMENDAÇÃO MICROSOFT
-- Documentação Microsoft:
-- "The workload performance increase realized in the small-scale environment ranged from 60 percent 
-- at the low level of fragmentation to more than 460 percent at the highest level of fragmentation. 
-- The workload performance increase realized for the large-scale environment ranged from 13 percent 
-- at the low fragmentation level to 40 percent at the medium fragmentation level"
-- avg_fragmentation_in_percent > 5% and <= 30% => REORGANIZE
-- avg_fragmentation_in_percent > 30%           => REBUILD WITH (ONLINE = ON)
-- ================================================================================================================================

-- ================================================================================================================================
-- ABORDAGEM: FAUSTO BRANCO
-- Consulta de fragmentação com decisão entre REBUILD e REORGANIZE
-- ================================================================================================================================
DECLARE @database VARCHAR(50) = 'integraticravil'
DECLARE @comando VARCHAR(MAX)

SET @comando =
'
SELECT
    t.name AS TableName
  , ind.name AS IndexName
  , indexstats.index_depth
  , indexstats.index_level
  , indexstats.avg_fragmentation_in_percent
  , indexstats.avg_page_space_used_in_percent
  , indexstats.page_count
  , CASE
        WHEN indexstats.avg_fragmentation_in_percent BETWEEN 5 AND 30
        THEN ''Reorganize''
        ELSE ''Rebuild''
    END AS Action
FROM
    [' + @database + '].sys.dm_db_index_physical_stats(DB_id(''' + @database + '''), NULL, NULL, NULL, ''DETAILED'') indexstats
    INNER JOIN [' + @database + '].sys.indexes ind
        ON ind.object_id = indexstats.object_id
        AND ind.index_id = indexstats.index_id
    INNER JOIN [' + @database + '].sys.tables AS t
        ON t.object_id = ind.object_id
WHERE
    indexstats.alloc_unit_type_desc = ''IN_ROW_DATA''
    AND indexstats.page_count > 1000
    AND indexstats.avg_fragmentation_in_percent >= 5
    AND indexstats.index_level = 0
    AND indexstats.avg_page_space_used_in_percent < 75
ORDER BY
    ind.name
  , index_level
  , indexstats.avg_fragmentation_in_percent DESC
'

EXECUTE (@comando)


-- ================================================================================================================================
-- ABORDAGEM: FABRÍCIO LIMA
-- Consulta utilizando histórico de fragmentação
-- ================================================================================================================================
USE YOUR_DATABASE
GO

SELECT
    *
FROM
    Management.HistoryIndexFragmentation AS h
WHERE
    h.PageCount > 1000                                                    -- eliminar índices pequenos
    AND h.DateReference >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
    AND h.AvgFragmentationInPercent > 20
    AND h.DatabaseName = 'YOUR_DATABASE'
ORDER BY
    h.TableName
  , h.IndexId_id


-- ================================================================================================================================
-- ABORDAGEM: DIRCEU RESENDE
-- Consulta simplificada para índices com fragmentação > 20%
-- ================================================================================================================================
SELECT
    OBJECT_NAME(B.object_id) AS TableName
  , B.name AS IndexName
  , A.index_type_desc AS IndexType
  , A.avg_fragmentation_in_percent
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') A
    INNER JOIN sys.indexes B WITH(NOLOCK)
        ON B.object_id = A.object_id
        AND B.index_id = A.index_id
WHERE
    A.avg_fragmentation_in_percent > 20
    AND OBJECT_NAME(B.object_id) NOT LIKE '[_]%'
    AND A.index_type_desc != 'HEAP'
ORDER BY
    A.avg_fragmentation_in_percent DESC


-- ================================================================================================================================
-- ABORDAGEM: THIAGO TIMM
-- Geração de scripts ALTER INDEX com decisão entre REBUILD e REORGANIZE
-- ================================================================================================================================
USE YOUR_DATABASE
GO

SELECT
    'ALTER INDEX ' + idx.name + ' ON ' + OBJECT_NAME(dmv.object_id, dmv.database_id)
    + CASE
          WHEN avg_fragmentation_in_percent > 30
          THEN ' REBUILD'
          ELSE ' REORGANIZE'
      END
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) dmv
    LEFT JOIN sys.indexes idx
        ON idx.object_id = dmv.object_id
        AND idx.index_id = dmv.index_id
WHERE
    index_type_desc <> 'HEAP'
    AND avg_fragmentation_in_percent > 20
--  AND dmv.page_count > 1000

-- Exemplo de comando gerado:
-- ALTER INDEX PK_CMVTransf ON HistoricoCMVTransf REBUILD

/*
    *******************************************************
    EXEMPLO PRÁTICO - CONSULTA DETALHADA COM HISTÓRICO
    *******************************************************
*/
SELECT
    t1.DatabaseName
  , t1.SchemaName
  , t1.TableName
  , t1.IndexName
  , IndexTypeDesc
  , t1.AvgFragmentationInPercent
  , t1.AvgPageSpaceUsedInPercent
  , t1.IndexLevel
  , t1.IndexDepth
  , t1.PageCount
  , t1.RecordCount
  , t1.IndexUsage
  , t1.IndexUserScans
  , t1.IndexUserScans
  , t1.IndexUserLookups
FROM
    Management.HistoryIndexFragmentation AS t1
WHERE
    t1.DateReference >= '20180301'
    AND t1.DateReference < '20180302'
    AND t1.DatabaseId = 6
    AND t1.AvgFragmentationInPercent > 5
    AND t1.PageCount > 1000
    AND t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
    AND t1.IndexLevel = 0
--  AND t1.AvgPageSpaceUsedInPercent > 75
ORDER BY
    t1.TableName ASC
  , t1.AvgFragmentationInPercent DESC


-- ================================================================================================================================
-- GERAÇÃO DE SCRIPTS DE MANUTENÇÃO
-- Cria comandos ALTER INDEX com REBUILD/REORGANIZE e backup do log
-- ================================================================================================================================
SELECT
    'ALTER INDEX ' + t1.IndexName + ' ON ' + t1.DatabaseName + '.' + t1.SchemaName + '.' + t1.TableName + ' '
    + CASE
          WHEN t1.AvgFragmentationInPercent < 30
          THEN 'REORGANIZE'
          ELSE 'REBUILD'
      END
    + '; BACKUP LOG YOUR_DATABASE TO DISK = ''G:\Backup\YOUR_DATABASE_log.TRN'' WITH INIT;'
    + ' --Frag. = ' + CAST(t1.AvgFragmentationInPercent AS VARCHAR(50)) + '%'
    + ' - PageCont = ' + CAST(t1.PageCount AS VARCHAR(50))
FROM
    Management.HistoryIndexFragmentation AS t1
WHERE
    t1.DateReference >= '20180301'
    AND t1.DateReference < '20180302'
    AND t1.DatabaseId = 6
    AND t1.AvgFragmentationInPercent > 5
    AND t1.PageCount > 1000
    AND t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
    AND t1.IndexLevel = 0
ORDER BY
    t1.PageCount DESC
--  , t1.AvgFragmentationInPercent DESC

-- ================================================================================================================================
-- EXEMPLO DE RESULTADO GERADO
-- ================================================================================================================================
-- ALTER INDEX PK__MOVESTOQUELEVEL1__2D52A092 ON YOUR_DATABASE.dbo.MOVESTOQUELEVEL1 REBUILD;
-- BACKUP LOG YOUR_DATABASE TO DISK = 'G:\Backup\YOUR_DATABASE_log.TRN' WITH INIT;
-- --Frag. = 36.58% - PageCont = 21596144
