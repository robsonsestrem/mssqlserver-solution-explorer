/*
 *
	OBJETIVO: Criação de tabela de histórico de fragmentação de índices e procedures
	          de carga automatizada (via SQL dinâmico) para monitoramento diário
	          de fragmentação em bases de produção, com envio de alerta em caso de falha.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	http://sqldicas.com.br/fragmentacao-das-bases/
 *	http://sqldicas.com.br/seu-job-de-rebuild-demora-muito/
 *	https://www.fabriciolima.net/blog/2011/02/16/monitorando-a-fragmentacao-dos-indices/
 *	https://www.dirceuresende.com/blog/entendendo-o-funcionamento-dos-indices-no-sql-server/
 *	https://dbasqlbr.wordpress.com/2015/03/22/como-podemos-diminuir-o-tempo-de-rebuild-de-indices/
 */
-- ============================================================
-- Histórico de Fragmentação de Índices
-- ============================================================

USE [DBA_PerformanceHub];
GO

-- Criação da tabela de histórico de fragmentação de índices
CREATE TABLE [Management].[HistoryIndexFragmentation]
(
    [DateReference] DATETIME NULL
  , [ServerName] NVARCHAR(20) NULL
  , [DatabaseId] TINYINT NULL
  , [DatabaseName] NVARCHAR(128) NULL
  , [SchemaName] SYSNAME NULL
  , [TableName] SYSNAME NULL
  , [IndexId_id] INT NULL
  , [IndexName] SYSNAME NULL
  , [IndexTypeDesc] NVARCHAR(50) NULL
  , [FillFactor] TINYINT NULL
  , [AvgFragmentationInPercent] NUMERIC(5, 2) NULL
  , [AvgPageSpaceUsedInPercent] NUMERIC(5, 2) NULL
  , [IndexLevel] TINYINT NULL
  , [IndexDepth] TINYINT NULL
  , [AllocUnitTypeDesc] NVARCHAR(50) NULL
  , [PageCount] BIGINT NULL
  , [RecordCount] BIGINT NULL
  , [FragmentCount] BIGINT NULL
  , [IsMsShipped] BIT NULL
  , [IndexUsage] BIGINT NULL
  , [IndexUserSeeks] BIGINT NULL
  , [IndexUserScans] BIGINT NULL
  , [IndexUserLookups] BIGINT NULL
  , [IsPrimaryKey] BIT NULL
);
GO

-- Consulta de exemplo: busca dos dados na DMV dm_db_index_physical_stats com parâmetros
SELECT
    GETDATE()
  , @@SERVERNAME
  , DB_NAME(DB_ID()) AS [NameDatabase]
  , [sc].[name] AS [SchemaName]
  , [t].[name] AS [TableName]
  , [a].[index_id]
  , [i].[name] AS [IndexName]
  , [a].[index_type_desc]
  , [i].[fill_factor]
  , ROUND([a].[avg_fragmentation_in_percent], 2)
  , ROUND([a].[avg_page_space_used_in_percent], 2)
  , [a].[index_level]
  , [a].[index_depth]
  , [a].[alloc_unit_type_desc]
  , [a].[page_count]
  , [a].[record_count]
  , [a].[fragment_count]
  , [t].[is_ms_shipped]
  , [Usage] = ([s].[user_seeks] + [s].[user_scans] + [s].[user_lookups])
  , [s].[user_seeks]
  , [s].[user_scans]
  , [s].[user_lookups]
  , [i].[is_primary_key]
FROM [DBA_PerformanceHub].[sys].[dm_db_index_usage_stats] AS [s]
INNER JOIN [DBA_PerformanceHub].[sys].[indexes] AS [i]
    ON [s].[object_id] = [i].[object_id]
    AND [s].[index_id] = [i].[index_id]
INNER JOIN [DBA_PerformanceHub].[sys].[dm_db_index_physical_stats](DB_ID('DBA_PerformanceHub'), NULL, NULL, NULL, 'detailed') AS [a]
    ON [s].[object_id] = [a].[object_id]
    AND [s].[index_id] = [a].[index_id]
INNER JOIN [DBA_PerformanceHub].[sys].[tables] AS [t]
    ON [i].[object_id] = [t].[object_id]
