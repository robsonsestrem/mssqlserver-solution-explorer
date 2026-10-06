/*
    OBJETIVO: Analisar cursores abertos no SQL Server, identificando sessões e o texto SQL associado,
              utilizando DMVs de execução e cursores para diagnóstico de desempenho.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://viniciusfonsecadba.wordpress.com/2018/09/13/fetch-api_cursor-sql-server/
    https://blog.sqlauthority.com/2015/01/10/sql-server-what-is-the-query-used-in-sp_cursorfetch-and-fetch-api_cursor/
*/
/*
 * 
   CONTEXTO:
   O texto FETCH API_CURSOR00000000029DD4BF aparece quando um cliente (ODBC, .NET, JDBC, ADO, etc.) abre um cursor server-side via API 
   e o driver manda comandos FETCH diretamente, sem enviar o SQL original. O SQL Server guarda apenas um handle sintético (API_CURSOR...) 
   no dm_exec_cursors, então sys.dm_exec_sql_text retorna esse nome em vez da query real.  
 *
 */
-- ============================================================
-- Query completa — todas as conexões, 
-- com dados de cursor quando existirem
-- ============================================================
SELECT
    'KILL ' + CAST(s.session_id AS VARCHAR(5))                  AS kill_command,
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    DB_NAME(s.database_id)                                      AS database_name,
    s.last_request_start_time,
    s.last_request_end_time,
    -- cursor (NULL quando a sessão não tem cursor aberto)
    c.cursor_id,
    c.creation_time                                             AS cursor_creation_time,
    c.is_open,
    c.properties,
    c.statement_start_offset,
    c.statement_end_offset,
    -- texto do cursor (normalmente "FETCH API_CURSOR...")
    SUBSTRING(
        st_cursor.text,
        (c.statement_start_offset / 2) + 1,
        (
            (CASE c.statement_end_offset
                WHEN -1 THEN DATALENGTH(st_cursor.text)
                ELSE c.statement_end_offset
             END - c.statement_start_offset) / 2
        ) + 1
    )                                                           AS cursor_statement_text,
    -- texto real do batch da conexão
    st_conn.text                                                AS connection_sql_text,
    -- último input enviado pelo cliente (útil quando o batch não está no cache)
    ib.event_info                                               AS last_input_buffer
FROM sys.dm_exec_sessions AS s
LEFT JOIN sys.dm_exec_connections AS ec
    ON ec.session_id = s.session_id
LEFT JOIN sys.dm_exec_cursors(0) AS c
    ON c.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(c.sql_handle)                  AS st_cursor
OUTER APPLY sys.dm_exec_sql_text(ec.most_recent_sql_handle)     AS st_conn
OUTER APPLY sys.dm_exec_input_buffer(s.session_id, NULL)        AS ib
WHERE s.is_user_process = 1   -- remove sessões internas do SQL Server
AND s.session_id NOT IN (@@SPID) 


