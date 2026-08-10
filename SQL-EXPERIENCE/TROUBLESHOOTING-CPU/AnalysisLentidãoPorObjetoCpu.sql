/*
    OBJETIVO: Analisar lentidão por objeto através de estatísticas de execução
              de consultas em cache, apresentando consumo de CPU, I/O e tempo
              decorrido com e sem formatação numérica, além de top consultas
              por tempo de CPU e contagem de linhas.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    http://www.davewentzel.com/content/useful-queries
    https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-stats-transact-sql
*/

-- ============================================================
-- Reset das estatísticas (descomentar se necessário)
-- ============================================================
-- DBCC SQLPERF(sys.dm_os_wait_stats, CLEAR);
-- ============================================================
-- Como os planos estão fora do cache, as estatísticas ficam obsoletas.
-- Isso é realmente apenas para planos ativos.
-- ============================================================

-- ============================================================
-- MÉDIA DE CONSUMO POR OBJETO (COM FORMATAÇÃO NUMÉRICA)
-- ============================================================
USE master;
GO

SELECT
    DB_NAME(st.dbid)                                                           AS DBName
  , OBJECT_SCHEMA_NAME(objectid, st.dbid)                                      AS SchemaName
  , st.objectid                                                                AS [Object_Id]
  , OBJECT_NAME(objectid, st.dbid)                                             AS [Object_Name]
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(SUM(qs.total_worker_time), 2)) AS Total_worker_time
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToMoney(SUM(qs.total_worker_time) / SUM(qs.execution_count))) AS Avg_worker_time
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(MAX(cp.usecounts), 2)) AS UseCounts
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(SUM(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes), 2)) AS Total_IO
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToMoney(SUM(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (MAX(cp.usecounts)))) AS Avg_total_IO
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(SUM(qs.total_physical_reads), 2)) AS Total_physical_reads
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToMoney(SUM(qs.total_physical_reads) / (MAX(cp.usecounts) * 1.0))) AS Avg_physical_read
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(SUM(qs.total_logical_reads), 2)) AS Total_logical_reads
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToMoney(SUM(qs.total_logical_reads) / (MAX(cp.usecounts) * 1.0))) AS Avg_logical_read
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(SUM(qs.total_logical_writes), 2)) AS Total_logical_writes
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToMoney(SUM(qs.total_logical_writes) / (MAX(cp.usecounts) * 1.0))) AS Avg_logical_writes
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToThousands(SUM(qs.total_elapsed_time), 2)) AS Total_elapsed_time
  , (SELECT YOUR_DATABASE.Management.fn_FormatIntToMoney(SUM(qs.total_elapsed_time) / MAX(cp.usecounts))) AS Avg_elapsed_time
FROM
    sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS st
    INNER JOIN sys.dm_exec_cached_plans AS cp
        ON qs.plan_handle = cp.plan_handle
WHERE
    DB_NAME(st.dbid) IS NOT NULL
    AND DB_NAME(st.dbid) IN ('YOUR_DATABASE')--, 'DBA_PerformanceHub', 'TICRAVIL', 'Guru5', 'Guru6', 'YOUR_DATABASE', 'YOUR_DATABASE')
GROUP BY
    DB_NAME(st.dbid)
  , OBJECT_SCHEMA_NAME(objectid, st.dbid)
  , OBJECT_NAME(objectid, st.dbid)
  , st.objectid;
-- ORDER BY Total_IO DESC;     -- 8 - VERIFICA MAIOR CONSUMO DE I/O
-- OU
-- ORDER BY Total_worker_time DESC; -- 4 - VERIFICA MAIOR CONSUMO DE CPU


-- ============================================================
-- MÉDIA DE CONSUMO POR OBJETO (SEM FORMATAÇÃO NUMÉRICA)
-- ============================================================
USE master;
GO

