/*
    OBJETIVO: Analisar conexões ativas no SQL Server por IP, programa,
              host e login, além de identificar os principais tipos de
              espera (waits) que estão impactando o desempenho do servidor.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://social.msdn.microsoft.com/Forums/sqlserver/en-US/fb4141b7-1081-4a00-b641-e8c9ee30a5af/question-regarding-batch-requests-sec?forum=sqldatabaseengine
*/

-- ============================================================
-- Contagem de conexões SQL por endereço IP
-- ============================================================

SELECT
    ec.client_net_address
  , es.program_name
  , es.host_name
  , es.login_name
  , COUNT(ec.session_id)                                                      AS [connection count]
FROM
    sys.dm_exec_sessions AS es
    INNER JOIN sys.dm_exec_connections AS ec
        ON es.session_id = ec.session_id
GROUP BY
    ec.client_net_address
  , es.program_name
  , es.host_name
  , es.login_name
ORDER BY
    COUNT(ec.session_id) DESC;  -- ec.client_net_address, es.program_name;


-- ============================================================
-- Contagem de conexões SQL por login_name
-- ============================================================

SELECT
    login_name
  , COUNT(session_id)                                                         AS [session_count]
FROM
    sys.dm_exec_sessions
GROUP BY
    login_name
ORDER BY
    COUNT(session_id) DESC;  -- login_name;


-- ============================================================
-- Isolar os principais waits do servidor desde o último restart
-- ou limpeza das estatísticas
-- ============================================================

;WITH Waits AS
(
    SELECT
        wait_type
      , wait_time_ms / 1000.                                                   AS wait_time_s
      , 100. * wait_time_ms / SUM(wait_time_ms) OVER()                         AS pct
      , ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC)                          AS rn
    FROM
        sys.dm_os_wait_stats
    WHERE
        wait_type NOT IN
        (
            'CLR_SEMAPHORE',
            'LAZYWRITER_SLEEP',
            'RESOURCE_QUEUE',
            'SLEEP_TASK',
            'SLEEP_SYSTEMTASK',
            'SQLTRACE_BUFFER_FLUSH',
            'WAITFOR',
            'LOGMGR_QUEUE',
            'CHECKPOINT_QUEUE',
            'REQUEST_FOR_DEADLOCK_SEARCH',
            'XE_TIMER_EVENT',
            'BROKER_TO_FLUSH',
            'BROKER_TASK_STOP',
            'CLR_MANUAL_EVENT',
            'CLR_AUTO_EVENT',
            'DISPATCHER_QUEUE_SEMAPHORE',
            'FT_IFTS_SCHEDULER_IDLE_WAIT',
            'XE_DISPATCHER_WAIT',
            'XE_DISPATCHER_JOIN'
        )
)
SELECT
    W1.wait_type
  , CAST(W1.wait_time_s AS DECIMAL(12, 2))                                     AS wait_time_s
  , CAST(W1.pct AS DECIMAL(12, 2))                                             AS pct
  , CAST(SUM(W2.pct) AS DECIMAL(12, 2))                                        AS running_pct
FROM
    Waits AS W1
    INNER JOIN Waits AS W2
        ON W2.rn <= W1.rn
GROUP BY
    W1.rn
  , W1.wait_type
  , W1.wait_time_s
  , W1.pct
HAVING
    SUM(W2.pct) - W1.pct < 95;  -- percentage threshold

