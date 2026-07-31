/*
 *
	OBJETIVO: Identificar e extrair o plano de execução em texto de procedimentos armazenados que retornam nulos em dm_exec_query_plan, capturando o hash do plano para análise.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	http://blog.sqlgrease.com/plan-cached-dm_exec_query_plan-returns-null/
 */
-- ============================================================
-- Análise de Plano de Execução em Cache
-- ============================================================

-- Identifique o objeto para capturar o hash
SELECT
    b.text
  , a.*
FROM sys.dm_exec_procedure_stats AS a
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) AS b
WHERE a.database_id = DB_ID('YOUR_DATABASE')
  AND a.object_id = OBJECT_ID('CaixasIntTraProcessar')

-- Aplique esse hash na consulta abaixo
SELECT
    SUBSTRING(
        c.text
      , (a.statement_start_offset / 2) + 1
      , (
            (
                CASE a.statement_end_offset
                    WHEN -1 THEN DATALENGTH(c.text)
                    ELSE a.statement_end_offset
                END - a.statement_start_offset
            ) / 2
        ) + 1
    ) AS statement_text
  , CONVERT(XML, b.query_plan) AS query_plan
FROM sys.dm_exec_query_stats AS a
CROSS APPLY sys.dm_exec_text_query_plan(
    a.plan_handle
  , a.statement_start_offset
  , a.statement_end_offset
) AS b
CROSS APPLY sys.dm_exec_sql_text(a.sql_handle) AS c
-- Coletar o hash
WHERE a.plan_handle = 0x05000F00D915F5621056BB1D0000000001000000000000000000000000000000000000000000000000000000
