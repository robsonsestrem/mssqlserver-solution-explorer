USE YOUR_DATABASE
GO

create or alter procedure Management.sp_RequestsFull
with encryption
as
begin	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	BEGIN TRY 
		begin transaction 
		
			insert into Management.HistoryRequestsFull

			select
			RIGHT('00' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 86400 AS VARCHAR), 2) + ' ' + 
			RIGHT('00' + CAST((DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 3600) % 24 AS VARCHAR), 2) + ':' + 
			RIGHT('00' + CAST((DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 60) % 60 AS VARCHAR), 2) + ':' + 
			RIGHT('00' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) % 60 AS VARCHAR), 2) + '.' + 
			RIGHT('000' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) AS VARCHAR), 3) 
			AS Duration,
			A.session_id AS session_id,
			B.command,
			X.[text],
			A.login_name,
			'(' + CAST(B.wait_time AS VARCHAR(20)) + 'ms)' + COALESCE(B.wait_type, B.last_wait_type) + COALESCE((CASE 
				WHEN E.wait_type LIKE 'PAGEIOLATCH%' THEN ':' + DB_NAME(LEFT(E.resource_description, CHARINDEX(':', E.resource_description) - 1)) + ':' + SUBSTRING(E.resource_description, CHARINDEX(':', E.resource_description) + 1, 999)
				WHEN E.wait_type = 'OLEDB' THEN '[' + REPLACE(REPLACE(E.resource_description, ' (SPID=', ':'), ')', '') + ']'
				ELSE ''
			END), '') AS wait_info,

			FORMAT(COALESCE(B.cpu_time, 0), '###,###,###,###,###,###,###,##0') AS CPU,
			FORMAT(COALESCE(F.tempdb_allocations, 0), '###,###,###,###,###,###,###,##0') AS tempdb_allocations,
			FORMAT(COALESCE((CASE WHEN F.tempdb_allocations > F.tempdb_current THEN F.tempdb_allocations - F.tempdb_current ELSE 0 END), 0), '###,###,###,###,###,###,###,##0') AS tempdb_current,
			FORMAT(COALESCE(B.logical_reads, 0), '###,###,###,###,###,###,###,##0') AS reads,
			FORMAT(COALESCE(B.writes, 0), '###,###,###,###,###,###,###,##0') AS writes,
			FORMAT(COALESCE(B.reads, 0), '###,###,###,###,###,###,###,##0') AS physical_reads,
			FORMAT(COALESCE(B.granted_query_memory, 0), '###,###,###,###,###,###,###,##0') AS used_memory,
			NULLIF(B.blocking_session_id, 0) AS blocking_session_id,

			COALESCE(G.blocked_session_count, 0) AS blocked_session_count,
			(CASE 
				WHEN B.[deadlock_priority] <= -5 THEN 'Low'
				WHEN B.[deadlock_priority] > -5 AND B.[deadlock_priority] < 5 AND B.[deadlock_priority] < 5 THEN 'Normal'
				WHEN B.[deadlock_priority] >= 5 THEN 'High'
			END) + ' (' + CAST(B.[deadlock_priority] AS VARCHAR(3)) + ')' AS [deadlock_priority],
			B.row_count,
			COALESCE(A.open_transaction_count, 0) AS open_transaction_count,
			(CASE B.transaction_isolation_level
				WHEN 0 THEN 'Unspecified' 
				WHEN 1 THEN 'ReadUncommitted' 
				WHEN 2 THEN 'ReadCommitted' 
				WHEN 3 THEN 'Repeatable' 
				WHEN 4 THEN 'Serializable' 
				WHEN 5 THEN 'Snapshot'
			END) AS transaction_isolation_level,
			A.[status],
			NULLIF(B.percent_complete, 0) AS percent_complete,
			A.[host_name],
			COALESCE(DB_NAME(CAST(B.database_id AS VARCHAR)), 'master') AS [database_name],
			(CASE WHEN D.name IS NOT NULL THEN 'SQLAgent - TSQL Job (' + D.name + ')' ELSE A.[program_name] END) AS [program_name],
			COALESCE(B.start_time, A.last_request_end_time) AS start_time,
			A.login_time,
			COALESCE(B.request_id, 0) AS request_id,
			W.query_plan,
			getdate() as DateInsert
			
			FROM
			sys.dm_exec_sessions AS A WITH (NOLOCK)
			LEFT JOIN sys.dm_exec_requests AS B WITH (NOLOCK) ON A.session_id = B.session_id
			JOIN sys.dm_exec_connections AS C WITH (NOLOCK) ON A.session_id = C.session_id AND A.endpoint_id = C.endpoint_id
			LEFT JOIN msdb.dbo.sysjobs AS D ON RIGHT(D.job_id, 10) = RIGHT(SUBSTRING(A.[program_name], 30, 34), 10)
			LEFT JOIN (
				SELECT
					session_id, 
					wait_type, 
					MAX(resource_description) AS resource_description
				FROM 
					sys.dm_os_waiting_tasks
				WHERE
					resource_description IS NOT NULL
				GROUP BY 
					session_id, 
					wait_type
			) E ON A.session_id = E.session_id
			LEFT JOIN (
				SELECT
					session_id,
					request_id,
					SUM(internal_objects_alloc_page_count + user_objects_alloc_page_count) AS tempdb_allocations,
					SUM(internal_objects_dealloc_page_count + user_objects_dealloc_page_count) AS tempdb_current
				FROM
					sys.dm_db_task_space_usage
				GROUP BY
					session_id,
					request_id
			) F ON B.session_id = F.session_id AND B.request_id = F.request_id
			LEFT JOIN (
				SELECT 
					blocking_session_id,
					COUNT(*) AS blocked_session_count
				FROM 
					sys.dm_exec_requests
				WHERE 
					blocking_session_id != 0
				GROUP BY
					blocking_session_id
			) G ON A.session_id = G.blocking_session_id
			OUTER APPLY sys.dm_exec_sql_text(COALESCE(B.[sql_handle], C.most_recent_sql_handle)) AS X
			OUTER APPLY sys.dm_exec_query_plan(COALESCE(B.[sql_handle], C.most_recent_sql_handle)) AS W
			WHERE A.session_id <> @@SPID

	    commit transaction
	END TRY 

	BEGIN CATCH
			ROLLBACK TRANSACTION
			DECLARE @corpoFalha varchar(max)
				  , @subject VARCHAR(100)			-- assunto
				  , @recipients VARCHAR(100);		-- destinat�rio				
			SET @subject = 'Falha na execu��o de Procedure: '+@@SERVERNAME;
			SET @recipients = 'suporte@cravil.com.br';
			SET @corpoFalha = '	
				<html>
				<head>
				<meta http-equiv=Content-Type content=text/html; charset=windows-1252>
				</head>
				<body>
				<div align=left>'
			SELECT @corpoFalha = @corpoFalha + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_RequestsFull]:<b> <br>
				  </td>
				 </tr>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
					  <br> [ERROR NUMBER] - '+ cast(ERROR_NUMBER() as varchar(10)) + '
					  <br>				  
					  <br> [LINE] - '+ cast(ERROR_LINE() as varchar(10)) + '
					  <br>
					  <br> [MESSAGE] - '+  ERROR_MESSAGE() + '
				   </td>
				  </tr>
			</table>'

			SELECT @corpoFalha = @corpoFalha + 
				'</div>
				</body>
				</html>'

			EXEC [msdb].[dbo].[sp_send_dbmail]
					@recipients = @recipients,
					@subject = @subject,
					@profile_name = 'CRAVIL',
					@body = @corpoFalha,
					@body_format = 'HTML';

			END CATCH

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED 

end






