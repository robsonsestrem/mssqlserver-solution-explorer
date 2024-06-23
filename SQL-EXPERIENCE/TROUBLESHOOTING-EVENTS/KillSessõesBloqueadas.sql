------------------------------------------------------------------------------------------------------------------------------
--						Fechando sessões bloqueadas
------------------------------------------------------------------------------------------------------------------------------
-- CREATE
-- PROCEDURE SP_ELIMINA_BLOCK AS

DECLARE @v_spid INT
DECLARE @Sql VARCHAR(100)

Set @v_spid =(SELECT spid 
			  FROM MASTER.DBO.SYSPROCESSES BLOCKING 
			  WHERE BLOCKING.BLOCKED = 0 
			  AND EXISTS (SELECT 1 
						  FROM MASTER.DBO.SYSPROCESSES BLOCKED 
						  WHERE BLOCKED.BLOCKED = BLOCKING.SPID));

Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)
EXEC (@Sql)

SELECT top 1 @v_spid =spid 
FROM MASTER.DBO.SYSPROCESSES BLOCKING 
WHERE BLOCKING.BLOCKED = 0 
AND EXISTS (SELECT 1 
			FROM MASTER.DBO.SYSPROCESSES BLOCKED 
			WHERE BLOCKED.BLOCKED = BLOCKING.SPID);
Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)

EXEC (@Sql)

