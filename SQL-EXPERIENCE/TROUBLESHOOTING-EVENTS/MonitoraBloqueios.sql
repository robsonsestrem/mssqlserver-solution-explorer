/*
    OBJETIVO: Monitorar e identificar bloqueios (blocking) no SQL Server,
              apresentando sessões bloqueadas, sessões bloqueadoras,
              cadeia de dependências e comandos em execução, além de
              opção para encerrar sessões bloqueadoras.
    PROJETO: mssqlserver-solution-explorer
*/

USE master;
GO

-- ============================================================
-- Bloqueios detalhados com informações das sessões
-- ============================================================
;WITH [Blocking]
AS (
    SELECT
        w.session_id
      , s.original_login_name
      , s.login_name
      , w.wait_duration_ms
      , w.wait_type
      , r.status
      , r.wait_resource
      , w.resource_description
      , s.program_name
      , w.blocking_session_id
      , s.host_name
      , r.command
      , r.percent_complete
      , r.cpu_time
      , r.total_elapsed_time
      , r.reads
      , r.writes
      , r.logical_reads
      , r.row_count
      , q.text
      , q.dbid
      , p.query_plan
      , r.plan_handle
    FROM
        sys.dm_os_waiting_tasks AS w
        INNER JOIN sys.dm_exec_sessions AS s
            ON w.session_id = s.session_id
        INNER JOIN sys.dm_exec_requests AS r
            ON s.session_id = r.session_id
        CROSS APPLY sys.dm_exec_sql_text(r.plan_handle) AS q
        CROSS APPLY sys.dm_exec_query_plan(r.plan_handle) AS p
    WHERE
        w.session_id > 50
        AND w.wait_type NOT IN ('DBMIRROR_DBM_EVENT', 'ASYNC_NETWORK_IO')
)

SELECT
    b.session_id                                                           AS [WaitingSessionID]
  , b.blocking_session_id                                                  AS [BlockingSessionID]
  , b.login_name                                                           AS [WaitingUserSessionLogin]
  , s1.login_name                                                          AS [BlockingUserSessionLogin]
  , CAST(b.wait_duration_ms / 1000.0 AS DECIMAL(28, 2))                    AS [WaitDuration (s)]
  , b.wait_type                                                            AS [WaitType]
  , t.request_mode                                                         AS [WaitRequestMode]
  , UPPER(b.status)                                                        AS [WaitingProcessStatus]
  , UPPER(s1.status)                                                       AS [BlockingSessionStatus]
  , DB_NAME(t.resource_database_id)                                        AS [WaitResourceDatabaseName]
  , b.program_name                                                         AS [WaitingSessionProgramName]
  , s1.program_name                                                        AS [BlockingSessionProgramName]
  , b.host_name                                                            AS [WaitingHost]
  , s1.host_name                                                           AS [BlockingHost]
  , b.command                                                              AS [WaitingCommandType]
  , b.text                                                                 AS [WaitingCommandText]
  , b.total_elapsed_time                                                   AS [WaitingCommandTotalElapsedTime]
FROM
    [Blocking] AS b
    INNER JOIN sys.dm_exec_sessions AS s1
        ON b.blocking_session_id = s1.session_id
    INNER JOIN sys.dm_tran_locks AS t
        ON t.request_session_id = b.session_id
WHERE
    t.request_status != 'GRANT';


-- ============================================================
-- Bloqueios por sessão (spid) com comando do spid bloqueador
-- ============================================================
;WITH Sessoes (Sessao, Bloqueadora)
AS (
    SELECT
        Session_Id
      , Blocking_Session_Id
    FROM
        sys.dm_exec_requests AS R
    WHERE
        blocking_session_id > 0

    UNION ALL

    SELECT
        Session_Id
      , CAST(0 AS SMALLINT)
    FROM
        sys.dm_exec_sessions AS S
    WHERE
        EXISTS
        (
            SELECT *
            FROM sys.dm_exec_requests AS R
            WHERE S.Session_Id = R.Blocking_Session_Id
        )
        AND NOT EXISTS
        (
            SELECT *
            FROM sys.dm_exec_requests AS R
            WHERE S.Session_Id = R.Session_Id
        )
)
, Bloqueios
AS (
    SELECT
        Sessao
      , Bloqueadora
      , Sessao AS Ref
      , 1 AS Nivel
    FROM
        Sessoes

    UNION ALL

    SELECT
        S.Sessao
      , B.Sessao
      , B.Ref
      , Nivel + 1
    FROM
        Bloqueios AS B
        INNER JOIN Sessoes AS S
            ON B.Sessao = S.Bloqueadora
)

SELECT
    Ref                                                                     AS Spid_Bloqueador
  , COUNT(DISTINCT R.Session_Id)                                            AS Bloqueios_Diretos
  , COUNT(DISTINCT B.Sessao) - 1                                            AS Total_Bloqueios
  , COUNT(DISTINCT B.Sessao) - COUNT(DISTINCT R.Session_Id) - 1             AS Bloqueios_Indiretos
  , (
        SELECT
            TEXT
        FROM
            sys.dm_exec_sql_text
            (
                (
                    SELECT
                        most_recent_sql_handle
                    FROM
                        sys.dm_exec_connections
                    WHERE
                        session_id = B.Ref
                )
            )
    )                                                                       AS Comando_Bloqueador
FROM
    Bloqueios AS B
    INNER JOIN sys.dm_exec_requests AS R
        ON B.Ref = R.blocking_session_id
GROUP BY
    Ref;


-- ============================================================
-- Cadeia de bloqueios - identifica dependências entre os spids
-- ============================================================
;WITH Sessoes (Sessao, Bloqueadora)
AS (
    SELECT
        Session_Id
      , Blocking_Session_Id
    FROM
        sys.dm_exec_requests AS R
    WHERE
        blocking_session_id > 0

    UNION ALL

    SELECT
        Session_Id
      , CAST(0 AS SMALLINT)
    FROM
        sys.dm_exec_sessions AS S
    WHERE
        EXISTS
        (
            SELECT *
            FROM sys.dm_exec_requests AS R
            WHERE S.Session_Id = R.Blocking_Session_Id
        )
        AND NOT EXISTS
        (
            SELECT *
            FROM sys.dm_exec_requests AS R
            WHERE S.Session_Id = R.Session_Id
        )
)
, Bloqueios
AS (
    SELECT
        CAST(Sessao AS VARCHAR(200))                                        AS Cadeia
      , Sessao
      , Bloqueadora
      , 1 AS Nivel
    FROM
        Sessoes

    UNION ALL

    SELECT
        CAST(B.Cadeia + ' -> ' + CAST(S.Sessao AS VARCHAR(5)) AS VARCHAR(200))
      , S.Sessao
      , B.Sessao
      , Nivel + 1
    FROM
        Bloqueios AS B
        INNER JOIN Sessoes AS S
            ON B.Sessao = S.Bloqueadora
)

SELECT
    Cadeia                                                                  AS Cadeia_Dependencias_Bloqueadores
FROM
    Bloqueios
WHERE
    Nivel = (SELECT MAX(Nivel) FROM Bloqueios)
ORDER BY
    Cadeia;


-- ============================================================
-- Top 100 bloqueios - ordenados por tempo de espera
-- ============================================================
SELECT TOP 100
    Session_Id                                                              AS Sessão_Bloqueada
  , Blocking_Session_Id                                                     AS Bloqueador
FROM
    sys.dm_exec_requests
WHERE
    Blocking_Session_Id > 0
ORDER BY
    Wait_Time DESC;
