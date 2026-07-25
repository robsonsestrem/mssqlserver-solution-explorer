/*
    OBJETIVO: Identificar as top 100 procedures com maior consumo total de I/O,
              destacando principalmente procedures operacionais que acumulam
              maior impacto ao longo do tempo no servidor.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Top Procedures Memory Consumption Total
-- (This will show more operational procedures)
-- ============================================================

SELECT TOP 100
    *
FROM
    (
        SELECT
            DatabaseName                    = DB_NAME(qt.dbid)
          , ObjectName                      = OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
          , DiskReads                       = SUM(qs.total_physical_reads)
          , MemoryReads                     = SUM(qs.total_logical_reads)
          , Total_IO_Reads                  = SUM(qs.total_physical_reads + qs.total_logical_reads)
          , Executions                      = SUM(qs.execution_count)
          , IO_Per_Execution                = SUM((qs.total_physical_reads + qs.total_logical_reads) / qs.execution_count)
          , CPUTime                         = SUM(qs.total_worker_time)
          , DiskWaitAndCPUTime              = SUM(qs.total_elapsed_time)
          , MemoryWrites                    = SUM(qs.max_logical_writes)
          , DateLastExecuted                = MAX(qs.last_execution_time)
        FROM
            sys.dm_exec_query_stats AS qs
            CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
        GROUP BY
            DB_NAME(qt.dbid)
          , OBJECT_SCHEMA_NAME(qt.objectid, dbid) + '.' + OBJECT_NAME(qt.objectid, qt.dbid)
    ) AS T
ORDER BY
    Total_IO_Reads DESC;
