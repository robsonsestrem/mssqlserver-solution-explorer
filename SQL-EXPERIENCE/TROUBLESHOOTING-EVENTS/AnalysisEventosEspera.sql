/*
    OBJETIVO: Analisar estatísticas de espera (wait statistics) do SQL Server,
              filtrando tipos de espera irrelevantes e apresentando métricas
              como tempo total, médio, percentual e URLs de referência para
              cada tipo de espera, auxiliando na identificação de gargalos.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
*/

-- ============================================================
-- Reseta as estatísticas (descomentar se necessário)
-- ============================================================
-- DBCC SQLPERF(sys.dm_os_wait_stats, CLEAR);
-- ============================================================

;WITH [Waits]
AS (
    SELECT
        [wait_type]                                                         -- Nome do tipo de espera
      , [wait_time_ms] / 1000.0                                             AS [WaitS]       -- Tempo de espera total (incluindo signal_wait_time_ms)
      , ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0                   AS [ResourceS]   -- Tempo de espera por recurso (excluindo sinalização)
      , [signal_wait_time_ms] / 1000.0                                      AS [SignalS]     -- Tempo de espera na fila de CPU
      , [waiting_tasks_count]                                               AS [WaitCount]   -- Número de esperas
      , 100.0 * [wait_time_ms] / SUM([wait_time_ms]) OVER()                 AS [Percentage]
      , ROW_NUMBER() OVER (ORDER BY [wait_time_ms] DESC)                    AS [RowNum]
    FROM
        sys.dm_os_wait_stats
    WHERE
        [wait_type] NOT IN
        (
            -- Tipos de espera que quase nunca são problemas e são filtrados
            N'BROKER_EVENTHANDLER',
            N'BROKER_RECEIVE_WAITFOR',
            N'BROKER_TO_FLUSH',
            N'CHECKPOINT_QUEUE',
            N'CHKPT',
            N'CXCONSUMER',
            N'DIRTY_PAGE_POLL',
            N'DISPATCHER_QUEUE_SEMAPHORE',
            N'EXECSYNC',
            N'FSAGENT',
            N'FT_IFTSHC_MUTEX',
            N'HADR_CLUSAPI_CALL',
            N'KSOURCE_WAKEUP',
            N'LOGMGR_QUEUE',
            N'MEMORY_ALLOCATION_EXT',
            N'ONDEMAND_TASK_QUEUE',
            N'PARALLEL_REDO_DRAIN_WORKER',
            N'PARALLEL_REDO_LOG_CACHE',
            N'PARALLEL_REDO_WORKER_SYNC',
            N'PARALLEL_REDO_WORKER_WAIT_WORK',
            N'PREEMPTIVE_XE_GETTARGETSTATE',
            N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
            N'QDS_ASYNC_QUEUE',
            N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
            N'QDS_SHUTDOWN_QUEUE',
            N'REQUEST_FOR_DEADLOCK_SEARCH',
            N'RESOURCE_QUEUE',
            N'SLEEP_BPOOL_FLUSH',
            N'SLEEP_DBSTARTUP',
            N'SLEEP_DCOMSTARTUP',
            N'SLEEP_MASTERDBREADY',
            N'SLEEP_MASTERMDREADY',
            N'SLEEP_MASTERUPGRADED',
            N'SLEEP_MSDBSTARTUP',
            N'SLEEP_SYSTEMTASK',
            N'SLEEP_TASK',
            N'SLEEP_TEMPDBSTARTUP',
            N'SP_SERVER_DIAGNOSTICS_SLEEP',
            N'WAIT_FOR_RESULTS',
            N'WAITFOR',
            N'XE_DISPATCHER_JOIN',
            N'XE_DISPATCHER_WAIT',
            N'XE_TIMER_EVENT'
        )
        AND [waiting_tasks_count] > 0
)

