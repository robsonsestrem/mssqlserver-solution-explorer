/*
	OBJETIVO: Monitoramento de consultas com ocorrência de Full Scans, identificando
			  possíveis índices ausentes (Missing Indexes) com base no cache do SQL Server.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS E AUTORIA:
	Autor: Júnior Galvão	
*/
SET NOCOUNT ON;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- ==============================================================================
-- Bloco principal: Extrai dados de estatísticas de execução e planos de consulta
-- para identificar onde há sugestão de índices ausentes.
-- ==============================================================================
SELECT
      x.CPU
    , x.Duration
    , x.Reads
    , x.execution_count
    , x.query_plan
    , x.txt
    , x.TotalImpact
    , x.[Database]
    , x.[Table]
FROM
(
    SELECT
          -- Tratamento para evitar divisão por zero (comentário original mantido)
          qs.total_worker_time                                             AS CPU
        , qs.total_elapsed_time                                            AS Duration
        , (qs.total_logical_reads + qs.total_physical_reads)               AS Reads
        , qs.execution_count
        , CAST(qp.query_plan AS VARCHAR(MAX))                              AS query_plan
        , SUBSTRING
          (
              st.text
            , (qs.statement_start_offset / 2) + 1
            , (
                  (
                      CASE qs.statement_end_offset
                          WHEN -1
                          THEN DATALENGTH(st.text)
                          ELSE qs.statement_end_offset
                      END - qs.statement_start_offset
                  ) / 2
              ) + 1
          )                                                                AS txt
        , qp.query_plan.value
          (
              'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]'
            , 'NVARCHAR(MAX)'
          )                                                                AS TotalImpact -- * execution_count -- tratar multiplicação com nulo (comentário original mantido)
        , qp.query_plan.value
          (
              'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch//Stmts/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]'
            , 'NVARCHAR(MAX)'
          )                                                                AS [Database]
        , qp.query_plan.value
          (
              'declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]'
            , 'NVARCHAR(MAX)'
          )                                                                AS [Table]
    FROM sys.dm_exec_query_stats                                          AS qs
    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle)                       AS st
    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle)                    AS qp
    -- WHERE CAST(qp.query_plan AS VARCHAR(MAX)) LIKE '%missing%'         -- Filtro opcional comentado
    -- ORDER BY TotalImpact DESC                                          -- Ordenação opcional comentada
)                                                                          AS x
WHERE x.query_plan LIKE '%missing%';

SET NOCOUNT OFF;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
