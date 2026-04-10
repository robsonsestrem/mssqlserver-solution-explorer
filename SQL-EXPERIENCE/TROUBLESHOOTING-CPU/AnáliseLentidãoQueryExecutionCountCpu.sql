----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Se você quer entender os resultados da query abaixo, basicamente são apresentados 
-- contadores de média e total para uso de CPU, duração da execução,
-- logical reads (leituras de cache) e physical reads, que é leitura direta de valores no disco.
-- Como os indicadores do SQL são inexatos é melhor tomálos como medidas relativas. 
-- O execution count apresenta o número de execuções, txt o corpo da consulta e query_plan
-- acaba por apresentar o plano de execução.
----------------------------------------------------------------------------------------------------------------------------------------------------------
--Fonte https://pedrogalvaojunior.wordpress.com/2016/04/27/dica-do-mes-identificando-as-top-10-querys-mais-pesadas-e-seus-respectivos-planos-de-execucao/
----------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.mssqltips.com/sqlservertip/2602/collecting-and-storing-poor-performing-sql-server-queries-for-analysis/
-- http://www.scarydba.com/2013/09/18/finding-ad-hoc-queries-with-query-hash/
-- https://jerfesonsantos.wordpress.com/
/*############ ATENÇÃO ##########################################
> Queries com a opção RECOMPILE não são capturadas;
> Queries estruturalmente similares não podem ser agrupadas;
> Algumas informações de execução da procedure não são 
consideradas. Alguns recursos de temporização como o WAITFOR 
não são considerados nas DMV e aparecem no Profiler.
#################################################################*/
-------------------------------------------------------------------------------------------------------------
-- Focado em objetos do banco
-------------------------------------------------------------------------------------------------------------
SELECT TOP 50
  SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1,
  ((CASE
    WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
    ELSE qs.statement_end_offset
  END - qs.statement_start_offset) / 2) + 1) AS [Individual Query]
 ,qt.text AS [Parent Query]
 ,DB_NAME(qt.dbid) AS DatabaseName
 ,qs.execution_count AS 'Execution Count'
 ,ISNULL(qs.execution_count / DATEDIFF(SECOND, qs.creation_time, GETDATE()), 0) AS 'Calls Per Second'
 ,qs.total_elapsed_time / qs.execution_count AS [Avg Duration (ms)]
 ,qs.total_physical_reads / qs.execution_count AS [Avg Physical Reads]
 ,qs.total_logical_reads / qs.execution_count AS [Avg Logical Reads]
 ,qs.total_logical_writes / qs.execution_count AS [Avg Logical Writes]
 ,qs.total_logical_reads AS 'Total Logical Reads'
 ,qs.last_logical_reads AS 'Last Logical Reads'
 ,qs.total_logical_writes AS 'Total Logical Writes'
 ,qs.last_logical_writes AS 'Last Logical Writes'
 ,qs.total_worker_time / qs.execution_count AS [Avg CPU Time (ms)]
 ,qs.total_worker_time AS 'Total Worker Time'
 ,qs.last_worker_time AS 'Last Worker Time'
 ,CAST(qs.total_elapsed_time / 1000.0 AS DECIMAL(28, 2)) AS [Total Elapsed Duration (s)]
 ,CAST(qs.last_elapsed_time AS DECIMAL(28, 2)) AS 'Last Elapsed Time (?)'
 ,qs.last_execution_time AS 'Last Execution Time'
 ,qp.query_plan AS 'Query Execution Plan'

FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE DB_NAME(qt.dbid) <> 'MAINTENANCE_DIX'
AND (
qs.execution_count > 100000
OR qs.total_logical_reads / qs.execution_count > 100000
OR qs.total_worker_time / qs.execution_count > 1000
OR qs.total_physical_reads / qs.execution_count > 100
OR qs.total_logical_writes / qs.execution_count > 100
OR qs.total_elapsed_time / qs.execution_count > 100
)
ORDER BY qs.execution_count DESC,
qs.total_elapsed_time / qs.execution_count DESC,
qs.total_worker_time / qs.execution_count DESC,
qs.total_physical_reads / qs.execution_count DESC,
qs.total_logical_reads / qs.execution_count DESC,
qs.total_logical_writes / qs.execution_count DESC


-------------------------------------------------------------------------------------------------------------
-- Focado em querys SELECT do banco
-- Identifica as "Recent Expensive Queries" (últimos X minutos)
-------------------------------------------------------------------------------------------------------------
DECLARE @Minutos INT = 30;

SELECT TOP 100
    SUBSTRING(est.text, (eqs.statement_start_offset / 2) + 1,
        ((CASE 
            WHEN eqs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), est.text)) * 2
            ELSE eqs.statement_end_offset
         END - eqs.statement_start_offset) / 2) + 1) AS [Individual Statement],
    est.text AS [Full Query Text],
    DB_NAME(est.dbid) AS DatabaseName,
    eqs.execution_count,
    ISNULL(eqs.execution_count / DATEDIFF(SECOND, eqs.creation_time, GETDATE()), 0) AS [Calls Per Second],
    eqs.total_elapsed_time / eqs.execution_count AS [Avg Duration (ms)],
    eqs.total_worker_time / eqs.execution_count AS [Avg CPU Time (ms)],
    eqs.total_logical_reads / eqs.execution_count AS [Avg Logical Reads],
    eqs.total_physical_reads / eqs.execution_count AS [Avg Physical Reads],
    eqs.total_logical_writes / eqs.execution_count AS [Avg Logical Writes],
    CAST(eqs.last_execution_time AS DATETIME) AS [Last Execution Time],
    CAST(eqs.total_elapsed_time / 1000.0 AS DECIMAL(18, 2)) AS [Total Duration (s)],
    eqs.total_worker_time AS [Total Worker Time (CPU ms)],
    eqs.total_logical_reads AS [Total Logical Reads],
    eqs.total_physical_reads AS [Total Physical Reads],
    qp.query_plan AS [Query Plan XML]
FROM sys.dm_exec_query_stats eqs
CROSS APPLY sys.dm_exec_sql_text(eqs.sql_handle) est
CROSS APPLY sys.dm_exec_query_plan(eqs.plan_handle) qp
WHERE est.text LIKE 'SELECT%'       -- Filtra só SELECTs, se quiser
    AND NOT est.text LIKE '%sys.%'  -- Remove system queries
    AND eqs.last_execution_time >= DATEADD(MINUTE, -@Minutos, GETDATE())  -- Apenas últimas X minutos
ORDER BY eqs.execution_count DESC                                         -- eqs.execution_count DESC; eqs.total_worker_time DESC; -- Pode mudar pra total_logical_reads, total_elapsed_time, etc.