SELECT
    MAX(W1.wait_type)                                                       AS WaitType
  , CAST(MAX(W1.WaitS) AS DECIMAL(16, 2))                                   AS Wait_S
  , CAST(MAX(W1.ResourceS) AS DECIMAL(16, 2))                               AS Resource_S
  , CAST(MAX(W1.SignalS) AS DECIMAL(16, 2))                                 AS Signal_S
  , MAX(W1.WaitCount)                                                       AS WaitCount
  , CAST(MAX(W1.Percentage) AS DECIMAL(5, 2))                               AS Percentage
  , CAST((MAX(W1.WaitS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4))             AS AvgWait_S
  , CAST((MAX(W1.ResourceS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4))         AS AvgRes_S
  , CAST((MAX(W1.SignalS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4))           AS AvgSig_S
  , CAST('https://www.sqlskills.com/help/waits/' + MAX(W1.wait_type) AS XML) AS [Help/Info URL]
FROM
    Waits AS W1
    INNER JOIN Waits AS W2
        ON W2.RowNum <= W1.RowNum
GROUP BY
    W1.RowNum
HAVING
    SUM(W2.Percentage) - MAX(W1.Percentage) < 95; -- threshold de percentual


-- ============================================================
-- Versão para Job (monitoramento contínuo a cada hora)
-- ============================================================

/*
USE master;
GO

;WITH [Waits] AS
(
    SELECT
        [wait_type]
      , [wait_time_ms] / 1000.0                                             AS [WaitS]
      , ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0                   AS [ResourceS]
      , [signal_wait_time_ms] / 1000.0                                      AS [SignalS]    -- Tempo de espera na fila da CPU
      , [waiting_tasks_count]                                               AS [WaitCount]
      , 100.0 * [wait_time_ms] / SUM([wait_time_ms]) OVER()                 AS [Percentage]
      , ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC)                     AS [RowNum]
    FROM
        sys.dm_os_wait_stats
    WHERE
        [wait_type] NOT IN
        (
            N'BROKER_EVENTHANDLER',
            N'BROKER_RECEIVE_WAITFOR',
            N'BROKER_TASK_STOP',
            N'BROKER_TO_FLUSH',
            N'BROKER_TRANSMITTER',
            N'CHECKPOINT_QUEUE',
            N'CHKPT',
            N'CLR_AUTO_EVENT',
            N'CLR_MANUAL_EVENT',
            N'CLR_SEMAPHORE',
            N'DBMIRROR_DBM_EVENT',
            N'DBMIRROR_EVENTS_QUEUE',
            N'DBMIRROR_WORKER_QUEUE',
            N'DBMIRRORING_CMD',
            N'DIRTY_PAGE_POLL',
            N'DISPATCHER_QUEUE_SEMAPHORE',
            N'EXECSYNC',
            N'FSAGENT',
            N'FT_IFTS_SCHEDULER_IDLE_WAIT',
            N'FT_IFTSHC_MUTEX',
            N'HADR_CLUSAPI_CALL',
            N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
            N'HADR_LOGCAPTURE_WAIT',
            N'HADR_NOTIFICATION_DEQUEUE',
            N'HADR_TIMER_TASK',
            N'HADR_WORK_QUEUE',
            N'KSOURCE_WAKEUP',
            N'LAZYWRITER_SLEEP',
            N'LOGMGR_QUEUE',
            N'ONDEMAND_TASK_QUEUE',
            N'PWAIT_ALL_COMPONENTS_INITIALIZED',
            N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
            N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
            N'REQUEST_FOR_DEADLOCK_SEARCH',
            N'RESOURCE_QUEUE',
            N'SERVER_IDLE_CHECK',
            N'SLEEP_BPOOL_FLUSH',
            N'SLEEP_DBSTARTUP',
            N'SLEEP_DCOMSTARTUP',
            N'SLEEP_MASTERDBREADY',
            N'SLEEP_MASTERMDREADY',
            N'SLEEP_MASTERUPGRADED',
            N'SLEEP_MSDBSTARTUP',
            N'SLEEP_SYSTEMTASK',
            N'SLEEP_TASK',
            N'SLEEP_TEMPDBSTARTUP',
            N'SNI_HTTP_ACCEPT',
            N'SP_SERVER_DIAGNOSTICS_SLEEP',
            N'SQLTRACE_BUFFER_FLUSH',
            N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
            N'SQLTRACE_WAIT_ENTRIES',
            N'WAIT_FOR_RESULTS',
            N'WAITFOR',
            N'WAITFOR_TASKSHUTDOWN',
            N'WAIT_XTP_HOST_WAIT',
            N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
            N'WAIT_XTP_CKPT_CLOSE',
            N'XE_DISPATCHER_JOIN',
            N'XE_DISPATCHER_WAIT',
            N'XE_TIMER_EVENT',
            N'BACKUPBUFFER',
            N'BACKUPIO',
            N'REDO_THREAD_PENDING_WORK',
            N'PREEMPTIVE_SP_SERVER_DIAGNOSTICS',
            N'PREEMPTIVE_HADR_LEASE_MECHANISM'
        )
        AND [waiting_tasks_count] > 0
)
SELECT
    GETDATE()                                                               AS Dt_Log
  , MAX(W1.wait_type)                                                       AS WaitType
  , CAST(MAX(W1.WaitS) AS DECIMAL(16, 2))                                   AS Wait_S
  , CAST(MAX(W1.ResourceS) AS DECIMAL(16, 2))                               AS Resource_S
  , CAST(MAX(W1.SignalS) AS DECIMAL(16, 2))                                 AS Signal_S
  , MAX(W1.WaitCount)                                                       AS WaitCount
  , CAST(MAX(W1.Percentage) AS DECIMAL(5, 2))                               AS Percentage
  , CAST((MAX(W1.WaitS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4))             AS AvgWait_S
  , CAST((MAX(W1.ResourceS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4))         AS AvgRes_S
  , CAST((MAX(W1.SignalS) / MAX(W1.WaitCount)) AS DECIMAL(16, 4))           AS AvgSig_S
FROM
    Waits AS W1
    INNER JOIN Waits AS W2
        ON W2.RowNum <= W1.RowNum
GROUP BY
    W1.RowNum
HAVING
    SUM(W2.Percentage) - MAX(W1.Percentage) < 95; -- threshold de percentual
*/