------------------------------------------------------------------------------------------------------------------------------
--						Fechando sessões bloqueadas usando cursores 
------------------------------------------------------------------------------------------------------------------------------

--CREATE PROCEDURE SP_ELIMINA_BLOCK AS
use GesCooper90
go
DECLARE @v_spid INT
DECLARE @Sql VARCHAR(100)
DECLARE bloq_cursor CURSOR FOR

SELECT spid 
FROM MASTER.DBO.SYSPROCESSES BLOCKING 
WHERE BLOCKING.BLOCKED = 0 
AND EXISTS(SELECT 1 
		   FROM MASTER.DBO.SYSPROCESSES BLOCKED 
		   WHERE BLOCKED.BLOCKED = BLOCKING.SPID); -- captura spid com bloqueio

OPEN bloq_cursor
FETCH NEXT FROM bloq_cursor INTO @v_spid;
WHILE @@FETCH_STATUS = 0
BEGIN
Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)
EXEC (@Sql)
print 'killed spid '+str(@v_spid)
FETCH NEXT FROM bloq_cursor INTO @v_spid;
END
CLOSE bloq_cursor;
DEALLOCATE bloq_cursor;

