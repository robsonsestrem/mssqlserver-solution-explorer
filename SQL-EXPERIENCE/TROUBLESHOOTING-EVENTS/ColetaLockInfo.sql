/*
    OBJETIVO: Coleta de informações de bloqueios e esperas no SQL Server,
              identificando sessões bloqueadas, sessões bloqueadoras, tipos
              de espera, planos de execução e modos de lock envolvidos.
    PROJETO: mssqlserver-solution-explorer
*/

-- =====================================================================
-- Bloco 1: CTE [Blocking] com detalhes completos das sessões em espera
-- =====================================================================

-- CTE que consolida informações de sessões em espera, juntando
-- waiting_tasks, sessions, requests, SQL text e query plan
;WITH [Blocking]
AS
(
    SELECT
        w.[session_id]
        , s.[original_login_name]
        , s.[login_name]
        , w.[wait_duration_ms]
        , w.[wait_type]
        , r.[status]
        , r.[wait_resource]
        , w.[resource_description]
        , s.[program_name]
        , w.[blocking_session_id]
        , s.[host_name]
        , r.[command]
        , r.[percent_complete]
        , r.[cpu_time]
        , r.[total_elapsed_time]
        , r.[reads]
        , r.[writes]
        , r.[logical_reads]
        , r.[row_count]
        , q.[text]
        , q.[dbid]
        , p.[query_plan]
        , r.[plan_handle]
    FROM [sys].[dm_os_waiting_tasks] AS w
    INNER JOIN [sys].[dm_exec_sessions] AS s
        ON w.[session_id] = s.[session_id]
    INNER JOIN [sys].[dm_exec_requests] AS r
        ON s.[session_id] = r.[session_id]
    CROSS APPLY [sys].[dm_exec_sql_text](r.[plan_handle]) AS q
    CROSS APPLY [sys].[dm_exec_query_plan](r.[plan_handle]) AS p
    WHERE w.[session_id] > 50
        AND w.[wait_type] NOT IN ('DBMIRROR_DBM_EVENT', 'ASYNC_NETWORK_IO')
)

-- Query principal: cruza a CTE [Blocking] com sessões bloqueadoras
-- e locks ativos para identificar pares bloqueador/bloqueado
SELECT
    b.[session_id] AS [WaitingSessionID]
    , b.[blocking_session_id] AS [BlockingSessionID]
    , b.[login_name] AS [WaitingUserSessionLogin]
    , s1.[login_name] AS [BlockingUserSessionLogin]
    , CAST(b.[wait_duration_ms] / 1000.0 AS DECIMAL(28, 2)) AS [WaitDuration (s)]
    , b.[wait_type] AS [WaitType]
    , t.[request_mode] AS [WaitRequestMode]
    , UPPER(b.[status]) AS [WaitingProcessStatus]
    , UPPER(s1.[status]) AS [BlockingSessionStatus]
    , DB_NAME(t.[resource_database_id]) AS [WaitResourceDatabaseName]
    , b.[program_name] AS [WaitingSessionProgramName]
    , s1.[program_name] AS [BlockingSessionProgramName]
    , b.[host_name] AS [WaitingHost]
    , s1.[host_name] AS [BlockingHost]
    , b.[command] AS [WaitingCommandType]
    , b.[text] AS [WaitingCommandText]
    , b.[total_elapsed_time] AS [WaitingCommandTotalElapsedTime]
FROM [Blocking] AS b
INNER JOIN [sys].[dm_exec_sessions] AS s1
    ON b.[blocking_session_id] = s1.[session_id]
INNER JOIN [sys].[dm_tran_locks] AS t
    ON t.[request_session_id] = b.[session_id]
WHERE t.[request_status] != 'GRANT'
;


-- =====================================================================
-- Bloco 2: Top 20 sessões bloqueadas ordenadas por tempo de espera.
-- Top 20 bloqueios: pela ordenação, o primeiro Session_Id da lista
-- é o que mais está esperando, e na mesma linha mostra quem está
-- bloqueando. Na coluna "Blocking_Session_Id" é possível ver se o
-- mesmo spid está bloqueando outras sessões.
-- =====================================================================
SELECT TOP 20
    Session_Id AS Sessao_Bloqueada
    , Blocking_Session_Id AS Bloqueador
FROM sys.dm_exec_requests
WHERE Blocking_Session_Id > 0
ORDER BY
    Wait_Time DESC;
