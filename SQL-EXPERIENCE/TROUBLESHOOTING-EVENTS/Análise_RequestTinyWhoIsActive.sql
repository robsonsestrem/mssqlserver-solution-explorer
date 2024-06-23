---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referências
-- https://www.dirceuresende.com/blog/sql-server-query-para-retornar-as-sessoes-ativas-sp_whoisactive-sem-consumir-tempdb/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Por diversas vezes, já tive problemas de lentidão ao executar a sp_WhoIsActive em ambientes com alto processamento e 
--contenção de disco e/ou TempDB, fazendo com que o retorno da SP demorasse vários segundos, até mesmo alguns minutos, 
--uma vez que essa SP tem muita utilização de TempDB para retornar os resultados da forma que ela retorna atualmente.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Qual a diferença para a sp_WhoIsActive?
-->Não utiliza a TempDB
-->Execução mais rápida
-->Código mais simples de entender
-->Pode ser facilmente utilizada como view, table-valued function ou scalar function, permitindo utilizar order by, select into, where, etc.
-->Além de mostrar a query em execução, mostra também o Outer Command (a sp_WhoIsActive também mostra se utilizado o parâmetro @get_outer_command = 1)
-->Caso a sessão seja de um job, mostra o nome do job na coluna program_name
-->Retorna o XML do plano de execução (a sp_WhoIsActive também mostra se utilizado o parâmetro @get_plans = 1)
-----------------------------------------------------------------------------------------------------------------------------------------------------
-- coluna status -> Status do ID do processo. Os valores possíveis são:
-----------------------------------------------------------------------------------------------------------------------------------------------------
 --dormant  (inativo) = SQL Server está redefinindo a sessão.

 --running (executando) = a sessão está executando um ou mais lotes. Quando são habilitados MARS (Vários Conjuntos de Resultados Ativos), uma sessão pode executar vários lotes. Para obter mais informações, consulte usando vários conjuntos de resultados ativos (. MARS &41;.

 --Background (plano de fundo) = a sessão está executando uma tarefa em segundo plano, como detecção de deadlock.

 --rollback (reversão) = a sessão tem uma reversão de transação em processo.

 --pending (pendente) = a sessão está aguardando um thread de trabalho se torne disponível.

 --runnable (executável) = a tarefa na sessão está na fila executável de um agendador enquanto aguarda para obter um quantum de tempo.

 --spinloop/sleeping = a tarefa na sessão está esperando um spinlock fique livre.

 --suspended (suspenso) = a sessão está aguardando um evento, como e/s, para concluir, em processo de retorno.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
select 
 cast(left(x.Duration, 2) as smallint) as dias
,cast(right(x.Duration, 12) as time) as Horas
,	*
from
(
	SELECT
		RIGHT('00' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 86400 AS VARCHAR), 2) + ' ' + 
		RIGHT('00' + CAST((DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 3600) % 24 AS VARCHAR), 2) + ':' + 
		RIGHT('00' + CAST((DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) / 60) % 60 AS VARCHAR), 2) + ':' + 
		RIGHT('00' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) % 60 AS VARCHAR), 2) + '.' + 
		RIGHT('000' + CAST(DATEDIFF(SECOND, COALESCE(B.start_time, A.login_time), GETDATE()) AS VARCHAR), 3) 
		AS Duration,
		A.session_id AS session_id,		
		A.login_name,
		A.[host_name],
		A.[status],
		COALESCE(A.open_transaction_count, 0) AS open_transaction_count,
		COALESCE(DB_NAME(CAST(B.database_id AS VARCHAR)), 'master') AS [database_name],
		(CASE WHEN D.name IS NOT NULL THEN 'SQLAgent - TSQL Job (' + D.name + ')' ELSE A.[program_name] END) AS [program_name],
		COALESCE(B.start_time, A.last_request_end_time) AS start_time,
		A.login_time,
		B.row_count,
	
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
		(CASE B.transaction_isolation_level
			WHEN 0 THEN 'Unspecified' 
			WHEN 1 THEN 'ReadUncommitted' 
			WHEN 2 THEN 'ReadCommitted' 
			WHEN 3 THEN 'Repeatable' 
			WHEN 4 THEN 'Serializable' 
			WHEN 5 THEN 'Snapshot'
		END) AS transaction_isolation_level,		
		NULLIF(B.percent_complete, 0) AS percent_complete,						
		COALESCE(B.request_id, 0) AS request_id,
		B.command,
		X.[text],
		W.query_plan
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
) as x
where x.session_id <> @@SPID
and x.session_id = 35
--AND x.login_name LIKE '%exec%'
--and x.open_transaction_count = 0
--and x.status <> 'sleeping'
--and x.database_name = 'guru'

--order by 1 desc, 2 desc

order by 15 desc	-- cpu


