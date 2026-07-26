/*
	OBJETIVO: Identificar planos de execução em cache que contenham operadores de
			  paralelismo (Parallelism), extraindo o texto da consulta, custo e
			  estatísticas de uso do plano.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS E AUTORIA:
	Referência: Vitor Fava (MVP)	
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

WITH XMLNAMESPACES
(
    DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan'
)
SELECT
      eqp.query_plan                                                                   AS CompleteQueryPlan
    , qn.n.value('(@StatementText)[1]', 'VARCHAR(4000)')                               AS StatementText
    , qn.n.value('(@StatementOptmLevel)[1]', 'VARCHAR(25)')                            AS StatementOptimizationLevel
    , qn.n.value('(@StatementSubTreeCost)[1]', 'VARCHAR(128)')                         AS StatementSubTreeCost
    , qn.n.query('.')                                                                  AS ParallelSubTreeXML
    , ecp.usecounts
    , ecp.size_in_bytes
FROM sys.dm_exec_cached_plans                                                          AS ecp
CROSS APPLY sys.dm_exec_query_plan(ecp.plan_handle)                                    AS eqp
CROSS APPLY eqp.query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS qn(n)
WHERE qn.n.query('.').exist('//RelOp[@PhysicalOp="Parallelism"]') = 1;

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