INNER JOIN [DBA_PerformanceHub].[sys].[schemas] AS [sc]
    ON [t].[schema_id] = [sc].[schema_id]
WHERE [i].[name] IS NOT NULL -- HEAP INDEX
  AND [s].[database_id] = DB_ID('DBA_PerformanceHub')
  AND [a].[database_id] = DB_ID('DBA_PerformanceHub')
ORDER BY
    [t].[name]
  , [a].[index_id];

-- Alternativa: consulta com filtro de fragmentação e ação sugerida (Reorganize/Rebuild)
SELECT
    OBJECT_NAME([ind].[object_id]) AS [TableName]
  , [ind].[name] AS [IndexName]
  , [indexstats].[index_depth]
  , [indexstats].[index_level]
  , [indexstats].[avg_fragmentation_in_percent]
  , [indexstats].[avg_page_space_used_in_percent]
  , [indexstats].[page_count]
  , CASE
        WHEN [indexstats].[avg_fragmentation_in_percent] BETWEEN 30 AND 50 THEN 'Reorganize'
        ELSE 'Rebuild'
    END AS [Action]
FROM [sys].[dm_db_index_physical_stats](DB_ID(), NULL, NULL, NULL, 'DETAILED') AS [indexstats]
INNER JOIN [sys].[indexes] AS [ind]
    ON [ind].[object_id] = [indexstats].[object_id]
    AND [ind].[index_id] = [indexstats].[index_id]
WHERE [indexstats].[alloc_unit_type_desc] = 'IN_ROW_DATA'
  AND [indexstats].[page_count] > 1000
  AND [indexstats].[avg_fragmentation_in_percent] > 30
  AND [indexstats].[index_level] = 0
  AND [indexstats].[avg_page_space_used_in_percent] < 75
ORDER BY
    [ind].[name]
  , [indexstats].[index_level]
  , [indexstats].[avg_fragmentation_in_percent] DESC;


-- ============================================================
-- Procedure para inserção em massa de fragmentação (base YOUR_DATABASE)
-- sp_LoadFragmentationIndexDB6     ==> apenas para base do cliente
-- sp_LoadFragmentationIndexDefault ==> para outros bancos de produção (comparação)
-- ============================================================
USE [YOUR_DATABASE];
GO

