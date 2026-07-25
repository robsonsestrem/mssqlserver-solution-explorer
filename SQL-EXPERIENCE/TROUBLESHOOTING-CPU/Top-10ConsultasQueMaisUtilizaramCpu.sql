/*
    OBJETIVO: Identificar as top 100 consultas com maior consumo de CPU,
              exibindo métricas de tempo de trabalho, leituras lógicas,
              tempo decorrido e o plano de execução associado.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- TOP 100 Consultas que Mais Utilizaram CPU
-- ============================================================
SELECT TOP 100
    SUBSTRING
    (
        ST.text,
        (QS.statement_start_offset / 2) + 1,
        (
            (CASE QS.statement_end_offset
                WHEN -1
                THEN DATALENGTH(ST.text)
                ELSE QS.statement_end_offset
            END - QS.statement_start_offset) / 2
        ) + 1
    )                                                                          AS statement_text
  , QS.execution_count
  , QS.total_worker_time / 1000                                                AS total_worker_time_ms
  , (QS.total_worker_time / 1000) / QS.execution_count                         AS avg_worker_time_ms
  , QS.total_logical_reads
  , QS.total_logical_reads / QS.execution_count                                AS avg_logical_reads
  , QS.total_elapsed_time / 1000                                               AS total_elapsed_time_ms
  , (QS.total_elapsed_time / 1000) / QS.execution_count                        AS avg_elapsed_time_ms
  , qp.query_plan
FROM
    sys.dm_exec_query_stats AS QS
    CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
    CROSS APPLY sys.dm_exec_query_plan(QS.plan_handle) AS qp
ORDER BY
    QS.total_worker_time DESC;
