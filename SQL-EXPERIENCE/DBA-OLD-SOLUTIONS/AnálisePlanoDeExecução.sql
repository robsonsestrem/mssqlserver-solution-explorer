-------------------------------------------------------------------------------------------------------------------------------
-- http://blog.sqlgrease.com/plan-cached-dm_exec_query_plan-returns-null/
-- para os planos que retornam nulos
-------------------------------------------------------------------------------------------------------------------------------
-- identifique o objeto para capturar o hash
select b.text, a.* from sys.dm_exec_procedure_stats a cross apply sys.dm_exec_sql_text(a.sql_handle) b 
where a.database_id = db_id('YOUR_DATABASE') and object_id = object_id('CaixasIntTraProcessar')

-- aplico esse hash na consulta abaixo
select
SUBSTRING(c.text, (a.statement_start_offset/2)+1,
((CASE a.statement_end_offset
WHEN -1 THEN DATALENGTH(c.text)
ELSE a.statement_end_offset
END - a.statement_start_offset)/2) + 1) AS statement_text,
convert(XML, b.query_plan)from
sys.dm_exec_query_stats a cross apply
sys.dm_exec_text_query_plan(a.plan_handle, a.statement_start_offset, a.statement_end_offset) b
cross apply sys.dm_exec_sql_text(a.sql_handle) c
-- coletar o hash
where a.plan_handle = 0x05000F00D915F5621056BB1D0000000001000000000000000000000000000000000000000000000000000000
