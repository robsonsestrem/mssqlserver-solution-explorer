/*
    OBJETIVO: Identificar as top 100 consultas com maior volume agregado de operações
              de I/O (leituras e escritas lógicas), calculando médias por execução
              para auxiliar na análise de desempenho e otimização de queries.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- TOP 100 Consultas que Mais Realizaram Operações de I/O
-- ============================================================
SELECT TOP 100
    qs.creation_time
  , qs.last_execution_time
  , qs.total_logical_reads                                                     AS [LogicalReads]
  , qs.total_logical_writes                                                    AS [LogicalWrites]
  , qs.execution_count
  , qs.total_logical_reads + qs.total_logical_writes                           AS [AggIO]
  , (qs.total_logical_reads + qs.total_logical_writes) / (qs.execution_count + 0.0) AS [AvgIO]
  , st.TEXT
  , DB_NAME(st.dbid)                                                           AS database_name
  , st.objectid                                                                AS OBJECT_ID
FROM
    sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
WHERE
    qs.total_logical_reads + qs.total_logical_writes > 0
    AND qs.sql_handle IS NOT NULL
ORDER BY
    [AggIO] DESC;
