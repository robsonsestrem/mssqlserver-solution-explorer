/*
Detectar quando os deadlocks ocorrem é o primeiro passo para a mitigação. Uma vez detectados, 
gostaríamos de fornecer esses detalhes de detecção aos administradores de banco de dados para correção. 
A primeira etapa é habilitar a opção de configuração do sistema “limite de processo bloqueado”. Este código executa essa alteração:
*/

IF (
    SELECT c.value_in_use
    FROM sys.configurations c
    WHERE c.name = N'blocked process threshold (s)'
    ) = 0
BEGIN
    EXEC sys.sp_configure @configname = N'blocked process threshold (s)', @configvalue = '5';
    RECONFIGURE
END

/*
Em seguida, criamos a sessão Extended Events que coleta dados XML do SQL Server sempre que um deadlock é detectado:
*/

/*
    Creates the deadlocks Extended Events session to capture deadlock events
    into a ring_buffer target.  Yes, I know, ring buffer.  See this site for some gotchas:
    https://www.sqlskills.com/blogs/jonathan/why-i-hate-the-ring_buffer-target-in-extended-events/
*/
IF NOT EXISTS ( /* only create this session if one doesn't already exist
                   to prevent inadvertant loss of events.
                */
    SELECT 1
    FROM sys.server_event_sessions ss
    WHERE ss.name = N'deadlocks'
    )
BEGIN
    CREATE EVENT SESSION [deadlocks] ON SERVER 
    ADD EVENT sqlserver.xml_deadlock_report (
        ACTION (
              sqlserver.client_app_name
            , sqlserver.client_hostname
            , sqlserver.database_name
            )
        )
    ADD TARGET package0.ring_buffer(
        SET   max_memory        = 2048 /* Maximum amount of memory in KB to use. Old events are dropped
                                          when this value is reached. 0 means unbounded.
                                          2048 is recommended to avoid posible XML data truncation */
            , occurrence_number = 0    /* Preferred number of events of each type to keep. */
            , max_events_limit  = 0    /* Maximum number of events to store. Old events are 
                                          dropped when this value is reached. 0 means unbounded. */
        )
    WITH (
          MAX_MEMORY = 10 MB
        , EVENT_RETENTION_MODE = ALLOW_SINGLE_EVENT_LOSS
        , MAX_DISPATCH_LATENCY = 5 SECONDS
        , MAX_EVENT_SIZE = 0 KB
        , MEMORY_PARTITION_MODE = NONE
        , TRACK_CAUSALITY = OFF
        , STARTUP_STATE = ON
        );
END
IF NOT EXISTS ( --XE sessions on show up in sys.dm_xe_sessions if they are running
    SELECT 1
    FROM sys.dm_xe_sessions xs
    WHERE xs.name = N'deadlocks'
    )
BEGIN
    ALTER EVENT SESSION [deadlocks] ON SERVER 
    STATE = START;
END
GO

/*
Em seguida, criaremos a procedure dbo.GatherDeadlockEvents. 
Essa pprocedure captura eventos de detecção de deadlock da sessão de eventos estendidos. 
Ele salva os eventos no banco d_maintenance_hmg. Ele usa o carimbo de data/hora de eventos estendidos 
e o ID do processo encerrado para capturar apenas eventos de deadlock do ring_buffer (xe system_health) que não foram capturados anteriormente. 
Há um potencial muito pequeno de perder eventos se eles ocorrerem muito rapidamente e tiverem o mesmo ID de processo.
*/


USE d_maintenance_hmg;
GO
IF OBJECT_ID(N'dbo.GatherDeadlockEvents', N'P') IS NOT NULL
BEGIN
    DROP PROCEDURE dbo.GatherDeadlockEvents;
