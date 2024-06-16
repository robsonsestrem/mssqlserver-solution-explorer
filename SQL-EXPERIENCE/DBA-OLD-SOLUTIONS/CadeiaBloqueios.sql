---------------------------------------------------------------------------------------------------
-- Cadeia de bloqueios - identifica dependências entre os "spids"
---------------------------------------------------------------------------------------------------
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
    WHERE S.Session_Id = R.Blocking_Session_Id)
  AND NOT EXISTS (SELECT *
    FROM sys.dm_exec_requests AS R
    WHERE S.Session_Id = R.Session_Id)
 ),
Bloqueios
AS
(SELECT
    CAST(Sessao AS VARCHAR(200)) AS Cadeia
   ,Sessao
   ,Bloqueadora
   ,1 AS Nivel
  FROM Sessoes
  UNION ALL
  SELECT
    CAST(B.Cadeia + ' -> ' + CAST(S.Sessao AS VARCHAR(5)) AS VARCHAR(200))
   ,S.Sessao
   ,B.Sessao
   ,Nivel + 1
  FROM Bloqueios AS B
  INNER JOIN Sessoes AS S
    ON B.Sessao = S.Bloqueadora
)
SELECT
  Cadeia AS Cadeia_Dependencias_Bloqueadores
FROM Bloqueios
WHERE Nivel = (SELECT  MAX(Nivel) FROM Bloqueios)
ORDER BY Cadeia


