----------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/sql-server-como-gerar-um-monitoramento-de-historico-de-deadlocks-para-analise-de-falhas-em-rotinas/
----------------------------------------------------------------------------------------------------------------------------------------------
IF (
    SELECT c.value_in_use
    FROM sys.configurations c
    WHERE c.name = N'blocked process threshold (s)'
    ) = 0
BEGIN
    EXEC sys.sp_configure @configname = N'blocked process threshold (s)', @configvalue = '5';
    RECONFIGURE
END


--------------------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------------------
IF NOT EXISTS ( /* only create this session if one doesn't already exist
                   to prevent inadvertant loss of events.
                */
    SELECT 1
    FROM sys.server_event_sessions ss
    WHERE ss.name = N'deadlocks'
    )
BEGIN
	CREATE EVENT SESSION deadlocks ON SERVER 
	ADD EVENT sqlserver.xml_deadlock_report(
		ACTION(sqlserver.client_app_name
		, sqlserver.client_hostname
		, sqlserver.database_name
		, sqlserver.plan_handle
		, sqlserver.session_id
		, sqlserver.session_server_principal_name
		, sqlserver.sql_text)
	)
	ADD TARGET package0.event_file ( 
    SET 
        filename = N'/var/opt/mssql/log_jobs/xe/deadlocks_report',
        max_file_size = ( 500 ),	-- Tamanho máximo (MB) de cada arquivo
        max_rollover_files = ( 8 )	-- Quantidade de arquivos gerados
)
	WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB, MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=OFF, STARTUP_STATE=ON)
END


--------------------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------------------
IF NOT EXISTS ( --XE sessions on show up in sys.dm_xe_sessions if they are running
    SELECT 1
    FROM sys.dm_xe_sessions xs
    WHERE xs.name = N'deadlocks'
    )
BEGIN
ALTER EVENT SESSION deadlocks ON SERVER STATE = START
END
GO


--------------------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------------------
USE P_HEALTHMAP_UNIMEDPA
GO

IF (OBJECT_ID('dbo.History_Deadlocks') IS NULL)
BEGIN
    CREATE TABLE dbo.History_Deadlocks
    (
        [dt_event] DATETIME NOT NULL,
		[processId] VARCHAR(100) NOT NULL,
        [isVictim] INT,        
        [processSqlCommand] XML,
        [resourceDBId] INT,
        [resourceDBName] NVARCHAR(128),
        [resourceObjectName] VARCHAR(128),
        [processWaitResource] VARCHAR(100),
        [processWaitTime] INT,
        [processTransactionName] VARCHAR(60),
        [processStatus] VARCHAR(60),
        [processSPID] INT,
        [processClientApp] VARCHAR(256),
        [processHostname] VARCHAR(256),
        [processLoginName] VARCHAR(256),
        [processIsolationLevel] VARCHAR(256),
        [processCurrentDb] VARCHAR(256),
        [processCurrentDbName] NVARCHAR(128),
        [processTranCount] INT,
        [processLockMode] VARCHAR(10),
		[transaction_time] datetime,
		[batch_started] datetime,
		[batch_completed] datetime,
        [resourceFileId] INT,
        [resourcePageId] INT,
        [resourceLockMode] VARCHAR(2),
        [resourceProcessOwner] VARCHAR(128),
        [resourceProcessOwnerMode] VARCHAR(2),
		
		PRIMARY KEY CLUSTERED ([dt_event], [processId])
    )
END


--------------------------------------------------------------------------------------------------------------
-- 
--------------------------------------------------------------------------------------------------------------
USE P_HEALTHMAP_UNIMEDPA
GO
CREATE OR ALTER PROCEDURE dbo.sp_Load_Deadlocks
AS
BEGIN
    DECLARE 
        @Ultimo_Log DATETIME2 = ISNULL((SELECT MAX([dt_event]) FROM dbo.History_Deadlocks WITH(NOLOCK)), '1900-01-01'),
        @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
    
    IF OBJECT_ID('tempdb..#xml_deadlock') IS NOT NULL 
        DROP TABLE #xml_deadlock

    SELECT
        *
    INTO
        #xml_deadlock
    FROM
    (
        SELECT
            module_guid,
            package_guid,
            [object_name],
            [file_name],
            [file_offset],
            DATEADD(HOUR, @TimeZone, CAST(timestamp_utc AS DATETIME2)) AS Dt_Evento,
            CAST(event_data AS XML) AS TargetData
        FROM 
            sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log_jobs/xe/deadlocks_report*.xel', NULL, NULL, NULL)
    ) AS [dados]
    WHERE
        Dt_Evento > @Ultimo_Log
    ORDER BY 
        Dt_Evento DESC