END
GO
/*
    Gathers deadlock events from the ring buffer target
    into the dbo.deadlock_xml_events table.
    Should be ran from a frequently occurring SQL Server
    Agent job.
*/
CREATE PROCEDURE dbo.GatherDeadlockEvents
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON;

    IF OBJECT_ID(N'dbo.deadlock_xml_events', N'U') IS NULL
    CREATE TABLE dbo.deadlock_xml_events
    (
          xeTimeStamp datetimeoffset NOT NULL
        , xeProcessID varchar(20) NOT NULL
        , xeXML XML NOT NULL
        , CONSTRAINT deadlock_xml_events_pk
            PRIMARY KEY CLUSTERED (xeTimeStamp, xeProcessID)
    );

    IF OBJECT_ID(N'tempdb..#xmlResults', N'U') IS NULL
    CREATE TABLE #xmlResults
    (
          xeTimeStamp datetimeoffset NOT NULL
        , xeProcessID varchar(20) NOT NULL
        , xeXML XML NOT NULL
        , PRIMARY KEY CLUSTERED (xeTimeStamp, xeProcessID)
    );

    TRUNCATE TABLE #xmlResults;

    DECLARE @target_data xml;
    SELECT @target_data = CONVERT(xml, target_data)
    FROM sys.dm_xe_sessions AS s 
    JOIN sys.dm_xe_session_targets AS t 
        ON t.event_session_address = s.address
    WHERE s.name = N'deadlocks'
        AND t.target_name = N'ring_buffer';

    ;WITH src AS 
    (
        SELECT xeXML = xm.s.query('.')
        FROM @target_data.nodes('/RingBufferTarget/event') AS xm(s)
    )
    INSERT INTO #xmlResults (xeXML, xeTimeStamp, xeProcessID)
    SELECT src.xeXML
        , [xeTimeStamp] = src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')
        , xeProcessID = src.xeXML.value('(/event/data/value/deadlock/victim-list/victimProcess/@id)[1]', 'varchar(20)')
    FROM src

    INSERT INTO dbo.deadlock_xml_events (xeProcessID, xeTimeStamp, xeXML)
    SELECT xr.xeProcessID
        , xr.xeTimeStamp
        , xr.xeXML
    FROM #xmlResults xr
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.deadlock_xml_events dxe
        WHERE dxe.xeTimeStamp = xr.xeTimeStamp
            AND dxe.xeProcessID = xr.xeProcessID
        );
END
GO


/*
Esse código executa o procedimento armazenado uma vez para criar a dbo.deadlock_xml_eventstabela.
*/

/*
    Creates a SQL Server Agent job to run the dbo.GatherDeadlockEvents stored procedure.
    The job is scheduled to run every 5 minutes.
*/

DECLARE @JobID BINARY(16) = NULL;
DECLARE @ScheduleID int = NULL;

IF NOT EXISTS (
    SELECT 1 
    FROM msdb.dbo.sysjobs sj 
    WHERE sj.name = N'DIX : Hitory Deadlock Events'
    )
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM msdb.dbo.syscategories sc 
        WHERE sc.name = N'DBA Tools'
        )
    BEGIN
        EXEC msdb.dbo.sp_add_category @class = 'JOB'
            , @type = 'LOCAL'
            , @name = N'DBA Tools';
    END

    EXEC msdb.dbo.sp_add_job @job_name = N'DBA : Gather Deadlock Events'
        , @enabled = 1
        , @description = N'Gathers deadlock XML event data from the deadlocks Extended Events Session, and persists the data in dbo.deadlock_xml_events.'
        , @start_step_id = 1
        , @category_name = N'DBA Tools'
        , @owner_login_name = N'sa'
        , @notify_level_eventlog = 0
        , @notify_level_email = 2
        , @notify_level_netsend = 0
        , @notify_level_page = 0
        , @notify_email_operator_name = N''
        , @notify_netsend_operator_name = NULL
        , @notify_page_operator_name = NULL
        , @delete_level = 0
        , @originating_server = N'(local)'
        , @job_id = @JobID OUTPUT;

    EXEC msdb.dbo.sp_add_jobstep @job_id = @JobID
        , @step_id = 1
        , @step_name = N'Gather Deadlocks'
        , @subsystem = N'TSQL'
        , @command = 'EXEC dbo.GatherDeadlockEvents;'
        , @on_success_action = 1
        , @on_fail_action = 2
        , @database_name = N'd_maintenance_hmg'
        , @database_user_name = NULL;

    EXEC msdb.dbo.sp_add_schedule @schedule_name = N'DBA : Gather Deadlock Events Schedule'
        , @enabled = 1
        , @freq_type = 4 --daily
        , @freq_interval = 1 --every day
        , @freq_subday_type = 0x04 -- every @freq_subday_interval minutes
        , @freq_subday_interval = 5
        , @owner_login_name = N'sa'
        , @schedule_id = @ScheduleID OUTPUT
        , @originating_server = N'(local)';

    EXEC msdb.dbo.sp_attach_schedule @job_id = @JobID
        , @schedule_id = @ScheduleID;

    EXEC msdb.dbo.sp_add_jobserver @job_name = N'DBA : Gather Deadlock Events', @server_name = N'(local)';
END
GO


/**
 * Código de Análise de Amostra
 * O código de exemplo a seguir apresenta detalhes sobre as ações envolvidas em eventos de deadlock.
 **/
/*
    Deadlock Analysis Samples
*/
USE d_maintenance_hmg;
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;
SET @StartTime = DATEADD(HOUR, -4, GETDATE()); --modify these to suit your needs
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

SELECT StartTime = CONVERT(varchar(30), @StartTime, 127), EndTime = CONVERT(varchar(30), @EndTime, 127)

SELECT [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [1_code] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[1]/executionStack/frame/text())[1]', 'nvarchar(4000)')
    , [1_input_buffer] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[1]/inputbuf/text())[1]', 'nvarchar(4000)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [2_code] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[2]/executionStack/frame/text())[1]', 'nvarchar(4000)')
    , [2_input_buffer] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[2]/inputbuf/text())[1]', 'nvarchar(4000)')
FROM #xmlResults x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1;

;WITH src AS
(    
SELECT [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [1_code] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[1]/executionStack/frame/text())[1]', 'nvarchar(4000)')
    , [1_input_buffer] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[1]/inputbuf/text())[1]', 'nvarchar(4000)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [2_code] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[2]/executionStack/frame/text())[1]', 'nvarchar(4000)')
    , [2_input_buffer] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[2]/inputbuf/text())[1]', 'nvarchar(4000)')
FROM #xmlResults x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT src.[1]
    , src.[1_code]
    , src.[1_input_buffer]
    , src.[2]
    , src.[2_code]
    , src.[2_input_buffer]
    , [Number of Deadlocks] = COUNT(1)
FROM src
GROUP BY src.[1]
    , src.[2]
    , src.[1_code]
    , src.[2_code]
    , src.[1_input_buffer]
    , src.[2_input_buffer];

;WITH src AS
(    
SELECT EventDate = DATEADD(HOUR, 0 - @Offset, CONVERT(datetime, x.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset')))
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [1_code] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[1]/executionStack/frame/text())[1]', 'nvarchar(4000)')
    , [1_input_buffer] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[1]/inputbuf/text())[1]', 'nvarchar(4000)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [2_code] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[2]/executionStack/frame/text())[1]', 'nvarchar(4000)')
    , [2_input_buffer] = x.xeXML.value('(/event/data/value/deadlock/process-list/process[2]/inputbuf/text())[1]', 'nvarchar(4000)')
FROM #xmlResults x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT src.EventDate
    , src.[1]
    , src.[1_code]
    , src.[1_input_buffer]
    , src.[2]
    , src.[2_code]
    , src.[2_input_buffer]
FROM src
ORDER BY src.EventDate DESC;



