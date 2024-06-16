use master
go

;WITH [Blocking]
AS (SELECT w.[session_id]
   ,s.[original_login_name]
   ,s.[login_name]
   ,w.[wait_duration_ms]
   ,w.[wait_type]
   ,r.[status]
   ,r.[wait_resource]
   ,w.[resource_description]
   ,s.[program_name]
   ,w.[blocking_session_id]
   ,s.[host_name]
   ,r.[command]
   ,r.[percent_complete]
   ,r.[cpu_time]
   ,r.[total_elapsed_time]
   ,r.[reads]
   ,r.[writes]
   ,r.[logical_reads]
   ,r.[row_count]
   ,q.[text]
   ,q.[dbid]
   ,p.[query_plan]
   ,r.[plan_handle]
 FROM [sys].[dm_os_waiting_tasks] w
 INNER JOIN [sys].[dm_exec_sessions] s ON w.[session_id] = s.[session_id]
 INNER JOIN [sys].[dm_exec_requests] r ON s.[session_id] = r.[session_id]
 CROSS APPLY [sys].[dm_exec_sql_text](r.[plan_handle]) q
 CROSS APPLY [sys].[dm_exec_query_plan](r.[plan_handle]) p
 WHERE w.[session_id] > 50
  AND w.[wait_type] NOT IN ('DBMIRROR_DBM_EVENT','ASYNC_NETWORK_IO')
  )

SELECT b.[session_id] AS [WaitingSessionID]
      ,b.[blocking_session_id] AS [BlockingSessionID]
      ,b.[login_name] AS [WaitingUserSessionLogin]
      ,s1.[login_name] AS [BlockingUserSessionLogin]
      ,cast(b.[wait_duration_ms] / 1000.0 as decimal(28,2)) AS [WaitDuration (s)]
      ,b.[wait_type] AS [WaitType]
      ,t.[request_mode] AS [WaitRequestMode]
      ,UPPER(b.[status]) AS [WaitingProcessStatus]
      ,UPPER(s1.[status]) AS [BlockingSessionStatus]
      ,DB_NAME(t.[resource_database_id]) AS [WaitResourceDatabaseName]
      ,b.[program_name] AS [WaitingSessionProgramName]
      ,s1.[program_name] AS [BlockingSessionProgramName]
      ,b.[host_name] AS [WaitingHost]
      ,s1.[host_name] AS [BlockingHost]
      ,b.[command] AS [WaitingCommandType]
      ,b.[text] AS [WaitingCommandText]
      ,b.[total_elapsed_time] AS [WaitingCommandTotalElapsedTime]
FROM [Blocking] b
INNER JOIN [sys].[dm_exec_sessions] s1
ON b.[blocking_session_id] = s1.[session_id]
INNER JOIN [sys].[dm_tran_locks] t
ON t.[request_session_id] = b.[session_id]
WHERE t.[request_status] != 'GRANT';


---------------------------------------------------------------------------------------------------
-- Boqueios por sessão(spid) com comando do spid que está causando o bloqueio
---------------------------------------------------------------------------------------------------
;WITH Sessoes (Sessao, Bloqueadora) As (

SELECT Session_Id, Blocking_Session_Id

FROM sys.dm_exec_requests As R

WHERE blocking_session_id > 0

UNION ALL

SELECT Session_Id, CAST(0 As SMALLINT)

FROM sys.dm_exec_sessions As S

WHERE EXISTS (

SELECT * FROM sys.dm_exec_requests As R

WHERE S.Session_Id = R.Blocking_Session_Id)

AND NOT EXISTS (

SELECT * FROM sys.dm_exec_requests As R

WHERE S.Session_Id = R.Session_Id)

),

Bloqueios As (

SELECT

Sessao, Bloqueadora, Sessao As Ref, 1 As Nivel

FROM Sessoes

UNION ALL

SELECT S.Sessao, B.Sessao, B.Ref, Nivel + 1

FROM Bloqueios As B

INNER JOIN Sessoes As S ON B.Sessao = S.Bloqueadora)

