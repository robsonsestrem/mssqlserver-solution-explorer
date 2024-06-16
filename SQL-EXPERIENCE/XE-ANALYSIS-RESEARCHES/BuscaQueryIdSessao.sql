------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cria XE filtrada para uma sessão afim de coletar o que está rodando de query
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT SESSION [RunningQuery] ON SERVER 
ADD EVENT sqlos.wait_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57))),
ADD EVENT sqlserver.cursor_close(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57))),
ADD EVENT sqlserver.cursor_open(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57))),
ADD EVENT sqlserver.rpc_completed(SET collect_statement=(1)
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57))),
ADD EVENT sqlserver.sp_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57))),
ADD EVENT sqlserver.sql_batch_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57))),
ADD EVENT sqlserver.sql_statement_completed(
    ACTION(sqlserver.client_app_name,sqlserver.client_hostname,sqlserver.database_name,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.username)
    WHERE ([sqlserver].[session_id]=(57)))
ADD TARGET package0.ring_buffer
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Consulta XE completa
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#capture_waits_data') IS NOT NULL
DROP TABLE #capture_waits_data

SELECT CAST(target_data as xml) AS targetdata
INTO #capture_waits_data
FROM sys.dm_xe_session_targets xet
JOIN sys.dm_xe_sessions xes
ON xes.address = xet.event_session_address
WHERE xes.name = 'RunningQuery'
AND xet.target_name = 'ring_buffer';

select * from #capture_waits_data

SELECT --xed.event_data.value('(@timestamp)[1]', 'datetime2') AS datetime_utc,
xed.event_data.value('(action[@name=session_id]/value)[1]', 'varchar(255)') AS session_id,
DATEADD(hh, DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), xed.event_data.value('(@timestamp)[1]', 'datetime2')) AS [timestamp],
CAST( xed.event_data.value('(data[@name=duration]/value)[1]', 'bigint') / 1000 as DECIMAL(28,2)) AS duration_ms,
xed.event_data.value('(@name)[1]', 'varchar(50)') AS event_type,
xed.event_data.value('(data[@name=statement]/value)[1]', 'varchar(1000)') AS statement,
xed.event_data.value('(action[@name=sql_text]/value)[1]', 'varchar(max)') AS sql_text,
xed.event_data.value('(action[@name=query_hash]/value)[1]', 'varchar(255)') AS query_hash,
xed.event_data.value('(data[@name=object_name]/value)[1]', 'varchar(50)') AS [object_name],
xed.event_data.value('(action[@name=database_name]/value)[1]', 'varchar(255)') AS database_name,
xed.event_data.value('(action[@name=client_hostname]/value)[1]', 'varchar(255)') AS client_hostname,
xed.event_data.value('(action[@name=client_app_name]/value)[1]', 'varchar(255)') AS client_app_name,
xed.event_data.value('(action[@name=username]/value)[1]', 'varchar(255)') AS username
FROM #capture_waits_data
CROSS APPLY targetdata.nodes('//RingBufferTarget/event') AS xed (event_data)