INSERT INTO dbo.History_Deadlocks
SELECT
    DATEADD(HOUR, @TimeZone, dados.event_data.value('@timestamp', 'datetimeoffset(7)')) AS [timestamp],        
    processo.dados.value('@id', 'varchar(100)') AS [processId],
	(CASE WHEN vitima.dados.value('@id', 'varchar(100)') = processo.dados.value('@id', 'varchar(100)') THEN 1 ELSE 0 END) AS isVictim,
    processo.dados.query('(inputbuf/text())') AS [processSqlCommand],
    recurso.resourceDBId,
    DB_NAME(recurso.resourceDBId) AS resourceDBName,
    recurso.resourceObjectName,
    processo.dados.value('@waitresource', 'varchar(100)') AS [processWaitResource],
    processo.dados.value('@waittime', 'int') AS [processWaitTime],
    processo.dados.value('@transactionname', 'varchar(60)') AS [processTransactionName],
    processo.dados.value('@status', 'varchar(60)') AS [processStatus],
    processo.dados.value('@spid', 'int') AS [processSPID],
    processo.dados.value('@clientapp', 'varchar(256)') AS [processClientApp],
    processo.dados.value('@hostname', 'varchar(256)') AS [processHostname],
    processo.dados.value('@loginname', 'varchar(256)') AS [processLoginName],
    processo.dados.value('@isolationlevel', 'varchar(256)') AS [processIsolationLevel],
    processo.dados.value('@currentdb', 'varchar(256)') AS [processCurrentDb],
    DB_NAME(processo.dados.value('@currentdb', 'varchar(256)')) AS [processCurrentDbName],
    processo.dados.value('@trancount', 'int') AS [processTranCount],
    processo.dados.value('@lockMode', 'varchar(10)') AS [processLockMode],
	processo.dados.value('@lasttranstarted', 'datetime') AS [TransactionTime],
	processo.dados.value('@lastbatchstarted', 'datetime') AS [BatchStarted],
	processo.dados.value('@lastbatchcompleted', 'datetime') AS [BatchCompleted],
    recurso.resourceFileId,
    recurso.resourcePageId,
    recurso.resourceLockMode,
    recurso.resourceProcessOwner,
    recurso.resourceProcessOwnerMode
FROM
    #xml_deadlock A
    CROSS APPLY A.TargetData.nodes('//event') AS dados(event_data)
    CROSS APPLY dados.event_data.nodes('data/value/deadlock/victim-list/victimProcess') AS vitima(dados)
    OUTER APPLY dados.event_data.nodes('data/value/deadlock/process-list/process') AS processo(dados)
    LEFT JOIN (
        SELECT
            A.Dt_Evento,
            recurso.dados.value('@fileid', 'int') AS [resourceFileId],
            recurso.dados.value('@pageid', 'int') AS [resourcePageId],
            recurso.dados.value('@dbid', 'int') AS [resourceDBId],
            recurso.dados.value('@objectname', 'varchar(128)') AS [resourceObjectName],
            recurso.dados.value('@mode', 'varchar(2)') AS [resourceLockMode],
            [owner].dados.value('@id', 'varchar(128)') AS [resourceProcessOwner],
            [owner].dados.value('@mode', 'varchar(2)') AS [resourceProcessOwnerMode]
        FROM 
            #xml_deadlock A
            CROSS APPLY A.TargetData.nodes('//ridlock') AS recurso(dados)
            OUTER APPLY recurso.dados.nodes('owner-list/owner') AS owner(dados)
    ) AS recurso ON recurso.resourceProcessOwner = processo.dados.value('@id', 'varchar(100)') AND recurso.Dt_Evento = A.Dt_Evento

END
GO


--------------------------------------------------------------------------------------------------------------
-- automatizando com Job do sql server
--------------------------------------------------------------------------------------------------------------
USE [msdb]
GO
DECLARE @jobId BINARY(16)
EXEC  msdb.dbo.sp_add_job @job_name=N'DIXHEALTH - Collect_Deadlocks', 
@enabled=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@category_name=N'Database Maintenance', 
@owner_login_name=N'healthmap', @job_id = @jobId OUTPUT
select @jobId
GO

-- vincula o target server
EXEC msdb.dbo.sp_add_jobserver @job_name=N'DIXHEALTH - Collect_Deadlocks', @server_name =  N'(local)'
GO

USE [msdb]
GO
EXEC msdb.dbo.sp_add_jobstep @job_name=N'DIXHEALTH - Collect_Deadlocks', @step_name=N'Executa SP', 
@step_id=1, 
@cmdexec_success_code=0, 
@on_success_action=1, 
@on_fail_action=2, 
@retry_attempts=0, 
@retry_interval=0, 
@os_run_priority=0, @subsystem=N'TSQL', 
@command=N'EXEC dbo.sp_Load_Deadlocks', 
@database_name=N'P_HEALTHMAP_UNIMEDPA', 
@flags=8
GO


