-----------------------------------------------------------------------------------------------------------------------------------
-- COLETA BLOQUEIOS E MOSTRA CADEIA DELES COM O CAUSADOR PRINCIPAL
-- REFERÊNCIAS
-- https://github.com/mjswart-d2l/sqlblockedprocesses
-- https://www.brentozar.com/archive/2014/03/extended-events-doesnt-hard/
-- https://michaeljswart.com/tag/blocked-process-report/
-----------------------------------------------------------------------------------------------------------------------------------
-- Cria a sessão de eventos
CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'/var/opt/mssql/log_jobs/xe/blocked_process*.xel',
     metadatafile = N'/var/opt/mssql/log_jobs/xe/blocked_process*.xem',
     max_file_size=(500),
     max_rollover_files=5)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO

-- MINHA VERSÃO
CREATE EVENT SESSION [blocked_process] ON SERVER 
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text)
    WHERE ([database_id]=(5))),
ADD EVENT sqlserver.xml_deadlock_report(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.plan_handle,sqlserver.session_id,sqlserver.session_server_principal_name,sqlserver.sql_text)
    WHERE ([sqlserver].[database_id]=(5)))
ADD TARGET package0.event_file(SET filename=N'/var/opt/mssql/log_jobs/xe/blocked_process*.xel',max_file_size=(500),max_rollover_files=(5),metadatafile=N'/var/opt/mssql/log_jobs/xe/blocked_process*.xem')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=5 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


-----------------------------------------------------------------------------------------------------------------------------------
-- Visão simples dos dados
-----------------------------------------------------------------------------------------------------------------------------------
WITH events_cte AS (
  SELECT
    xevents.event_data,
    DATEADD(mi,
    DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
    xevents.event_data.value(
      '(event/@timestamp)[1]', 'datetime2')) AS [event time] ,
    xevents.event_data.value(
      '(event/action[@name=client_app_name]/value)[1]', 'nvarchar(128)')
      AS [client app name],
    xevents.event_data.value(
      '(event/action[@name=client_hostname]/value)[1]', 'nvarchar(max)')
      AS [client host name],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=database_name]/value)[1]', 'nvarchar(max)')
      AS [database name],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=database_id]/value)[1]', 'int')
      AS [database_id],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=object_id]/value)[1]', 'int')
      AS [object_id],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=index_id]/value)[1]', 'int')
      AS [index_id],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=duration]/value)[1]', 'bigint') / 1000
      AS [duration (ms)],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=lock_mode]/text)[1]', 'varchar')
      AS [lock_mode],
    xevents.event_data.value(
      '(event[@name=blocked_process_report]/data[@name=login_sid]/value)[1]', 'int')
      AS [login_sid],
    xevents.event_data.query(
      '(event[@name=blocked_process_report]/data[@name=blocked_process]/value/blocked-process-report)[1]')
      AS blocked_process_report,
    xevents.event_data.query(
      '(event/data[@name=xml_report]/value/deadlock)[1]')
      AS deadlock_graph
  FROM    sys.fn_xe_file_target_read_file
    ('E:\DATABASES_SQL\TRACES\blocked_process*.xel',
     'E:\DATABASES_SQL\TRACES\blocked_process*.xem',
     null, null)
    CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
SELECT
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN 'Deadlock'
       ELSE 'Blocked Process'
       END AS ReportType,
  [event time],
  CASE [client app name] WHEN '' THEN ' -- N/A -- '
                         ELSE [client app name]
                         END AS [client app _name],
  CASE [client host name] WHEN '' THEN ' -- N/A -- '
                          ELSE [client host name]
                          END AS [client host name],
  [database name],
  COALESCE(OBJECT_SCHEMA_NAME(object_id, database_id), ' -- N/A -- ') AS [schema],
  COALESCE(OBJECT_NAME(object_id, database_id), ' -- N/A -- ') AS [table],
  index_id,
  [duration (ms)],
  lock_mode,
  COALESCE(SUSER_NAME(login_sid), ' -- N/A -- ') AS username,
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN deadlock_graph
       ELSE blocked_process_report
       END AS Report
FROM events_cte
ORDER BY [event time] DESC ;


-----------------------------------------------------------------------------------------------------------------------------------
-- Cria a tabela com os xml de locks
-----------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE bpr (
    EndTime DATETIME,
    TextData XML,
    EventClass INT DEFAULT(137)
);
GO


-----------------------------------------------------------------------------------------------------------------------------------
-- Faz uma inserção dos dados coletados na tabela
-- Depois da pra automatizar o incremento dos dados
-----------------------------------------------------------------------------------------------------------------------------------
WITH events_cte AS (
    SELECT
        DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP),
        xevents.event_data.value('(event/@timestamp)[1]',
           'datetime2')) AS [event_time] ,
        xevents.event_data.query('(event[@name=blocked_process_report]/data[@name=blocked_process]/value/blocked-process-report)[1]')
            AS blocked_process_report
    FROM    sys.fn_xe_file_target_read_file
        ('E:\DATABASES_SQL\TRACES\blocked_process*.xel',
         'E:\DATABASES_SQL\TRACES\blocked_process*.xem',
         null, null)
        CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)

INSERT INTO bpr (EndTime, TextData)
SELECT
    [event_time],
    blocked_process_report
FROM events_cte
WHERE blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NOT NULL
ORDER BY [event_time] DESC ;


-----------------------------------------------------------------------------------------------------------------------------------
-- VISUALIZA A CADEIA DE BLOQUEIOS
-----------------------------------------------------------------------------------------------------------------------------------
-- A tabela tem que ter pelo menos essas 3 colunas
-- EndTime
-- TextData
-- EventClass
EXEC d_maintenance_hmg.dbo.sp_blocked_process_report_viewer 'bpr', 'TABLE';








