/*
    OBJETIVO: Identificar e encerrar todas as sessões que estão bloqueando
              outras sessões no SQL Server utilizando cursores, eliminando
              os bloqueios de forma iterativa.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- Fechar sessões bloqueadas usando cursores
-- ============================================================

DECLARE @v_spid INT;
DECLARE @Sql VARCHAR(100);

DECLARE bloq_cursor CURSOR FOR
SELECT
    spid
FROM
    master.dbo.sysprocesses AS Blocking
WHERE
    Blocking.blocked = 0
    AND EXISTS
    (
        SELECT 1
        FROM master.dbo.sysprocesses AS Blocked
        WHERE Blocked.blocked = Blocking.spid
    );  -- captura spid com bloqueio

OPEN bloq_cursor;

FETCH NEXT FROM bloq_cursor INTO @v_spid;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Sql = 'KILL ' + CAST(@v_spid AS VARCHAR);
    EXEC(@Sql);

    PRINT 'killed spid ' + STR(@v_spid);

    FETCH NEXT FROM bloq_cursor INTO @v_spid;
END;

CLOSE bloq_cursor;
DEALLOCATE bloq_cursor;