USE [msdb]
GO
EXEC msdb.dbo.sp_update_job @job_name=N'DIXHEALTH - Collect_Deadlocks', 
@enabled=1, 
@start_step_id=1, 
@notify_level_eventlog=0, 
@notify_level_email=2, 
@notify_level_page=2, 
@delete_level=0, 
@description=N'', 
@category_name=N'Database Maintenance', 
@owner_login_name=N'healthmap', 
@notify_email_operator_name=N'', 
@notify_page_operator_name=N''
GO


USE [msdb]
GO
DECLARE @schedule_id int
EXEC msdb.dbo.sp_add_jobschedule @job_name=N'DIXHEALTH - Collect_Deadlocks', @name=N'A cada 4 minutos', 
@enabled=1, 
@freq_type=4, 
@freq_interval=1, 
@freq_subday_type=4, 
@freq_subday_interval=4, 
@freq_relative_interval=0, 
@freq_recurrence_factor=1, 
@active_start_date=20190218, 
@active_end_date=99991231, 
@active_start_time=112, 
@active_end_time=235959, @schedule_id = @schedule_id OUTPUT
select @schedule_id
GO


--------------------------------------------------------------------------------------------------------------
-- replicação dos mesmo dados em outra tabela para possibilitar outra visão dos processos
--------------------------------------------------------------------------------------------------------------
IF OBJECT_ID(N'dbo.History_Deadlock_Xml_Events', N'U') IS NULL
CREATE TABLE dbo.History_Deadlock_Xml_Events
(
   xeTimeStamp datetimeoffset NOT NULL
 , xeProcessID varchar(20) NOT NULL
 , xeXML XML NOT NULL
 , CONSTRAINT deadlock_xml_events_pk
 PRIMARY KEY CLUSTERED (xeTimeStamp, xeProcessID)
);


CREATE OR ALTER PROCEDURE dbo.sp_Gather_Deadlock_Events
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON;

    IF OBJECT_ID('tempdb..#xmlResults') IS NOT NULL DROP TABLE #xmlResults

    CREATE TABLE #xmlResults
    (
          xeTimeStamp datetimeoffset NOT NULL
        , xeProcessID varchar(20) NOT NULL
        , xeXML XML NOT NULL
        , PRIMARY KEY CLUSTERED (xeTimeStamp, xeProcessID)
    )    

    DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())

    ;WITH src AS 
    (
            SELECT            
            CAST(event_data AS XML) AS xeXML
            FROM 
            sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log_jobs/xe/deadlocks_report*.xel', NULL, NULL, NULL)
    )
    INSERT INTO #xmlResults (xeXML, xeTimeStamp, xeProcessID)
    SELECT src.xeXML
        , [xeTimeStamp] = DATEADD(HOUR, @TimeZone, src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)'))        
        , xeProcessID = src.xeXML.value('(/event/data/value/deadlock/victim-list/victimProcess/@id)[1]', 'varchar(20)')
    FROM src

    INSERT INTO dbo.History_Deadlock_Xml_Events (xeProcessID, xeTimeStamp, xeXML)
    SELECT xr.xeProcessID
        , xr.xeTimeStamp
        , xr.xeXML
    FROM #xmlResults xr
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.History_Deadlock_Xml_Events dxe
        WHERE dxe.xeTimeStamp = xr.xeTimeStamp
            AND dxe.xeProcessID = xr.xeProcessID
        )
END 
GO


--------------------------------------------------------------------------------------------------------------
-- JOB FINAL PARA EXECUÇÃO DAS 2 PROCEDURES
--------------------------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [DIXHEALTH - Collect_Deadlocks]    Script Date: 11/05/2023 22:14:45 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 11/05/2023 22:14:46 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DIXHEALTH - Collect_Deadlocks', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'healthmap', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Executa sp_Load_Deadlocks]    Script Date: 11/05/2023 22:14:48 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Executa sp_Load_Deadlocks', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.sp_Load_Deadlocks', 
		@database_name=N'P_HEALTHMAP_UNIMEDPA', 
		@flags=8
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Executa sp_Gather_Deadlock_Events]    Script Date: 11/05/2023 22:14:49 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Executa sp_Gather_Deadlock_Events', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC dbo.sp_Gather_Deadlock_Events', 
		@database_name=N'P_HEALTHMAP_UNIMEDPA', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'A cada 4 minutos', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=4, 
		@freq_subday_interval=4, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20190218, 
		@active_end_date=99991231, 
		@active_start_time=112, 
		@active_end_time=235959, 
		@schedule_uid=N'567cc67f-6a66-4215-b6c3-6cf04dc7917f'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO