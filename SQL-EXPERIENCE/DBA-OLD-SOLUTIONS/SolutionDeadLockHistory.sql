/*
 *
	OBJETIVO: Captura e análise de histórico de DeadLocks no SQL Server via Service Broker
	          e Event Notification, incluindo extração de dados do grafo XML para análise
	          de performance e identificação de usuários afetados.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.sqlskills.com/blogs/jonathan/how-much-memory-does-my-sql-server-actually-need/
 */
-- ===============================================================
-- Objetos para captura de DeadLocks
-- ===============================================================

------------------------------------------------------------------
-- 1. Configuração inicial: habilitar Service Broker e Trustworthy
------------------------------------------------------------------
USE [YOUR_DATABASE];
GO

ALTER DATABASE [YOUR_DATABASE] SET ENABLE_BROKER;
GO

-- Caso haja problema de mesmo ID do Service Broker
-- ALTER DATABASE [YOUR_DATABASE] SET NEW_BROKER;

ALTER DATABASE [YOUR_DATABASE] SET TRUSTWORTHY ON;
GO

-- Automatizando o processo caso tenha problema de mesmo ID do Service Broker
-- DECLARE @SQL NVARCHAR(MAX);
-- BEGIN TRY
--     SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE';
--     PRINT @SQL;
--     EXEC sp_executesql @SQL;
-- END TRY
-- BEGIN CATCH
--     SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE';
--     PRINT @SQL;
--     EXEC sp_executesql @SQL;
-- END CATCH
-- GO


------------------------------------------------------------------
-- 2. Configuração do threshold para geração 
-- de eventos de processo bloqueado (em segundos)
------------------------------------------------------------------
EXEC sp_configure 'show advanced options', 1;
GO

RECONFIGURE;
GO

EXEC sp_configure 'blocked process threshold', 10;
GO

RECONFIGURE WITH OVERRIDE;
GO


------------------------------------------------------------------
-- 3. Criação da tabela de histórico de DeadLocks
------------------------------------------------------------------
USE [YOUR_DATABASE];
GO

IF EXISTS (
    SELECT [name]
    FROM [sys].[tables]
    WHERE [name] = 'HistoryDeadLock'
)
BEGIN
    DROP TABLE [HistoryDeadLock];
END
GO

CREATE TABLE [HistoryDeadLock]
(
    [IdDeadLock] INT IDENTITY(1, 1) NOT NULL,
    [DateDeadLock] DATETIME NULL,
    [DatabaseName] VARCHAR(255) NULL,
    [GraphDeadLock] XML NULL,
    CONSTRAINT [PK_DeadLock] PRIMARY KEY CLUSTERED ([IdDeadLock] ASC)
)
ON [PRIMARY];
GO


------------------------------------------------------------------
-- 4. Criação da Queue, Service e 
-- Event Notification para captura de DeadLocks
------------------------------------------------------------------
USE [DBA_PerformanceHub];
GO

CREATE QUEUE [Audit_DeadLock_Queue];
GO