CREATE OR ALTER PROCEDURE [Management].[sp_LoadFragmentationIndexDB6]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- Criação da tabela temporária com lista de databases a serem processadas
    CREATE TABLE [#ListaDatabases]
    (
        [id] INT IDENTITY PRIMARY KEY
      , [NAME] VARCHAR(300)
    );

    INSERT INTO [#ListaDatabases] ([NAME])
    SELECT [NAME]
    FROM [master].[sys].[sysdatabases] AS [s]
    WHERE [dbid] = 6 -- YOUR_DATABASE
      AND DATABASEPROPERTYEX([NAME], 'Status') = 'ONLINE'
    ORDER BY 1;

    DECLARE
        @id INT
      , @cnt INT
      , @Comando NVARCHAR(MAX)
      , @NomeBanco VARCHAR(300);

    SET @id = 1;
    SET @cnt = (SELECT MAX([id]) FROM [#ListaDatabases]);

    -- Validação para não fazer mais de uma inserção diária (apaga registro anterior do dia)
    SELECT COUNT(*)
    FROM [YOUR_DATABASE].[Management].[HistoryIndexFragmentation] AS [h]
    WHERE [h].[DateReference] >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
      AND [h].[DatabaseName] = 'YOUR_DATABASE';

    IF (@@ROWCOUNT > 0)
    BEGIN
        DELETE FROM [YOUR_DATABASE].[Management].[HistoryIndexFragmentation]
        WHERE [DateReference] >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
          AND [DatabaseName] = 'YOUR_DATABASE';
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Loop para processar cada database da lista
        WHILE @id <= @cnt
        BEGIN
            SET @NomeBanco = (SELECT [NAME] FROM [#ListaDatabases] WHERE [id] = @id);

            -- Montagem do comando dinâmico de coleta de fragmentação
            SET @Comando =
                'SELECT
                   GETDATE()
                  ,InstanceName = ''' + @@SERVERNAME + '''
                  ,db_id(''' + @NomeBanco + ''')
                  ,DatabaseName = ''' + @NomeBanco + '''
                  , sc.name as NameSchema
                  , t.name  as NameTable
                  , a.index_id
                  , i.name  as NameIndex
                  , a.index_type_desc
                  , i.fill_factor
                  ,ROUND(a.avg_fragmentation_in_percent,2) as Fragmentation
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
                    [' + @NomeBanco + '].sys.dm_db_index_usage_stats s
                    INNER JOIN [' + @NomeBanco + '].sys.indexes i
                            ON s.[object_id] = i.[object_id]
                           AND s.index_id = i.index_id
                    INNER JOIN [' + @NomeBanco + '].sys.dm_db_index_physical_stats( DB_ID(''' + @NomeBanco + '''), null, null, null, ''detailed'' ) a
                            ON s.[object_id] = a.[object_id]
                           AND s.index_id = a.index_id
                    INNER JOIN [' + @NomeBanco + '].sys.tables t
                            ON i.object_id = t.object_id
                    INNER JOIN [' + @NomeBanco + '].sys.schemas sc
                            ON t.schema_id = sc.schema_id
                WHERE
                  i.name IS NOT NULL -- HEAP INDEX
                  and s.database_id = DB_ID(''' + @NomeBanco + ''')
                  and a.database_id = DB_ID(''' + @NomeBanco + ''')
                ORDER BY
                  t.name, a.index_id';

            INSERT INTO [Management].[HistoryIndexFragmentation]
            (
                [DateReference]
              , [ServerName]
              , [DatabaseId]
              , [DatabaseName]
              , [SchemaName]
              , [TableName]
              , [IndexId_id]
              , [IndexName]
              , [IndexTypeDesc]
              , [FillFactor]
              , [AvgFragmentationInPercent]
              , [AvgPageSpaceUsedInPercent]
              , [IndexLevel]
              , [IndexDepth]
              , [AllocUnitTypeDesc]
              , [PageCount]
              , [RecordCount]
              , [FragmentCount]
              , [IsMsShipped]
              , [IndexUsage]
              , [IndexUserSeeks]
              , [IndexUserScans]
              , [IndexUserLookups]
              , [IsPrimaryKey]
            )
            EXEC (@Comando);

            SET @id = @id + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE
            @corpoFalha VARCHAR(MAX)
          , @subject VARCHAR(100)
          , @recipients VARCHAR(100);

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';

        SET @corpoFalha = '
        <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
        </head>
        <body>
        <div align="left">';

        SELECT @corpoFalha = @corpoFalha + '
        <table border="0" cellpadding="0" cellspacing="0" width="402" style="border-collapse: collapse; table-layout: fixed; width: 1000pt; font-family: Arial; font-size: 14px;">
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <b>Falha na Procedure [sp_LoadFragmentationIndexDB5]:</b><br>
                </td>
            </tr>
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                    <br><br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                    <br><br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                </td>
            </tr>
        </table>';

        SELECT @corpoFalha = @corpoFalha + '
        </div>
        </body>
        </html>';

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML';
    END CATCH

    DROP TABLE [#ListaDatabases];

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT OFF;
END
GO

-- Procedure para inserção em massa de fragmentação (bases de produção exceto YOUR_DATABASE)
USE [YOUR_DATABASE];
GO

CREATE OR ALTER PROCEDURE [Management].[sp_LoadFragmentationIndexDefault]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    -- Criação da tabela temporária com lista de databases de produção
    CREATE TABLE [#ListaDatabases]
    (
        [id] INT IDENTITY PRIMARY KEY
      , [NAME] VARCHAR(300)
    );

    INSERT INTO [#ListaDatabases] ([NAME])
    SELECT [NAME]
    FROM [master].[sys].[sysdatabases] AS [s]
    WHERE [dbid] IN (5, 7, 9, 11, 12, 14, 16, 18) -- bases de produção menos YOUR_DATABASE (6 no server novo)
      AND DATABASEPROPERTYEX([NAME], 'Status') = 'ONLINE'
    ORDER BY 1;

    DECLARE
        @id INT
      , @cnt INT
      , @Comando NVARCHAR(MAX)
      , @NomeBanco VARCHAR(300);

    SET @id = 1;
    SET @cnt = (SELECT MAX([id]) FROM [#ListaDatabases]);

    -- Validação para não fazer mais de uma inserção diária (apaga registro anterior do dia)
    SELECT COUNT(*)
    FROM [YOUR_DATABASE].[Management].[HistoryIndexFragmentation] AS [h]
    WHERE [h].[DateReference] >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
      AND [h].[DatabaseName] <> 'YOUR_DATABASE';

    IF (@@ROWCOUNT > 0)
    BEGIN
        DELETE FROM [YOUR_DATABASE].[Management].[HistoryIndexFragmentation]
        WHERE [DateReference] >= CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)
          AND [DatabaseName] <> 'YOUR_DATABASE';
    END

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Loop para processar cada database da lista
        WHILE @id <= @cnt
        BEGIN
            SET @NomeBanco = (SELECT [NAME] FROM [#ListaDatabases] WHERE [id] = @id);

            -- Montagem do comando dinâmico de coleta de fragmentação
            SET @Comando =
                'SELECT
                   GETDATE()
                  ,InstanceName = ''' + @@SERVERNAME + '''
                  ,db_id(''' + @NomeBanco + ''')
                  ,DatabaseName = ''' + @NomeBanco + '''
                  , sc.name as NameSchema
                  , t.name  as NameTable
                  , a.index_id
                  , i.name  as NameIndex
                  , a.index_type_desc
                  , i.fill_factor
                  ,ROUND(a.avg_fragmentation_in_percent,2) as Fragmentation
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
                    [' + @NomeBanco + '].sys.dm_db_index_usage_stats s
                    INNER JOIN [' + @NomeBanco + '].sys.indexes i
                            ON s.[object_id] = i.[object_id]
                           AND s.index_id = i.index_id
                    INNER JOIN [' + @NomeBanco + '].sys.dm_db_index_physical_stats( DB_ID(''' + @NomeBanco + '''), null, null, null, ''detailed'' ) a
                            ON s.[object_id] = a.[object_id]
                           AND s.index_id = a.index_id
                    INNER JOIN [' + @NomeBanco + '].sys.tables t
                            ON i.object_id = t.object_id
                    INNER JOIN [' + @NomeBanco + '].sys.schemas sc
                            ON t.schema_id = sc.schema_id
                WHERE
                  i.name IS NOT NULL -- HEAP INDEX
                  and s.database_id = DB_ID(''' + @NomeBanco + ''')
                  and a.database_id = DB_ID(''' + @NomeBanco + ''')
                ORDER BY
                  t.name, a.index_id';

            INSERT INTO [Management].[HistoryIndexFragmentation]
            (
                [DateReference]
              , [ServerName]
              , [DatabaseId]
              , [DatabaseName]
              , [SchemaName]
              , [TableName]
              , [IndexId_id]
              , [IndexName]
              , [IndexTypeDesc]
              , [FillFactor]
              , [AvgFragmentationInPercent]
              , [AvgPageSpaceUsedInPercent]
              , [IndexLevel]
              , [IndexDepth]
              , [AllocUnitTypeDesc]
              , [PageCount]
              , [RecordCount]
              , [FragmentCount]
              , [IsMsShipped]
              , [IndexUsage]
              , [IndexUserSeeks]
              , [IndexUserScans]
              , [IndexUserLookups]
              , [IsPrimaryKey]
            )
            EXEC (@Comando);

            SET @id = @id + 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE
            @corpoFalha VARCHAR(MAX)
          , @subject VARCHAR(100)
          , @recipients VARCHAR(100);

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';

        SET @corpoFalha = '
        <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
        </head>
        <body>
        <div align="left">';

        SELECT @corpoFalha = @corpoFalha + '
        <table border="0" cellpadding="0" cellspacing="0" width="402" style="border-collapse: collapse; table-layout: fixed; width: 1000pt; font-family: Arial; font-size: 14px;">
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <b>Falha na Procedure [sp_LoadFragmentationIndexDefault]:</b><br>
                </td>
            </tr>
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                    <br><br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                    <br><br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                </td>
            </tr>
        </table>';

        SELECT @corpoFalha = @corpoFalha + '
        </div>
        </body>
        </html>';

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML';
    END CATCH

    DROP TABLE [#ListaDatabases];

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    SET NOCOUNT OFF;
END
GO