;WITH src AS
(
SELECT dt = x.xeXML.value('(/event/@timestamp)[1]', 'datetime')
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [3] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[3]', 'nvarchar(128)')
    , [4] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[4]', 'nvarchar(128)')
    , [5] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[5]', 'nvarchar(128)')
    , [6] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[6]', 'nvarchar(128)')
    , [7] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[7]', 'nvarchar(128)')
    , [8] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[8]', 'nvarchar(128)')
    , [9] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[9]', 'nvarchar(128)')
    , [10] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[10]', 'nvarchar(128)')
    , [11] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[11]', 'nvarchar(128)')
    , [12] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[12]', 'nvarchar(128)')
    , [13] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[13]', 'nvarchar(128)')
    , [14] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[14]', 'nvarchar(128)')
    , [15] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[15]', 'nvarchar(128)')
    , [16] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[16]', 'nvarchar(128)')
    , [17] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[17]', 'nvarchar(128)')
    , [18] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[18]', 'nvarchar(128)')
    , [19] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[19]', 'nvarchar(128)')
    , [20] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[20]', 'nvarchar(128)')
FROM dbo.deadlock_xml_events x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT ProcName = t.x
    , [Count] = COUNT(1)
FROM (
SELECT *
FROM src
UNPIVOT
([x] FOR [ProcName] IN (
      [1] 
    , [2] 
    , [3] 
    , [4] 
    , [5] 
    , [6] 
    , [7] 
    , [8] 
    , [9] 
    , [10]
    , [11]
    , [12]
    , [13]
    , [14]
    , [15]
    , [16]
    , [17]
    , [18]
    , [19]
    , [20]
    )) upvt
) t
GROUP BY t.x

;WITH src AS
(
SELECT dt = x.xeXML.value('(/event/@timestamp)[1]', 'datetime')
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [3] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[3]', 'nvarchar(128)')
    , [4] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[4]', 'nvarchar(128)')
    , [5] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[5]', 'nvarchar(128)')
    , [6] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[6]', 'nvarchar(128)')
    , [7] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[7]', 'nvarchar(128)')
    , [8] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[8]', 'nvarchar(128)')
    , [9] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[9]', 'nvarchar(128)')
    , [10] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[10]', 'nvarchar(128)')
    , [11] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[11]', 'nvarchar(128)')
    , [12] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[12]', 'nvarchar(128)')
    , [13] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[13]', 'nvarchar(128)')
    , [14] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[14]', 'nvarchar(128)')
    , [15] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[15]', 'nvarchar(128)')
    , [16] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[16]', 'nvarchar(128)')
    , [17] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[17]', 'nvarchar(128)')
    , [18] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[18]', 'nvarchar(128)')
    , [19] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[19]', 'nvarchar(128)')
    , [20] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[20]', 'nvarchar(128)')
FROM dbo.deadlock_xml_events x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT *
FROM src
UNPIVOT
([x] FOR [ProcName] IN (
      [1] 
    , [2] 
    , [3] 
    , [4] 
    , [5] 
    , [6] 
    , [7] 
    , [8] 
    , [9] 
    , [10]
    , [11]
    , [12]
    , [13]
    , [14]
    , [15]
    , [16]
    , [17]
    , [18]
    , [19]
    , [20]
    )) upvt


/*
 * O código de análise de amostra acima mostra os nomes de procedimentos e códigos envolvidos em eventos de deadlock salvos na dbo.deadlock_xml_eventstabela.
 **/

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Testes 
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE d_maintenance_hmg;
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;
SET @StartTime = DATEADD(HOUR, -3, GETDATE()); --modify these to suit your needs
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

SELECT StartTime = CONVERT(varchar(30), @StartTime, 127), EndTime = CONVERT(varchar(30), @EndTime, 127)


;WITH src AS
(
SELECT dt = x.xeXML.value('(/event/@timestamp)[1]', 'datetime')
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [3] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[3]', 'nvarchar(128)')
    , [4] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[4]', 'nvarchar(128)')
    , [5] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[5]', 'nvarchar(128)')
    , [6] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[6]', 'nvarchar(128)')
    , [7] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[7]', 'nvarchar(128)')
    , [8] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[8]', 'nvarchar(128)')
    , [9] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[9]', 'nvarchar(128)')
    , [10] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[10]', 'nvarchar(128)')
    , [11] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[11]', 'nvarchar(128)')
    , [12] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[12]', 'nvarchar(128)')
    , [13] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[13]', 'nvarchar(128)')
    , [14] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[14]', 'nvarchar(128)')
    , [15] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[15]', 'nvarchar(128)')
    , [16] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[16]', 'nvarchar(128)')
    , [17] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[17]', 'nvarchar(128)')
    , [18] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[18]', 'nvarchar(128)')
    , [19] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[19]', 'nvarchar(128)')
    , [20] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[20]', 'nvarchar(128)')
FROM dbo.deadlock_xml_events x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
   -- AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
   -- AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT ProcName = t.x
    , [Count] = COUNT(1)
FROM (
SELECT *
FROM src
UNPIVOT
([x] FOR [ProcName] IN (
      [1] 
    , [2] 
    , [3] 
    , [4] 
    , [5] 
    , [6] 
    , [7] 
    , [8] 
    , [9] 
    , [10]
    , [11]
    , [12]
    , [13]
    , [14]
    , [15]
    , [16]
    , [17]
    , [18]
    , [19]
    , [20]
    )) upvt
) t
GROUP BY t.x

;WITH src AS
(
SELECT dt = x.xeXML.value('(/event/@timestamp)[1]', 'datetime')
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [3] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[3]', 'nvarchar(128)')
    , [4] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[4]', 'nvarchar(128)')
    , [5] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[5]', 'nvarchar(128)')
    , [6] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[6]', 'nvarchar(128)')
    , [7] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[7]', 'nvarchar(128)')
    , [8] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[8]', 'nvarchar(128)')
    , [9] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[9]', 'nvarchar(128)')
    , [10] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[10]', 'nvarchar(128)')
    , [11] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[11]', 'nvarchar(128)')
    , [12] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[12]', 'nvarchar(128)')
    , [13] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[13]', 'nvarchar(128)')
    , [14] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[14]', 'nvarchar(128)')
    , [15] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[15]', 'nvarchar(128)')
    , [16] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[16]', 'nvarchar(128)')
    , [17] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[17]', 'nvarchar(128)')
    , [18] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[18]', 'nvarchar(128)')
    , [19] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[19]', 'nvarchar(128)')
    , [20] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[20]', 'nvarchar(128)')
FROM dbo.deadlock_xml_events x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
   -- AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
   -- AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT *
FROM src
UNPIVOT
([x] FOR [ProcName] IN (
      [1] 
    , [2] 
    , [3] 
    , [4] 
    , [5] 
    , [6] 
    , [7] 
    , [8] 
    , [9] 
    , [10]
    , [11]
    , [12]
    , [13]
    , [14]
    , [15]
    , [16]
    , [17]
    , [18]
    , [19]
    , [20]
    )) upvt