SELECT Ref As Spid_Bloqueador,

COUNT(DISTINCT R.Session_Id) As Bloqueios_Diretos,

COUNT(DISTINCT B.Sessao) - 1 As Total_Bloqueios,

COUNT(DISTINCT B.Sessao) - COUNT(DISTINCT R.Session_Id) - 1 As Bloqueios_Indiretos,

(SELECT TEXT FROM sys.dm_exec_sql_text(

(SELECT most_recent_sql_handle FROM sys.dm_exec_connections

WHERE session_id = B.Ref))) As Comando_Bloqueador

FROM Bloqueios As B

INNER JOIN sys.dm_exec_requests As R

ON B.Ref = R.blocking_session_id

GROUP BY Ref


---------------------------------------------------------------------------------------------------
-- Cadeia de bloqueios - identifica dependências entre os spids
---------------------------------------------------------------------------------------------------

;WITH Sessoes (Sessao, Bloqueadora) As (

SELECT Session_Id, Blocking_Session_Id

FROM sys.dm_exec_requests As R

WHERE blocking_session_id > 0

UNION ALL

SELECT Session_Id, CAST(0 As SMALLINT)

FROM sys.dm_exec_sessions As S

WHERE EXISTS (

SELECT * FROM sys.dm_exec_requests As R

WHERE S.Session_Id = R.Blocking_Session_Id)

AND NOT EXISTS (

SELECT * FROM sys.dm_exec_requests As R

WHERE S.Session_Id = R.Session_Id)

),

Bloqueios As (

SELECT

CAST(Sessao As VARCHAR(200)) As Cadeia,

Sessao, Bloqueadora, 1 As Nivel

FROM Sessoes

UNION ALL

SELECT CAST(B.Cadeia + ' ­> ' + CAST(S.Sessao As VARCHAR(5)) As VARCHAR(200)),

S.Sessao, B.Sessao, Nivel + 1

FROM Bloqueios As B

INNER JOIN Sessoes As S ON B.Sessao = S.Bloqueadora)

SELECT Cadeia AS Cadeia_Dependencias_Bloqueadores
FROM Bloqueios

WHERE Nivel = (SELECT MAX(Nivel) FROM Bloqueios)

ORDER BY Cadeia


---------------------------------------------------------------------------------------------------
-- top 10 bloqueios - Pela ordenação o primeiro Session_Id da lista é o que mais está esperando
-- e na mesma linha mostra quem está bloqueando.
-- nesta lista da coluna Blocking_Session_Id é possível ver se o mesmo spid está 
-- bloqueando outras sessões.
---------------------------------------------------------------------------------------------------
SELECT TOP 100 Session_Id as Sessão_Bloqueada, Blocking_Session_Id as Bloqueador

FROM sys.dm_exec_requests

WHERE Blocking_Session_Id > 0

ORDER BY Wait_Time DESC



------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--						Fechando sessões bloqueadas
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- CREATE
-- PROCEDURE SP_ELIMINA_BLOCK AS

--DECLARE @v_spid INT
--DECLARE @Sql VARCHAR(100)

--Set @v_spid =(SELECT spid 
--			  FROM MASTER.DBO.SYSPROCESSES BLOCKING 
--			  WHERE BLOCKING.BLOCKED = 0 
--			  AND EXISTS (SELECT 1 
--						  FROM MASTER.DBO.SYSPROCESSES BLOCKED 
--						  WHERE BLOCKED.BLOCKED = BLOCKING.SPID));

--Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)
--EXEC (@Sql)

--SELECT top 1 @v_spid =spid 
--FROM MASTER.DBO.SYSPROCESSES BLOCKING 
--WHERE BLOCKING.BLOCKED = 0 
--AND EXISTS (SELECT 1 
--			FROM MASTER.DBO.SYSPROCESSES BLOCKED 
--			WHERE BLOCKED.BLOCKED = BLOCKING.SPID);
--Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)

--EXEC (@Sql)
