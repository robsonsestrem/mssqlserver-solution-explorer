DECLARE @logs TABLE (
    data DATETIME
   ,ProcessInfo VARCHAR(50)
   ,Text VARCHAR(4000)
)
INSERT INTO @logs
EXEC sys.sp_readerrorlog @p1 = 0    -- É o valor inteiro (int) do log que você deseja exibir. O log de erros atual tem um valor de 0, o anterior é 1 (Errorlog.1), o anterior é 2 (Errorlog.2) e assim por diante.
                        ,@p2 = NULL -- 1 ou NULL = Log de Erro, 2 = Log do SQL Agent
                        ,@p3 = N''  -- primeira string que deseja buscar
                        ,@p4 = N''; -- segunda string para refinar a busca

SELECT
    l.data
   ,l.ProcessInfo
   ,l.Text
FROM @logs AS l
WHERE l.data >= '20250413 00:00:00.000' AND l.data <= '20250501 18:00:00.000'
AND l.[Text] NOT LIKE '%Login failed%' --AND l.[Text] NOT LIKE '%Error: 18456, Severity: 14, State: 8.%' -- Login failed; Error: 18456, Severity: 14, State: 8.; Process ID 823 was killed by hostname HMNOT005, host process ID 15956;
--AND l.Text LIKE '%was killed%'
AND l.Text NOT LIKE '%Error: 18456%'
AND l.Text NOT LIKE '%Error: 17836%'
AND l.Text NOT LIKE '%Error: 17832%'
AND l.Text NOT LIKE '%Error: 17806%'
AND l.Text NOT LIKE '%Error: 18452%'
AND l.Text NOT LIKE '%Error: 17828%'
--AND l.Text NOT LIKE '%cachestore%'
-- 
--AND l.Text LIKE '%was killed%' -- Operating system error 31
ORDER BY l.data DESC


-- EXEMPLO COM MAIS PARÂMETROS E ORDENAÇÃO
-- EXEC master.dbo.xp_readerrorlog 0, 1, N'backup', N'failed', NULL, NULL, N'asc'


/*
 *
  Buscar dados periódicos varrendo mais de 1 arquivo
 *
 */
IF OBJECT_ID('tempdb..#logs') IS NOT NULL 
    DROP TABLE #logs;

CREATE TABLE #logs (
    [RowID] INT IDENTITY(1,1) PRIMARY KEY,
    EntryTime DATETIME,
    ProcessInfo VARCHAR(50),
    Text NVARCHAR(MAX)
);
CREATE NONCLUSTERED INDEX IX_logs_EntryTime ON #logs(EntryTime);

DECLARE @logIndex INT = 0;
DECLARE @hasData BIT = 1;
DECLARE @endDate DATETIME = GETDATE();
DECLARE @startDate DATETIME = DATEADD(HOUR, -24, @endDate);

WHILE @hasData = 1
BEGIN
    CREATE TABLE #tempLogs (
        EntryTime DATETIME,
        ProcessInfo VARCHAR(50),
        Text NVARCHAR(MAX)
    );
    
    BEGIN TRY
        INSERT INTO #tempLogs
        EXEC sys.sp_readerrorlog @p1 = @logIndex, @p2 = NULL, @p3 = N'', @p4 = N'';

        IF EXISTS (SELECT 1 FROM #tempLogs WHERE EntryTime BETWEEN @startDate AND @endDate)
        BEGIN
            DELETE FROM #tempLogs
            WHERE [Text] LIKE '%Login failed%' OR [Text] LIKE '%Error: 18456%';

            DELETE FROM #tempLogs
            WHERE
                ([Text] NOT LIKE '%err%'
                 AND [Text] NOT LIKE '%warn%'
                 AND [Text] NOT LIKE '%kill%'
                 AND [Text] NOT LIKE '%dead%'
                 AND [Text] NOT LIKE '%cannot%'
                 AND [Text] NOT LIKE '%could%'
                 AND [Text] NOT LIKE '%fail%'
                 AND [Text] NOT LIKE '%not%'
                 AND [Text] NOT LIKE '%stop%'
                 AND [Text] NOT LIKE '%terminate%'
                 AND [Text] NOT LIKE '%bypass%'
                 AND [Text] NOT LIKE '%roll%'
                 AND [Text] NOT LIKE '%truncate%'
                 AND [Text] NOT LIKE '%upgrade%'
                 AND [Text] NOT LIKE '%victim%'
                 AND [Text] NOT LIKE '%recover%'
                 AND [Text] NOT LIKE '%IO requests taking longer than%'
                 AND [Text] NOT LIKE '%adjustment%'
                 AND [Text] NOT LIKE '%disk%'
                 AND [Text] NOT LIKE '%memory%'
                 AND [Text] NOT LIKE '%processor%'
                 AND [Text] NOT LIKE '%socket%'
                )                
                OR [Text] LIKE '%The Service Broker endpoint is in disabled or stopped state%';

            INSERT INTO #logs
            SELECT * FROM #tempLogs;

            SET @logIndex += 1;
        END
        ELSE
        BEGIN
            SET @hasData = 0;
        END
    END TRY
    BEGIN CATCH
        SET @hasData = 0;
    END CATCH

    DROP TABLE #tempLogs;
END

SELECT
    EntryTime,
    ProcessInfo,
    Text
FROM #logs
WHERE EntryTime BETWEEN @startDate AND @endDate
ORDER BY EntryTime DESC



