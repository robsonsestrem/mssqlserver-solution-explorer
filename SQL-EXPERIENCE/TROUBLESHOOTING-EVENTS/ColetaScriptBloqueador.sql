;WITH Sessoes (Sessao, Bloqueadora)
AS
(SELECT
    Session_Id
   ,Blocking_Session_Id
  FROM sys.dm_exec_requests AS R
  WHERE blocking_session_id > 0
  UNION ALL
  SELECT
    Session_Id
   ,CAST(0 AS SMALLINT)
  FROM sys.dm_exec_sessions AS S
  WHERE EXISTS (SELECT *
    FROM sys.dm_exec_requests AS R
    WHERE S.Session_Id = R.Blocking_Session_Id
	)
  AND NOT EXISTS (SELECT *
    FROM sys.dm_exec_requests AS R
    WHERE S.Session_Id = R.Session_Id)
),
Bloqueios
AS
(SELECT
    Sessao
   ,Bloqueadora
   ,Sessao AS Ref
   ,1 AS Nivel
  FROM Sessoes
  UNION ALL
  SELECT
    S.Sessao
   ,B.Sessao
   ,B.Ref
   ,Nivel + 1
  FROM Bloqueios AS B
  INNER JOIN Sessoes AS S
    ON B.Sessao = S.Bloqueadora
 )
SELECT
  Ref AS Spid_Bloqueador
 ,COUNT(DISTINCT R.Session_Id) AS Bloqueios_Diretos
 ,COUNT(DISTINCT B.Sessao) - 1 AS Total_Bloqueios
 ,COUNT(DISTINCT B.Sessao) - COUNT(DISTINCT R.Session_Id) - 1 AS Bloqueios_Indiretos
 ,(SELECT
      TEXT
    FROM sys.dm_exec_sql_text((SELECT
        most_recent_sql_handle
      FROM sys.dm_exec_connections

      WHERE session_id = B.Ref)
    ))
  AS Comando_Bloqueador
FROM Bloqueios AS B
INNER JOIN sys.dm_exec_requests AS R
  ON B.Ref = R.blocking_session_id
GROUP BY Ref


