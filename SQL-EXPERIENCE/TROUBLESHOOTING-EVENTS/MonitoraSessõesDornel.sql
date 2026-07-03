-------------------------------------------------------------------------------------------------------------------
-- Análise de sessão realizada por Dornel
-------------------------------------------------------------------------------------------------------------------
   -- DECLARE @databaseId int = DB_ID(); --(SELECT database_id FROM sys.databases WHERE name = @database)

	-- Executing Requests
    SELECT r1.session_id                                            AS SessionId,	
		(r1.total_elapsed_time / 1000)                                  AS [TotalElapsedTime (s)], 
		s1.host_name                                                    AS HostName, 
		s1.program_name                                                 AS ProgramName, 
		r1.command                                                      AS Command, 
		--OBJECT_NAME(object_id1, @databaseId)                            AS [Background task on...],
		CASE 
		  WHEN r1.transaction_isolation_level = 0 THEN 'Unspecified' 
		  WHEN r1.transaction_isolation_level = 1 THEN 'ReadUncomitted'
		  WHEN r1.transaction_isolation_level = 2 THEN 'ReadCommitted'
		  WHEN r1.transaction_isolation_level = 3 THEN 'Repeatable'
		  WHEN r1.transaction_isolation_level = 4 THEN 'Serializable'
		  WHEN r1.transaction_isolation_level = 5 THEN 'Snapshot'
		END                                                             AS IsolationLevel,
		--(r1.wait_time / 1000) AS [WaitTime (s)], 
		--r1.wait_type AS WaitType, 
		r1.last_wait_type                                               AS LastWaitTipe,
		r1.reads                                                        AS Reads, 
		r1.logical_reads                                                AS LogicalReads, 
		r1.writes                                                       AS Writes, 
		(r1.cpu_time / 1000)                                            AS [CpuTime (s)], 
		r1.open_transaction_count,
		OBJECT_SCHEMA_NAME(sq1.objectid) + '.' + OBJECT_NAME(sq1.objectid, sq1.dbid) AS ObjectName,	
		SUBSTRING(sq1.text,(r1.statement_start_offset/2) + 1,
		 ((CASE r1.statement_end_offset
			 WHEN -1 THEN DATALENGTH(sq1.text)
			 ELSE r1.statement_end_offset END
				 - r1.statement_start_offset)/2) + 1)                                    AS QueryText,
		r2.session_id                                                                AS BlockingSessionId, 
		s2.host_name                                                                 AS HostName_S2, 
		s2.program_name                                                              AS ProgramName_S2, 
		r2.command                                                                   AS Command_S2, 
		CASE 
		  WHEN r2.transaction_isolation_level = 0 THEN 'Unspecified' 
		  WHEN r2.transaction_isolation_level = 1 THEN 'ReadUncomitted'
		  WHEN r2.transaction_isolation_level = 2 THEN 'ReadCommitted'
		  WHEN r2.transaction_isolation_level = 3 THEN 'Repeatable'
		  WHEN r2.transaction_isolation_level = 4 THEN 'Serializable'
		  WHEN r2.transaction_isolation_level = 5 THEN 'Snapshot'
		END                                                                          AS IsolationLevel_S2,
		SUBSTRING(sq2.text, (r2.statement_start_offset/2)+1, 
			((CASE r2.statement_end_offset
			  WHEN -1 THEN DATALENGTH(sq2.text)
			 ELSE r2.statement_end_offset
			 END - r2.statement_start_offset)/2) + 1)                                  AS QueryText_S2,
		r2.session_id                                                                AS BlockingSessionId_S2
		--'------------',				
		--r1.*
	FROM sys.dm_exec_requests r1
	INNER JOIN sys.dm_exec_sessions s1 ON r1.session_id = s1.session_id
	LEFT OUTER JOIN sys.dm_exec_requests r2 ON r1.blocking_session_id = r2.session_id
	OUTER APPLY sys.dm_exec_sql_text(r1.sql_handle) sq1
	LEFT OUTER JOIN sys.dm_exec_sessions s2 ON r2.session_id = s2.session_id
	OUTER APPLY sys.dm_exec_sql_text(r2.sql_handle) sq2
	LEFT OUTER JOIN sys.dm_exec_background_job_queue jq on jq.session_id = r1.session_id
	--WHERE r1.sql_handle IS NOT NULL
	WHERE 1 = 1 
	--AND r1.database_id = @databaseId
	AND r1.command != 'DB MIRROR'
	AND r1.command != 'WAITFOR'
	--and s1.program_name like 'QComm%'
	--AND s1.host_name = 'ST24'
	--AND s1.host_name != 'CORVETTE'
  AND r1.session_id <> @@spid
	ORDER BY r1.total_elapsed_time DESC, r1.session_id DESC


	
	-- Open transactions
--	SELECT tr.session_id AS SessionId,tr.elapsed_time_seconds AS [TotalElapsedTime (s)],sess.host_name,sess.program_name,sq.text
--	FROM sys.dm_tran_active_snapshot_database_transactions tr
--	inner join sys.dm_exec_sessions sess on sess.session_id = tr.session_id
--	inner join sys.sysprocesses pr on pr.spid = tr.session_id
--	cross apply sys.dm_exec_sql_text(pr.sql_handle) sq
--	ORDER BY elapsed_time_seconds DESC;

