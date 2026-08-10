/*
    OBJETIVO: Identificar índices fragmentados com base no histórico de
              fragmentação armazenado por rotina customizada (HistoryIndexFragmentation),
              apresentando os registros mais recentes e gerando scripts de REORGANIZE
              ou REBUILD para manutenção dos índices.
    PROJETO: mssqlserver-solution-explorer
    
    REFERÊNCIAS:
*   https://blogfabiano.com/2010/05/25/plano-de-manutencao-reindex-vs-estatisticas/
*/
-- ============================================================
-- Última atualização dos dados de fragmentação
-- ============================================================
;WITH conjunto
AS (
    SELECT
        LAST_VALUE(t1.DateReference) OVER
        (
            ORDER BY t1.DateReference
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                   AS LAST_VAL
      , t1.DateReference
      , t1.DatabaseName
      , t1.SchemaName
      , t1.TableName
      , t1.IndexName
      , t1.IndexTypeDesc
      , t1.AvgFragmentationInPercent
      , t1.AvgPageSpaceUsedInPercent
      , t1.IndexLevel
      , t1.IndexDepth
      , t1.PageCount
      , t1.RecordCount
      , t1.IndexUsage
      , t1.IndexUserScans
      , t1.IndexUserSeeks
      , t1.IndexUserLookups
    FROM
        Management.HistoryIndexFragmentation AS t1
    WHERE
        t1.DatabaseName = 'DBA_PerformanceHub'
        AND t1.AvgFragmentationInPercent > 5
        AND t1.PageCount > 1000
        AND t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
        AND t1.IndexLevel = 0
)

SELECT
    x.DateReference
  , x.DatabaseName
  , x.SchemaName
  , x.TableName
  , x.IndexName
  , x.IndexTypeDesc
  , x.AvgFragmentationInPercent
  , x.AvgPageSpaceUsedInPercent
  , x.IndexLevel
  , x.IndexDepth
  , x.PageCount
  , x.RecordCount
  , x.IndexUsage
  , x.IndexUserScans
  , x.IndexUserSeeks
  , x.IndexUserLookups
FROM
    conjunto AS x
WHERE
    x.DateReference = x.LAST_VAL
ORDER BY
    x.TableName ASC
  , x.AvgFragmentationInPercent DESC;
-- AND x.AvgPageSpaceUsedInPercent > 75;


-- ============================================================
-- Consulta de fragmentação para um índice específico
-- ============================================================
SELECT
    t1.DatabaseName
  , t1.SchemaName
  , t1.TableName
  , t1.IndexName
  , t1.IndexTypeDesc
  , t1.AvgFragmentationInPercent
  , t1.AvgPageSpaceUsedInPercent
  , t1.IndexLevel
  , t1.IndexDepth
  , t1.PageCount
  , t1.RecordCount
  , t1.IndexUsage
  , t1.IndexUserScans
  , t1.IndexUserSeeks
  , t1.IndexUserLookups
FROM
    Management.HistoryIndexFragmentation AS t1
WHERE
    t1.DateReference >= '20180701'
    AND t1.DateReference < '20180710'
    AND t1.DatabaseId = 6
    AND t1.IndexName = 'PK__MOVESTOQUELEVEL1__2D52A092'
    AND t1.AvgFragmentationInPercent > 5
    AND t1.PageCount > 1000
    AND t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
    AND t1.IndexLevel = 0
    -- AND t1.AvgPageSpaceUsedInPercent > 75
ORDER BY
    t1.TableName ASC
  , t1.AvgFragmentationInPercent DESC;


-- ============================================================
-- Gerando script de manutenção - Modelo 1
-- ============================================================
;WITH conjunto
AS (
    SELECT
        'ALTER INDEX ' + t1.IndexName + ' ON '
        + t1.DatabaseName + '.' + t1.SchemaName + '.' + t1.TableName + ' '
        + CASE
              WHEN t1.AvgFragmentationInPercent < 30 THEN 'REORGANIZE'
              ELSE 'REBUILD'
          END
        + '; BACKUP LOG DBA_PerformanceHub TO DISK = ''G:\Backup\DBA_PerformanceHub_log.TRN'' WITH INIT;' AS SCRIPTS
      , LAST_VALUE(t1.DateReference) OVER
        (
            ORDER BY t1.DateReference
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        )                                                                   AS LAST_VAL
      , t1.DateReference
      , t1.PageCount
      , t1.AvgFragmentationInPercent
    FROM
        Management.HistoryIndexFragmentation AS t1
    WHERE
        t1.DatabaseName = 'DBA_PerformanceHub'
        AND t1.AvgFragmentationInPercent > 5
        AND t1.PageCount > 1000
        AND t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
        AND t1.IndexLevel = 0
)

SELECT
    x.SCRIPTS
  , x.PageCount
  , x.AvgFragmentationInPercent
  , x.DateReference
FROM
    conjunto AS x
WHERE
    x.DateReference = x.LAST_VAL
ORDER BY
    x.PageCount DESC;  -- buscando os maiores índices primeiro


-- ============================================================
-- Gerando script de manutenção - Modelo 2
-- ============================================================
SELECT
    'ALTER INDEX ' + x.IndexName + ' ON '
    + x.DatabaseName + '.' + x.SchemaName + '.' + x.TableName + ' '
    + CASE
          WHEN x.AvgFragmentationInPercent < 30 THEN 'REORGANIZE'
          ELSE 'REBUILD'
      END                                                                   AS SCRIPTS
  , x.DateReference
  , x.PageCount
  , x.AvgFragmentationInPercent
FROM
    (
        SELECT
            MAX(t1.DateReference) OVER
            (
                ORDER BY t1.DateReference
                ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
            )                                                               AS Rows
          , t1.DateReference
          , t1.AllocUnitTypeDesc
          , t1.AvgFragmentationInPercent
          , t1.AvgPageSpaceUsedInPercent
          , t1.DatabaseId
          , t1.DatabaseName
          , t1.FillFactor
          , t1.FragmentCount
          , t1.IndexDepth
          , t1.IndexId_id
          , t1.IndexLevel
          , t1.IndexName
          , t1.IndexTypeDesc
          , t1.IndexUsage
          , t1.IndexUserLookups
          , t1.IndexUserScans
          , t1.IndexUserSeeks
          , t1.IsMsShipped
          , t1.IsPrimaryKey
          , t1.PageCount
          , t1.RecordCount
          , t1.SchemaName
          , t1.ServerName
          , t1.TableName
        FROM
            Management.HistoryIndexFragmentation AS t1
        WHERE
            t1.DatabaseName = 'DBA_PerformanceHub'
            AND t1.AvgFragmentationInPercent > 3
            AND t1.PageCount > 1000
            AND t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
            AND t1.IndexLevel = 0
    ) AS x
WHERE
    x.DateReference = x.Rows
ORDER BY
    x.PageCount DESC;  -- buscando os maiores índices primeiro


-- ============================================================
-- Gerando script de manutenção - Modelo 3
-- ============================================================
SELECT
    'ALTER INDEX ' + t1.IndexName + ' ON '
    + t1.DatabaseName + '.' + t1.SchemaName + '.' + t1.TableName + ' '
    + CASE
          WHEN t1.AvgFragmentationInPercent < 30 THEN 'REORGANIZE'
          ELSE 'REBUILD'
      END
    + '; BACKUP LOG YOUR_DATABASE TO DISK = ''G:\Backup\YOUR_DATABASE_log.TRN'' WITH INIT;'
    + ' --Frag. = ' + CAST(t1.AvgFragmentationInPercent AS VARCHAR(50)) + '%'
    + ' - PageCont = ' + CAST(t1.PageCount AS VARCHAR(50))                  AS SCRIPTS
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
    t1.PageCount DESC;  -- buscando os maiores índices primeiro


-- ============================================================
-- Exemplo de saída gerada
-- ============================================================

/*
ALTER INDEX PK__MOVESTOQUELEVEL1__2D52A092 ON YOUR_DATABASE.dbo.MOVESTOQUELEVEL1 REBUILD; BACKUP LOG YOUR_DATABASE TO DISK = 'G:\Backup\YOUR_DATABASE_log.TRN' WITH INIT; --Frag. = 36.58% - PageCont = 21596144
*/
