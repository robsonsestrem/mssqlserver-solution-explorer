-- Exemplo – Query – Monitoramento de Consumo com ocorrência de FullScans
-- Júnior Galvão

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

select * from
(
	SELECT 
	-- tratar divisão por zero
	qs.total_worker_time as CPU, -- / qs.execution_count
																					  
	qs.total_elapsed_time as Duration, -- / qs.execution_count	
																						
	(qs.total_logical_reads + qs.total_physical_reads ) Reads, -- / qs.execution_count			

	execution_count,

	cast(qp.query_plan as varchar(max)) as query_plan,

	substring(st.text, (qs.statement_start_offset/2)+1 , ((case qs.statement_end_offset when - 1 then datalength(st.text) 
	else qs.statement_end_offset end - qs.statement_start_offset)/2) + 1)													as txt,

	qp.query_plan.value('declare default element namespace http://schemas.microsoft.com/sqlserver/2004/07/showplan; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]' , 'nvarchar(max)') as TotalImpact, --* execution_count -- tratar multiplicação com nulo,

	qp.query_plan.value('declare default element namespace http://schemas.microsoft.com/sqlserver/2004/07/showplan; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]' , 'nvarchar(max)') AS [Database],

	qp.query_plan.value('declare default element namespace http://schemas.microsoft.com/sqlserver/2004/07/showplan; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]' , 'nvarchar(max)') AS [Table]
	from sys.dm_exec_query_stats qs
	cross apply sys.dm_exec_sql_text(sql_handle) st
	cross apply sys.dm_exec_query_plan(plan_handle) qp	
	--where cast(qp.query_plan as varchar(max)) like '%missing%'
	--order by TotalImpact desc
) as x
where x.query_plan like '%missing%'


SET NOCOUNT OFF
SET TRANSACTION ISOLATION LEVEL READ COMMITTED


