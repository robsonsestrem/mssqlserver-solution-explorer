/*
 *
    OBJETIVO: Scripts de monitoramento para análise de espaço em datafiles,
              incluindo percentual de utilização em relação ao limite proposto
              e espaço livre em arquivos de log (LDF).
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: sys.master_files, sys.databases, dm_os_volume_stats, FILEPROPERTY
 */
-- ============================================================
-- Busca dados de utilização do initial file dos datafiles
-- em relação ao limite proposto
-- ============================================================
;WITH datafiles AS
(
    SELECT
          B.database_id AS database_id
        , B.[name] AS [database_name]
        , A.state_desc
        , A.[type_desc]
        , A.[file_id]
        , A.[name] AS file_name_logic
        , A.physical_name AS file_name_physical
        , CAST(A.size / 128 AS NUMERIC(18, 2)) AS size_MB
        , CAST(A.max_size / 128 AS NUMERIC(18, 2)) AS max_size_MB
        , CAST(
            CASE
                WHEN A.growth <= 0 THEN A.size / 128
                WHEN A.max_size <= 0 THEN C.total_bytes / 1048576.0
                WHEN A.max_size / 128 / 1024.0 > C.total_bytes / 1048576.0 THEN C.total_bytes / 1048576.0
                ELSE A.max_size / 128
            END AS NUMERIC(18, 2)) AS max_real_size_MB
    FROM sys.master_files A WITH(NOLOCK)
        JOIN sys.databases B WITH(NOLOCK) ON A.database_id = B.database_id
        CROSS APPLY sys.dm_os_volume_stats(A.database_id, A.[file_id]) C
)
SELECT
      t2.*
    , CAST((t2.size_MB / t2.max_real_size_MB) * 100 AS NUMERIC(18, 2)) AS Percentual
FROM datafiles AS t2
WHERE t2.type_desc = 'ROWS'  -- Para filtrar apenas arquivos de dados (mdf/ndf)
-- WHERE t2.type_desc = 'LOG' -- Para filtrar apenas arquivos de log (ldf)
GO

-- ============================================================
-- Busca percentual livre nos arquivos de logs
-- ============================================================
IF OBJECT_ID('tempdb..##tempPercFreeFile') IS NOT NULL
    DROP TABLE ##tempPercFreeFile

CREATE TABLE ##tempPercFreeFile
(
      DatabaseName   SYSNAME
    , LogicalName    SYSNAME
    , PhysicalName   NVARCHAR(100)
    , Size_Mb        DECIMAL(18, 2)
    , SpaceFree_Mb   DECIMAL(18, 2)
    , PercFreeFile   DECIMAL(18, 2)
    , [Type_desc]    VARCHAR(20)
)

EXEC sp_msforeachdb '
USE [?];
INSERT INTO ##tempPercFreeFile
(
      DatabaseName
    , LogicalName
    , physicalName
    , size_Mb
    , SpaceFree_Mb
    , PercFreeFile
    , [Type_desc]
)
SELECT
      DB_NAME() AS DatabaseName
    , Name
    , physical_name
    , CAST(CAST(ROUND(CAST(size AS DECIMAL) * 8.0 / 1024.0, 2) AS DECIMAL(18, 2)) AS NVARCHAR) AS Size_MB
    , CAST(CAST(ROUND(CAST(size AS DECIMAL) * 8.0 / 1024.0, 2) AS DECIMAL(18, 2))
        - CAST(FILEPROPERTY(name, ''SpaceUsed'') * 8.0 / 1024.0 AS DECIMAL(18, 2)) AS NVARCHAR) AS SpaceFree_MB
    , CAST(ROUND(
        (CAST(size * 8.0 / 1024.0 AS DECIMAL(18, 2))
         - CAST(FILEPROPERTY(name, ''SpaceUsed'') * 8.0 / 1024.0 AS DECIMAL(18, 2)))
        * 100 / CAST(size * 8.0 / 1024.0 AS DECIMAL(18, 2))
        , 2) AS DECIMAL(18, 2)) AS PercFreeFile
    , [type_desc]
FROM sys.database_files
WHERE [type_desc] = ''LOG'''

SELECT *
FROM ##tempPercFreeFile
GO