CREATE SERVICE [Audit_DeadLock_Service]
    ON QUEUE [Audit_DeadLock_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION [Audit_DeadLock_Event]
    ON SERVER
    WITH FAN_IN
    FOR DEADLOCK_GRAPH
    TO SERVICE 'Audit_DeadLock_Service', 'current database';
GO

-- DROP EVENT NOTIFICATION [Audit_DeadLock_Event] ON SERVER;


------------------------------------------------------------------
-- 5. Procedure para processamento da fila de DeadLocks
------------------------------------------------------------------
USE [DBA_PerformanceHub];
GO

CREATE OR ALTER PROCEDURE [Management].[sp_DeadLock]
    WITH EXECUTE AS OWNER, ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @conversation_handle UNIQUEIDENTIFIER;
    DECLARE @message_body XML;
    DECLARE @message_type_name NVARCHAR(128);
    DECLARE @deadlock_graph XML;
    DECLARE @event_datetime DATETIME;
    DECLARE @deadlock_id INT;
    DECLARE @DBname SYSNAME;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- Aguarda mensagem na fila com timeout de 10 segundos
        WAITFOR
        (
            RECEIVE TOP (1)
                @conversation_handle = [conversation_handle],
                @message_body = CAST([message_body] AS XML),
                @message_type_name = [message_type_name]
            FROM [dbo].[Audit_DeadLock_Queue]
        ), TIMEOUT 10000;

        -- Processa apenas eventos de notificação com dados de deadlock
        IF @message_type_name = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
            AND @message_body.exist('(/EVENT_INSTANCE/TextData/deadlock-list)') = 1
        BEGIN
            SELECT
                @deadlock_graph = @message_body.query('(/EVENT_INSTANCE/TextData/deadlock-list)'),
                @event_datetime = @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime'),
                @DBname = DB_NAME(@message_body.value('(//*/process/@currentdb)[1]', 'varchar(10)'));

            INSERT INTO [DBA_PerformanceHub].[Management].[HistoryDeadLock]
            (
                [DateDeadLock],
                [DatabaseName],
                [GraphDeadLock]
            )
            VALUES
            (
                @event_datetime,
                @DBname,
                @message_body
            );
        END
        ELSE
        BEGIN
            END CONVERSATION @conversation_handle;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
    END CATCH

    SET NOCOUNT OFF;
END
GO


------------------------------------------------------------------
-- 6. Ativação da Queue para processamento automático
------------------------------------------------------------------
ALTER QUEUE [Audit_DeadLock_Queue]
    WITH ACTIVATION
    (
        STATUS = ON,
        PROCEDURE_NAME = [Management].[sp_DeadLock],
        MAX_QUEUE_READERS = 1,
        EXECUTE AS OWNER
    );
GO


-- ===============================================================
-- Análises diversas sobre histórico de DeadLocks
-- ===============================================================
------------------------------------------------------------------
-- Consulta detalhada de DeadLocks com extração de dados do XML
------------------------------------------------------------------
USE [DBA_PerformanceHub];
GO

WITH [cte_DeadLock] AS (
    SELECT
        [IdDeadLock],
        [DateDeadLock],
        [GraphDeadLock]
    FROM [HistoryDeadLock]
),
[Victims] AS (
    SELECT
        [ID] = [Victims].[List].value('@id', 'varchar(50)')
    FROM [cte_DeadLock]
    CROSS APPLY [cte_DeadLock].[GraphDeadLock].[nodes]('//deadlock/victim-list/victimProcess') AS [Victims]([List])
),
[Locks] AS (
    SELECT
        [cte_DeadLock].[IdDeadLock],
        [MainLock].[Process].value('@id', 'varchar(100)') AS [LockID],
        [OwnerList].[Owner].value('@id', 'varchar(200)') AS [LockProcessId],
        REPLACE([MainLock].[Process].value('local-name(.)', 'varchar(100)'), 'lock', '') AS [LockEvent],
        [MainLock].[Process].value('@objectname', 'sysname') AS [ObjectName],
        [OwnerList].[Owner].value('@mode', 'varchar(10)') AS [LockMode],
        [MainLock].[Process].value('@dbid', 'INTEGER') AS [Database_id],
        [MainLock].[Process].value('@associatedObjectId', 'BIGINT') AS [AssociatedObjectId],
        [MainLock].[Process].value('@WaitType', 'varchar(100)') AS [WaitType],
        [WaiterList].[Owner].value('@id', 'varchar(200)') AS [WaitProcessId],
        [WaiterList].[Owner].value('@mode', 'varchar(10)') AS [WaitMode]
    FROM [cte_DeadLock]
    CROSS APPLY [cte_DeadLock].[GraphDeadLock].[nodes]('//deadlock/resource-list') AS [Locks]([list])
    CROSS APPLY [Locks].[List].[nodes]('*') AS [MainLock]([Process])
    CROSS APPLY [MainLock].[Process].[nodes]('owner-list/owner') AS [OwnerList]([Owner])
    CROSS APPLY [MainLock].[Process].[nodes]('waiter-list/waiter') AS [WaiterList]([Owner])
),
[Process] AS (
    SELECT
        [cte_DeadLock].[IdDeadLock],
        [Victim] = CONVERT(BIT,
            CASE
                WHEN [Deadlock].[Process].value('@id', 'varchar(50)') = ISNULL([Deadlock].[Process].value('../../@victim', 'varchar(50)'), [v].[ID])
                THEN 1
                ELSE 0
            END
        ),
        [LockMode] = [Deadlock].[Process].value('@lockMode', 'varchar(10)'),
        [ProcessID] = [Process].[ID],
        [KPID] = [Deadlock].[Process].value('@kpid', 'int'),
        [SPID] = [Deadlock].[Process].value('@spid', 'int'),
        [SBID] = [Deadlock].[Process].value('@sbid', 'int'),
        [ECID] = [Deadlock].[Process].value('@ecid', 'int'),
        [IsolationLevel] = [Deadlock].[Process].value('@isolationlevel', 'varchar(200)'),
        [WaitResource] = [Deadlock].[Process].value('@waitresource', 'varchar(200)'),
        [LogUsed] = [Deadlock].[Process].value('@logused', 'int'),
        [ClientApp] = [Deadlock].[Process].value('@clientapp', 'varchar(100)'),
        [HostName] = [Deadlock].[Process].value('@hostname', 'varchar(20)'),
        [LoginName] = [Deadlock].[Process].value('@loginname', 'varchar(20)'),
        [TransactionTime] = [Deadlock].[Process].value('@lasttranstarted', 'datetime'),
        [BatchStarted] = [Deadlock].[Process].value('@lastbatchstarted', 'datetime'),
        [BatchCompleted] = [Deadlock].[Process].value('@lastbatchcompleted', 'datetime'),
        [InputBuffer] = [Input].[Buffer].query('.'),
        [cte_DeadLock].[GraphDeadLock],
        [QueryStatement] = [Execution].[Frame].value('.', 'varchar(max)'),
        [TranCount] = [Deadlock].[Process].value('@trancount', 'int')
    FROM [cte_DeadLock]
    CROSS APPLY [cte_DeadLock].[GraphDeadLock].[nodes]('//deadlock/process-list/process') AS [Deadlock]([Process])
    CROSS APPLY (
        SELECT [Deadlock].[Process].value('@id', 'varchar(50)')
    ) AS [Process]([ID])
    LEFT JOIN [Victims] AS [v]
        ON [Process].[ID] = [v].[ID]
    CROSS APPLY [Deadlock].[Process].[nodes]('inputbuf') AS [Input]([Buffer])
    CROSS APPLY [Deadlock].[Process].[nodes]('executionStack') AS [Execution]([Frame])
)
SELECT
    [p].[IdDeadLock],
    [p].[Victim],
    [p].[LockMode],
    [LockedObject] = NULLIF([l].[ObjectName], ''),
    [l].[database_id],
    [l].[AssociatedObjectId],
    [LockProcess] = [p].[ProcessID],
    [p].[KPID],
    [p].[SPID],
    [p].[SBID],
    [p].[ECID],
    [p].[TranCount],
    [l].[LockEvent],
    [LockedMode] = [l].[LockMode],
    [l].[WaitProcessID],
    [l].[WaitMode],
    [p].[WaitResource],
    [l].[WaitType],
    [p].[IsolationLevel],
    [p].[LogUsed],
    [p].[ClientApp],
    [p].[HostName],
    [p].[LoginName],
    [p].[TransactionTime],
    [p].[BatchStarted],
    [p].[BatchCompleted],
    [p].[InputBuffer]
FROM [Locks] AS [l]
INNER JOIN [Process] AS [p]
    ON [p].[ProcessID] = [l].[LockProcessID]
ORDER BY
    [p].[IdDeadLock] ASC,
    [p].[Victim] DESC,
    [p].[ProcessId];


------------------------------------------------------------------
-- Totalização de DeadLocks por dia
------------------------------------------------------------------
SELECT
    COUNT([d].[IdDeadLock]) AS [total],
    CONVERT(VARCHAR(10), [d].[DateDeadLock], 103) AS [date],
    [d].[DatabaseName]
FROM [YOUR_DATABASE].[Management].[HistoryDeadLock] AS [d]
WHERE [d].[DatabaseName] IS NOT NULL
    AND [d].[DateDeadLock] IS NOT NULL
    AND [d].[DateDeadLock] BETWEEN '2017-03-28' AND GETDATE()
GROUP BY
    SUBSTRING(CONVERT(VARCHAR(10), [d].[DateDeadLock], 103), 4, 2),
    CONVERT(VARCHAR(10), [d].[DateDeadLock], 103),
    [d].[DatabaseName];

-- Totalização de DeadLocks por semana
DECLARE @decremento SMALLINT;
DECLARE @limite SMALLINT;
DECLARE @dia DATETIME;

IF OBJECT_ID('tempdb.dbo.##semanas') IS NOT NULL
BEGIN
    DROP TABLE [##semanas];
END

CREATE TABLE [##semanas]
(
    [TotalDeaLock] INT NULL,
    [DateDeadLock] VARCHAR(12) NULL,
    [DatabaseName] VARCHAR(50) NULL
);

SET @limite = (
    SELECT DATEDIFF(WEEK, '2017-03-28', GETDATE()) * -1
);

SET @decremento = 1;

WHILE (@limite <= @decremento)
BEGIN
    SET @dia = (
        SELECT CAST(DATEADD(WEEK, @decremento, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)) AS DATE)
    );

    INSERT INTO [##semanas]
    SELECT
        SUM([x].[TotalBlock]) AS [TotalDeadLock],
        MAX([x].[DateDeadLock]) AS [LastDayWeek],
        [x].[DatabaseName]
    FROM (
        SELECT
            COUNT([h].[IdDeadLock]) AS [TotalBlock],
            CONVERT(VARCHAR(12), [h].[DateDeadLock], 103) AS [DateDeadLock],
            [h].[DatabaseName]
        FROM [YOUR_DATABASE].[Management].[HistoryDeadLock] AS [h]
        WHERE [h].[DatabaseName] IS NOT NULL
            AND [h].[DateDeadLock] IS NOT NULL
            AND CAST([h].[DateDeadLock] AS DATE) BETWEEN DATEADD(WEEK, -1, CAST(CAST(FLOOR(CAST(@dia AS FLOAT)) AS DATETIME) AS DATE)) AND CAST(@dia AS DATE)
        GROUP BY
            SUBSTRING(CONVERT(VARCHAR(12), [h].[DateDeadLock], 103), 4, 2),
            CONVERT(VARCHAR(12), [h].[DateDeadLock], 103),
            [h].[DatabaseName]
    ) AS [x]
    GROUP BY
        [x].[DatabaseName];

    SET @decremento = @decremento - 1;
END

SELECT
    [s].[TotalDeaLock],
    [s].[DateDeadLock],
    [s].[DatabaseName]
FROM [##semanas] AS [s];

IF OBJECT_ID('tempdb.dbo.##semanas') IS NOT NULL
BEGIN
    DROP TABLE [##semanas];
END


------------------------------------------------------------------
-- Visão para PowerBI com dia da semana
------------------------------------------------------------------
SELECT
    [x].[DateDeadLock] AS [Data de Referência],
    CASE
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 1 THEN 'Domingo'
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 2 THEN 'Segunda'
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 3 THEN 'Terça'
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 4 THEN 'Quarta'
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 5 THEN 'Quinta'
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 6 THEN 'Sexta'
        WHEN DATEPART(WEEKDAY, [x].[DateDeadLock]) = 7 THEN 'Sábado'
    END AS [Dia da Semana],
    [x].[DatabaseName] AS [Nome Database],
    COUNT([x].[IdDeadLock]) AS [Total DeadLock]
FROM (
    SELECT
        [h].[IdDeadLock],
        CAST([h].[DateDeadLock] AS DATE) AS [DateDeadLock],
        [h].[DatabaseName]
    FROM [YOUR_DATABASE].[Management].[HistoryDeadLock] AS [h]
    WHERE [h].[DatabaseName] IS NOT NULL
        AND [h].[DateDeadLock] IS NOT NULL
) AS [x]
GROUP BY
    [x].[DateDeadLock],
    [x].[DatabaseName];


------------------------------------------------------------------
-- Contagem de usuários distintos afetados por DeadLock por dia
------------------------------------------------------------------
USE [YOUR_DATABASE];
GO

WITH [cte_DeadLock] AS (
    SELECT
        [IdDeadLock],
        [DateDeadLock],
        [DatabaseName],
        [GraphDeadLock]
    FROM [Management].[HistoryDeadLock]
    WHERE [DateDeadLock] >= '20181221'
),
[Victims] AS (
    SELECT
        [ID] = [Victims].[List].value('@id', 'varchar(50)')
    FROM [cte_DeadLock]
    CROSS APPLY [cte_DeadLock].[GraphDeadLock].[nodes]('//deadlock/victim-list/victimProcess') AS [Victims]([List])
),
[Locks] AS (
    SELECT
        [cte_DeadLock].[IdDeadLock],
        [MainLock].[Process].value('@id', 'varchar(100)') AS [LockID],
        [OwnerList].[Owner].value('@id', 'varchar(200)') AS [LockProcessId],
        REPLACE([MainLock].[Process].value('local-name(.)', 'varchar(100)'), 'lock', '') AS [LockEvent],
        [MainLock].[Process].value('@objectname', 'sysname') AS [ObjectName],
        [OwnerList].[Owner].value('@mode', 'varchar(10)') AS [LockMode],
        [cte_DeadLock].[DatabaseName] AS [DatabaseName],
        [MainLock].[Process].value('@associatedObjectId', 'BIGINT') AS [AssociatedObjectId],
        [MainLock].[Process].value('@WaitType', 'varchar(100)') AS [WaitType],
        [WaiterList].[Owner].value('@id', 'varchar(200)') AS [WaitProcessId],
        [WaiterList].[Owner].value('@mode', 'varchar(10)') AS [WaitMode]
    FROM [cte_DeadLock]
    CROSS APPLY [cte_DeadLock].[GraphDeadLock].[nodes]('//deadlock/resource-list') AS [Locks]([list])
    CROSS APPLY [Locks].[List].[nodes]('*') AS [MainLock]([Process])
    CROSS APPLY [MainLock].[Process].[nodes]('owner-list/owner') AS [OwnerList]([Owner])
    CROSS APPLY [MainLock].[Process].[nodes]('waiter-list/waiter') AS [WaiterList]([Owner])
),
[Process] AS (
    SELECT
        [cte_DeadLock].[IdDeadLock],
        [Victim] = CONVERT(BIT,
            CASE
                WHEN [Deadlock].[Process].value('@id', 'varchar(50)') = ISNULL([Deadlock].[Process].value('../../@victim', 'varchar(50)'), [v].[ID])
                THEN 1
                ELSE 0
            END
        ),
        [LockMode] = [Deadlock].[Process].value('@lockMode', 'varchar(10)'),
        [ProcessID] = [Process].[ID],
        [KPID] = [Deadlock].[Process].value('@kpid', 'int'),
        [SPID] = [Deadlock].[Process].value('@spid', 'int'),
        [SBID] = [Deadlock].[Process].value('@sbid', 'int'),
        [ECID] = [Deadlock].[Process].value('@ecid', 'int'),
        [IsolationLevel] = [Deadlock].[Process].value('@isolationlevel', 'varchar(200)'),
        [WaitResource] = [Deadlock].[Process].value('@waitresource', 'varchar(200)'),
        [LogUsed] = [Deadlock].[Process].value('@logused', 'int'),
        [ClientApp] = [Deadlock].[Process].value('@clientapp', 'varchar(100)'),
        [HostName] = [Deadlock].[Process].value('@hostname', 'varchar(20)'),
        [LoginName] = [Deadlock].[Process].value('@loginname', 'varchar(20)'),
        [TransactionTime] = [Deadlock].[Process].value('@lasttranstarted', 'datetime'),
        [BatchStarted] = [Deadlock].[Process].value('@lastbatchstarted', 'datetime'),
        [BatchCompleted] = [Deadlock].[Process].value('@lastbatchcompleted', 'datetime'),
        [InputBuffer] = [Input].[Buffer].query('.'),
        [cte_DeadLock].[GraphDeadLock],
        [QueryStatement] = [Execution].[Frame].value('.', 'varchar(max)'),
        [TranCount] = [Deadlock].[Process].value('@trancount', 'int')
    FROM [cte_DeadLock]
    CROSS APPLY [cte_DeadLock].[GraphDeadLock].[nodes]('//deadlock/process-list/process') AS [Deadlock]([Process])
    CROSS APPLY (
        SELECT [Deadlock].[Process].value('@id', 'varchar(50)')
    ) AS [Process]([ID])
    LEFT JOIN [Victims] AS [v]
        ON [Process].[ID] = [v].[ID]
    CROSS APPLY [Deadlock].[Process].[nodes]('inputbuf') AS [Input]([Buffer])
    CROSS APPLY [Deadlock].[Process].[nodes]('executionStack') AS [Execution]([Frame])
)
SELECT DISTINCT
    COUNT([y].[TotalPorDia]) OVER (PARTITION BY [y].[TransactionTime]) AS [Total Logins Distintos Envolvidos],
    [y].[TransactionTime],
    COALESCE([y].[DatabaseName], '') AS [DatabaseName]
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY [x].[LoginName]) AS [TotalPorDia],
        [x].[LoginName],
        [x].[TransactionTime],
        [x].[DatabaseName]
    FROM (
        SELECT DISTINCT
            [l].[DatabaseName],
            ISNULL([p].[LoginName], '') AS [LoginName],
            CAST([p].[TransactionTime] AS DATE) AS [TransactionTime]
        FROM [Locks] AS [l]
        INNER JOIN [Process] AS [p]
            ON [p].[ProcessID] = [l].[LockProcessID]
    ) AS [x]
) AS [y];
