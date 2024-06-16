----------------------------------------------------------------------------
-- http://blog.sqlgrease.com/ever-wondered-sql-generated-fetch-statement/
----------------------------------------------------------------------------
SELECT er.sql_handle
, ec.sql_handle

, SUBSTRING(ers.text, (er.statement_start_offset/2)+1,(
	(CASE er.statement_end_offset WHEN -1 THEN DATALENGTH(ers.text)
		ELSE er.statement_end_offset
     END - er.statement_start_offset)/2) + 1) AS statement_text_er

, SUBSTRING(ecs.text, (ec.statement_start_offset/2)+1,(
    (CASE ec.statement_end_offset WHEN -1 THEN DATALENGTH(ecs.text)
	    ELSE ec.statement_end_offset
     END - ec.statement_start_offset)/2) + 1) AS statement_text_ec
FROM sys.dm_exec_requests er 
CROSS APPLY sys.dm_exec_cursors(er.session_id) ec
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) ers
CROSS APPLY sys.dm_exec_sql_text(ec.sql_handle) ecs
WHERE er.session_id = 434


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://viniciusfonsecadba.wordpress.com/2018/09/13/fetch-api_cursor-sql-server/
--------------------------------------------------------------------------------------------------------------------------------------------------------
with cte 
as (
SELECT session_id, t.text
FROM sys.dm_exec_connections c
CROSS APPLY sys.dm_exec_sql_text (c.most_recent_sql_handle) t
where text like '%FETCH API_CURSOR%'
)

SELECT distinct c.session_id, c.properties, c.creation_time, c.is_open, t.[text]
FROM cte 
cross apply sys.dm_exec_cursors (session_id) c
CROSS APPLY sys.dm_exec_sql_text (c.sql_handle) t


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://blog.sqlauthority.com/2015/01/10/sql-server-what-is-the-query-used-in-sp_cursorfetch-and-fetch-api_cursor/
--------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT creation_time,
cursor_id,
c.session_id,
c.properties,
c.creation_time,
c.is_open,
SUBSTRING(st.TEXT, ( c.statement_start_offset / 2) + 1, (
( CASE c.statement_end_offset
WHEN -1 THEN DATALENGTH(st.TEXT)
ELSE c.statement_end_offset
END - c.statement_start_offset) / 2) + 1) AS statement_text
FROM   sys.dm_exec_cursors(0) AS c
JOIN sys.dm_exec_sessions AS s
ON c.session_id = s.session_id
CROSS apply sys.Dm_exec_sql_text(c.sql_handle) AS st