/*
 *
    OBJETIVO: Procedure para geração e envio de relatório diário de DeadLocks
              no SQL Server, com extração detalhada dos grafos XML de deadlock
              e envio por e-mail com anexo CSV contendo as informações.
    PROJETO: mssqlserver-solution-explorer
 * 
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_ReportDeadLock]
    @ExibirApenasHtml BIT = 0
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET LANGUAGE 'portuguese'

    -- ============================================================
    -- Declaração de variáveis
    -- ============================================================
    DECLARE @inicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
    DECLARE @fim DATETIME = DATEADD(MILLISECOND, +997, DATEADD(SECOND, +59, DATEADD(MINUTE, +59, DATEADD(HOUR, +23, DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))))))
    DECLARE @vSubject NVARCHAR(255) = 'Relatório Diário - DeadLocks no Sistema'
    DECLARE @vBody AS NVARCHAR(MAX) = ''
    DECLARE @contaInsert INT = 0

    -- ============================================================
    -- Criação da tabela temporária para armazenar os dados extraídos
    -- ============================================================
    IF OBJECT_ID('tempdb..##ReportDeadlock') IS NOT NULL
    BEGIN
        DROP TABLE ##ReportDeadlock
    END
    ELSE
    BEGIN
        CREATE TABLE ##ReportDeadlock
        (
              IdDeadLock          VARCHAR(10)
            , [Victim]            VARCHAR(2)
            , [LockMode]          VARCHAR(10)
            , [LockedObject]      VARCHAR(200)
            , DatabaseName        VARCHAR(50)
            , [AssociatedObjectId] VARCHAR(MAX)
            , [LockProcess]       VARCHAR(200)
            , [KPID]              VARCHAR(10)
            , [SPID]              VARCHAR(10)
            , [SBID]              VARCHAR(10)
            , [ECID]              VARCHAR(10)
            , [TranCount]         VARCHAR(10)
            , [LockEvent]         VARCHAR(50)
            , [LockedMode]        VARCHAR(10)
            , [WaitProcessID]     VARCHAR(50)
            , [WaitMode]          VARCHAR(10)
            , [WaitResource]      VARCHAR(100)
            , [WaitType]          VARCHAR(100)
            , [IsolationLevel]    VARCHAR(100)
            , [LogUsed]           VARCHAR(50)
            , [ClientApp]         VARCHAR(100)
            , [HostName]          VARCHAR(60)
            , [LoginName]         VARCHAR(60)
            , [TransactionTime]   VARCHAR(30)
            , [BatchStarted]      VARCHAR(30)
            , [BatchCompleted]    VARCHAR(30)
            , [InputBuffer]       VARCHAR(MAX)
        )
    END

    -- ============================================================
    -- Extração dos dados dos grafos de deadlock
    -- ============================================================
    ;WITH cte_DeadLock AS
    (
        SELECT
              IdDeadLock
            , DateDeadLock
            , DatabaseName
            , GraphDeadLock
        FROM Management.HistoryDeadLock
        WHERE DateDeadLock BETWEEN @inicio AND @fim
    )
    , Victims AS
    (
        SELECT
            [ID] = [Victims].[List].value('@id', 'varchar(50)')
        FROM [cte_DeadLock]
            CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/victim-list/victimProcess') AS [Victims]([List])
    )
    , Locks AS
    (
        SELECT
              [cte_DeadLock].IdDeadLock
            , [LockID] = [MainLock].[Process].value('@id', 'varchar(100)')
            , [LockProcessId] = [OwnerList].[Owner].value('@id', 'varchar(200)')
            , [LockEvent] = REPLACE([MainLock].[Process].value('local-name(.)', 'varchar(100)'), 'lock', '')
            , [ObjectName] = [MainLock].[Process].value('@objectname', 'sysname')
            , [LockMode] = [OwnerList].[Owner].value('@mode', 'varchar(10)')
            , [cte_DeadLock].DatabaseName
            , [AssociatedObjectId] = [MainLock].[Process].value('@associatedObjectId', 'BIGINT')
            , [WaitType] = [MainLock].[Process].value('@WaitType', 'varchar(100)')
            , [WaitProcessId] = [WaiterList].[Owner].value('@id', 'varchar(200)')
            , [WaitMode] = [WaiterList].[Owner].value('@mode', 'varchar(10)')
        FROM [cte_DeadLock]
            CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/resource-list') AS [Locks]([list])
            CROSS APPLY [Locks].[List].[nodes]('*') AS [MainLock]([Process])
            CROSS APPLY [MainLock].[Process].[nodes]('owner-list/owner') AS [OwnerList]([Owner])
            CROSS APPLY [MainLock].[Process].[nodes]('waiter-list/waiter') AS [WaiterList]([Owner])
    )
    , Process AS
    (
        SELECT
              [cte_DeadLock].IdDeadLock
            , [Victim] = CONVERT(
                  BIT,
                  CASE
                      WHEN [Deadlock].[Process].value('@id', 'varchar(50)') = ISNULL([Deadlock].[Process].value('../../@victim', 'varchar(50)'), [v].[ID])
                      THEN 1
                      ELSE 0
                  END
              )
            , [LockMode] = [Deadlock].[Process].value('@lockMode', 'varchar(10)')
            , [ProcessID] = [Process].[ID]
            , [KPID] = [Deadlock].[Process].value('@kpid', 'int')
            , [SPID] = [Deadlock].[Process].value('@spid', 'int')
            , [SBID] = [Deadlock].[Process].value('@sbid', 'int')
            , [ECID] = [Deadlock].[Process].value('@ecid', 'int')
            , [IsolationLevel] = [Deadlock].[Process].value('@isolationlevel', 'varchar(200)')
            , [WaitResource] = [Deadlock].[Process].value('@waitresource', 'varchar(200)')
            , [LogUsed] = [Deadlock].[Process].value('@logused', 'int')
            , [ClientApp] = [Deadlock].[Process].value('@clientapp', 'varchar(100)')
            , [HostName] = [Deadlock].[Process].value('@hostname', 'varchar(20)')
            , [LoginName] = [Deadlock].[Process].value('@loginname', 'varchar(20)')
            , [TransactionTime] = CAST([Deadlock].[Process].value('@lasttranstarted', 'datetime') AS DATETIME)
            , [BatchStarted] = CAST([Deadlock].[Process].value('@lastbatchstarted', 'datetime') AS DATETIME)
            , [BatchCompleted] = CAST([Deadlock].[Process].value('@lastbatchcompleted', 'datetime') AS DATETIME)
            , [InputBuffer] = [Input].[Buffer].[query]('.')
            , [cte_DeadLock].GraphDeadLock
            , [QueryStatement] = [Execution].[Frame].value('.', 'varchar(max)')
            , [TranCount] = [Deadlock].[Process].value('@trancount', 'int')
        FROM [cte_DeadLock]
            CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/process-list/process') AS [Deadlock]([Process])
            CROSS APPLY (SELECT [Deadlock].[Process].value('@id', 'varchar(50)')) AS [Process]([ID])
            LEFT JOIN [Victims] AS [v] ON [Process].[ID] = [v].[ID]
            CROSS APPLY [Deadlock].[Process].[nodes]('inputbuf') AS [Input]([Buffer])
            CROSS APPLY [Deadlock].[Process].[nodes]('executionStack') AS [Execution]([Frame])
    )

    INSERT INTO ##ReportDeadlock
    SELECT
          [p].IdDeadLock
        , [p].[Victim]
        , ISNULL([p].[LockMode], '') AS [LockMode]
        , ISNULL([l].[ObjectName], '') AS [LockedObject]
        , [l].DatabaseName
        , ISNULL([l].[AssociatedObjectId], '') AS [AssociatedObjectId]
        , [p].[ProcessID] AS [LockProcess]
        , [p].[KPID]
        , [p].[SPID]
        , [p].[SBID]
        , [p].[ECID]
        , [p].[TranCount]
        , [l].[LockEvent]
        , ISNULL([l].[LockMode], '') AS [LockedMode]
        , [l].[WaitProcessID]
        , ISNULL([l].[WaitMode], '') AS [WaitMode]
        , ISNULL([p].[WaitResource], '') AS [WaitResource]
        , ISNULL([l].[WaitType], '') AS [WaitType]
        , ISNULL([p].[IsolationLevel], '') AS [IsolationLevel]
        , ISNULL([p].[LogUsed], '') AS [LogUsed]
        , ISNULL([p].[ClientApp], '') AS [ClientApp]
        , ISNULL([p].[HostName], '') AS [HostName]
        , ISNULL([p].[LoginName], '') AS [LoginName]
        , CONVERT(VARCHAR(30), ISNULL([p].[TransactionTime], ''), 113) AS [TransactionTime]
        , CONVERT(VARCHAR(30), [p].[BatchStarted], 113) AS [BatchStarted]
        , CONVERT(VARCHAR(30), [p].[BatchCompleted], 113) AS [BatchCompleted]
        , REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST([p].[InputBuffer] AS VARCHAR(MAX)), '<inputbuf/>', ''), '<inputbuf>', ''), CHAR(9), ''), CHAR(10), ''), CHAR(13), '') AS [InputBuffer]
    FROM [Locks] AS [l]
        INNER JOIN [Process] AS [p] ON [p].[ProcessID] = [l].[LockProcessID]
    ORDER BY
          [p].[IdDeadLock] ASC
        , [p].[Victim] DESC
        , [p].[ProcessId]

    -- ============================================================
    -- Captura do resultado de inserções
    -- ============================================================
    SET @contaInsert = @@ROWCOUNT

    -- ============================================================
    -- Tratamento do corpo do e-mail
    -- ============================================================
    SET @vBody = '
    <html>
        <head></head>
        <body>
        <div align=left>
    '

    IF (@contaInsert = 0)
    BEGIN
        SET @vBody = @vBody + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
            <tr height=20 style=color:black;>
                <td width=300 style=height:20.0pt>Não houve registros de DeadLock.
                    <br>Data dos eventos: ' + CONVERT(VARCHAR(12), @inicio, 105) + '
                    <br>Instância: ' + @@SERVERNAME + '
                </td>
            </tr>
        </table>
        '

        IF @ExibirApenasHtml = 0
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name   = 'CRAVIL'
              , @recipients     = 'suporte@cravil.com.br'
              , @subject        = @vSubject
              , @body           = @vBody
              , @body_format    = 'HTML'
            -- @file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
        END
        ELSE
        BEGIN
            SELECT @vBody
        END
    END
    ELSE
    BEGIN
        -- ============================================================
        -- Caso tenha registros, monta a mensagem com anexo
        -- ============================================================
        SET @vBody = @vBody + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
            <tr height=20 style=color:black;>
                <td width=300 style=height:20.0pt>Anexo dados de processos que sofreram DeadLock disponíveis para análise.
                    <br>Data dos eventos: ' + CONVERT(VARCHAR(12), @inicio, 105) + '
                    <br>Instância: ' + @@SERVERNAME + '
                </td>
            </tr>
        </table>
        '

        -- ============================================================
        -- Finaliza HTML
        -- ============================================================
        SET @vBody = @vBody + '
        </div>
        </body>
        </html>'

        -- ============================================================
        -- Montagem da query para anexo CSV
        -- ============================================================
        DECLARE @Query NVARCHAR(MAX)
        DECLARE @tab CHAR(1) = CHAR(9)

        SET @Query = '
        SET NOCOUNT ON;

        SELECT
              ''IdDeadLock''
            , ''Victim''
            , ''LockMode''
            , ''LockedObject''
            , ''DatabaseName''
            , ''AssociatedObjectId''
            , ''LockProcess''
            , ''KPID''
            , ''SPID''
            , ''SBID''
            , ''ECID''
            , ''TranCount''
            , ''LockEvent''
            , ''LockedMode''
            , ''WaitProcessID''
            , ''WaitMode''
            , ''WaitResource''
            , ''WaitType''
            , ''IsolationLevel''
            , ''LogUsed''
            , ''ClientApp''
            , ''HostName''
            , ''LoginName''
            , ''TransactionTime''
            , ''BatchStarted''
            , ''BatchCompleted''
            , ''InputBuffer''

        UNION ALL

        SELECT
              IdDeadLock
            , [Victim]
            , [LockMode]
            , [LockedObject]
            , DatabaseName
            , [AssociatedObjectId]
            , [LockProcess]
            , [KPID]
            , [SPID]
            , [SBID]
            , [ECID]
            , [TranCount]
            , [LockEvent]
            , [LockedMode]
            , [WaitProcessID]
            , [WaitMode]
            , [WaitResource]
            , [WaitType]
            , [IsolationLevel]
            , [LogUsed]
            , [ClientApp]
            , [HostName]
            , [LoginName]
            , [TransactionTime]
            , [BatchStarted]
            , [BatchCompleted]
            , [InputBuffer]
        FROM ##ReportDeadlock'

        -- ============================================================
        -- Envio do e-mail com anexo
        -- ============================================================
        IF @ExibirApenasHtml = 0
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name                   = 'CRAVIL'
              , @recipients                     = 'suporte@cravil.com.br'
              , @subject                        = @vSubject
              , @body                           = @vBody
              , @body_format                    = 'HTML'
              , @query                          = @Query
              , @attach_query_result_as_file    = 1
              , @query_attachment_filename      = 'DeadLock.csv'
              , @query_result_header            = 0
              , @query_result_separator         = @tab
              , @query_result_no_padding        = 1
              , @query_result_width             = 32767
            -- @file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
        END
        ELSE
        BEGIN
            SELECT @vBody
        END

        -- ============================================================
        -- Limpeza da tabela temporária
        -- ============================================================
        IF OBJECT_ID('tempdb..##ReportDeadlock') IS NOT NULL
        BEGIN
            DROP TABLE ##ReportDeadlock
        END
    END

    SET NOCOUNT OFF
END
GO
