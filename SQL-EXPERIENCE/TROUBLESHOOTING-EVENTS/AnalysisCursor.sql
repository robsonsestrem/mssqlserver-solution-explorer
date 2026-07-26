/*
    OBJETIVO: Analisar cursores abertos no SQL Server, identificando sessões e o texto SQL associado,
              utilizando DMVs de execução e cursores para diagnóstico de desempenho.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://viniciusfonsecadba.wordpress.com/2018/09/13/fetch-api_cursor-sql-server/
    https://blog.sqlauthority.com/2015/01/10/sql-server-what-is-the-query-used-in-sp_cursorfetch-and-fetch-api_cursor/
*/

-- ============================================================
-- SEÇÃO 1: Identificação de sessões com FETCH API_CURSOR
-- ============================================================

-- CTE para localizar conexões executando operações de FETCH em cursores
WITH cte AS (
    SELECT 
        session_id
        , t.text
    FROM sys.dm_exec_connections AS c
    CROSS APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) AS t
    WHERE t.text LIKE '%FETCH API_CURSOR%'
)

-- Seleção distinta dos detalhes do cursor e do texto SQL associado
SELECT DISTINCT
    c.session_id
    , c.properties
    , c.creation_time
    , c.is_open
    , t.text
FROM cte
CROSS APPLY sys.dm_exec_cursors(session_id) AS c
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) AS t;

-- ============================================================
-- SEÇÃO 2: Detalhamento de cursores e extração do texto SQL
-- ============================================================

-- Consulta detalhada de todos os cursores ativos com extração do trecho SQL em execução
SELECT 
    c.creation_time
    , c.cursor_id
    , c.session_id
    , c.properties
    , c.creation_time
    , c.is_open
    , SUBSTRING(
        st.text
        , (c.statement_start_offset / 2) + 1
        , (
            (
                CASE c.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.text)
                    ELSE c.statement_end_offset
                END - c.statement_start_offset
            ) / 2
        ) + 1
    ) AS statement_text
FROM sys.dm_exec_cursors(0) AS c
INNER JOIN sys.dm_exec_sessions AS s
    ON c.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(c.sql_handle) AS st;
