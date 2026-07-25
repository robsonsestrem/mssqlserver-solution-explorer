/*
    OBJETIVO: Consultar diagnósticos de concessão de memória (memory grant) combinando dados de sessões, 
              requisições e semáforos de recursos para identificação de gargalos de desempenho.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://github.com/MicrosoftDocs/SupportArticles-docs/blob/main/support/sql/database-engine/performance/troubleshoot-memory-grant-issues.md
*/

-- Seleção de métricas de concessão de memória, estatísticas do servidor e detalhes da sessão
SELECT 
    CONVERT(VARCHAR(30), GETDATE(), 121) AS runtime
    , r.session_id
    , r.wait_time
    , r.wait_type
    , mg.request_time
    , mg.grant_time
    , mg.requested_memory_kb / 1024 AS requested_memory_mb
    , mg.granted_memory_kb / 1024 AS granted_memory_mb
    , mg.required_memory_kb / 1024 AS required_memory_mb
    , mg.max_used_memory_kb / 1024 AS max_used_memory_mb
    , rs.pool_id AS resource_pool_id
    , mg.query_cost
    , mg.timeout_sec
    , mg.resource_semaphore_id
    , mg.wait_time_ms AS memory_grant_wait_time_ms
    , CASE mg.is_next_candidate
          WHEN 1 THEN 'Yes'
          WHEN 0 THEN 'No'
          ELSE 'Memory has been granted'
      END AS Next_Candidate_For_Memory_Grant
    , r.command
    , LTRIM(RTRIM(REPLACE(REPLACE(SUBSTRING(q.text, 1, 1000), CHAR(10), ' '), CHAR(13), ' '))) AS text
    , rs.target_memory_kb / 1024 AS server_target_grant_memory_mb
    , rs.max_target_memory_kb / 1024 AS server_max_target_grant_memory_mb
    , rs.total_memory_kb / 1024 AS server_total_resource_semaphore_memory_mb
    , rs.available_memory_kb / 1024 AS server_available_memory_for_grants_mb
    , rs.granted_memory_kb / 1024 AS server_total_granted_memory_mb
    , rs.used_memory_kb / 1024 AS server_used_granted_memory_mb
    , rs.grantee_count AS successful_grantee_count
    , rs.waiter_count AS grant_waiters_count
    , rs.timeout_error_count
    , rs.forced_grant_count
    , mg.dop
    , r.blocking_session_id
    , r.cpu_time
    , r.total_elapsed_time
    , r.reads
    , r.writes
    , r.logical_reads
    , r.row_count
    , s.login_time
    , d.name
    , s.login_name
    , s.host_name
    , s.nt_domain
    , s.nt_user_name
    , s.status
    , c.client_net_address
    , s.program_name
    , s.client_interface_name
    , s.last_request_start_time
    , s.last_request_end_time
    , c.connect_time
    , c.last_read
    , c.last_write
    , qp.query_plan
FROM sys.dm_exec_requests AS r
INNER JOIN sys.dm_exec_connections AS c
    ON r.connection_id = c.connection_id
INNER JOIN sys.dm_exec_sessions AS s
    ON c.session_id = s.session_id
INNER JOIN sys.databases AS d
    ON r.database_id = d.database_id
INNER JOIN sys.dm_exec_query_memory_grants AS mg
    ON s.session_id = mg.session_id
INNER JOIN sys.dm_exec_query_resource_semaphores AS rs
    ON mg.resource_semaphore_id = rs.resource_semaphore_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) AS q
CROSS APPLY sys.dm_exec_query_plan(mg.plan_handle) AS qp
OPTION (MAXDOP 1, LOOP JOIN);