SELECT
    DB_NAME(st.dbid)                                                           AS DBName
  , OBJECT_SCHEMA_NAME(objectid, st.dbid)                                      AS SchemaName
  , st.objectid                                                                AS [Object_Id]
  , OBJECT_NAME(objectid, st.dbid)                                             AS [Object_Name]
  , SUM(qs.total_worker_time)                                                  AS Total_worker_time
  , SUM(qs.total_worker_time) / SUM(qs.execution_count)                        AS Avg_worker_time
  , MAX(cp.usecounts)                                                          AS UseCounts
  , SUM(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) AS Total_IO
  , SUM(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (MAX(cp.usecounts)) AS Avg_total_IO
  , SUM(qs.total_physical_reads)                                               AS Total_physical_reads
  , SUM(qs.total_physical_reads) / (MAX(cp.usecounts) * 1.0)                  AS Avg_physical_read
  , SUM(qs.total_logical_reads)                                                AS Total_logical_reads
  , SUM(qs.total_logical_reads) / (MAX(cp.usecounts) * 1.0)                   AS Avg_logical_read
  , SUM(qs.total_logical_writes)                                               AS Total_logical_writes
  , SUM(qs.total_logical_writes) / (MAX(cp.usecounts) * 1.0)                  AS Avg_logical_writes
  , SUM(qs.total_elapsed_time)                                                 AS Total_elapsed_time
  , SUM(qs.total_elapsed_time) / MAX(cp.usecounts)                            AS Avg_elapsed_time
FROM
    sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) AS st
    INNER JOIN sys.dm_exec_cached_plans AS cp
        ON qs.plan_handle = cp.plan_handle
WHERE
    DB_NAME(st.dbid) IS NOT NULL
    AND DB_NAME(st.dbid) IN ('YOUR_DATABASE')--, 'DBA_PerformanceHub', 'TICRAVIL', 'Guru5', 'Guru6', 'YOUR_DATABASE', 'YOUR_DATABASE')
GROUP BY
    DB_NAME(st.dbid)
  , OBJECT_SCHEMA_NAME(objectid, st.dbid)
  , OBJECT_NAME(objectid, st.dbid)
  , st.objectid;
-- ORDER BY Total_IO DESC;     -- 8 - VERIFICA MAIOR CONSUMO DE I/O
-- OU
-- ORDER BY Total_worker_time DESC; -- 4 - VERIFICA MAIOR CONSUMO DE CPU


-- ============================================================
-- TOP TEMPO DE CPU ACUMULADO
-- O exemplo a seguir retorna informações sobre as cinco principais
-- consultas classificadas pelo tempo médio de CPU. Este exemplo agrega
-- as consultas de acordo com seu hash de consulta para que as consultas
-- logicamente equivalentes sejam agrupadas pelo consumo cumulativo de recursos.
-- ============================================================
USE master;
GO

SELECT TOP 20
    query_stats.query_hash                                                     AS [Query Hash]
  , SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count)      AS [Avg CPU Time]
  , MIN(query_stats.statement_text)                                            AS [Statement Text]
FROM
    (
        SELECT
            QS.*
          , SUBSTRING
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
            )                                                                  AS statement_text
        FROM
            sys.dm_exec_query_stats AS QS
            CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) AS ST
    ) AS query_stats
GROUP BY
    query_stats.query_hash
ORDER BY
    [Avg CPU Time] DESC;


-- ============================================================
-- RETORNANDO AGREGADOS DE CONTAGEM DE LINHAS PARA UMA CONSULTA
-- O exemplo a seguir retorna informações agregadas de contagem de linhas
-- (linhas totais, linhas mínimas, linhas máximas e últimas linhas) para consultas.
-- ============================================================
SELECT
    qs.execution_count
  , SUBSTRING
    (
        qt.text,
        qs.statement_start_offset / 2 + 1,
        (
            (CASE WHEN qs.statement_end_offset = -1
                THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                ELSE qs.statement_end_offset
            END - qs.statement_start_offset) / 2
        )
    )                                                                          AS query_text
  , qt.text
  , qt.dbid
  , DBname                                                                     = DB_NAME(qt.dbid)
  , qt.objectid
  , ObjectName                                                                 = OBJECT_NAME(qt.objectid)
  , qs.total_rows
  , qs.last_rows
  , qs.min_rows
  , qs.max_rows
FROM
    sys.dm_exec_query_stats AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
WHERE
    qt.text LIKE '%SELECT%'
    AND qt.dbid = 6 -- YOUR_DATABASE
ORDER BY
    qs.execution_count DESC;
