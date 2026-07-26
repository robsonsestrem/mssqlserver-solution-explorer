/*
    OBJETIVO: Identificar e encerrar sessões que estão bloqueando outras
              sessões no SQL Server, eliminando o bloqueio e permitindo
              que as demais execuções prossigam.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Fechar sessões bloqueadas
-- ============================================================

DECLARE @v_spid INT;
DECLARE @Sql VARCHAR(100);

-- Primeiro bloqueador
SELECT TOP 1
    @v_spid = spid
FROM
    master.dbo.sysprocesses AS Blocking
WHERE
    Blocking.blocked = 0
    AND EXISTS
    (
        SELECT 1
        FROM master.dbo.sysprocesses AS Blocked
        WHERE Blocked.blocked = Blocking.spid
    );

SET @Sql = 'KILL ' + CAST(@v_spid AS VARCHAR);
EXEC(@Sql);

-- Segundo bloqueador (caso exista)
SELECT TOP 1
    @v_spid = spid
FROM
    master.dbo.sysprocesses AS Blocking
WHERE
    Blocking.blocked = 0
    AND EXISTS
    (
        SELECT 1
        FROM master.dbo.sysprocesses AS Blocked
        WHERE Blocked.blocked = Blocking.spid
    );

SET @Sql = 'KILL ' + CAST(@v_spid AS VARCHAR);
EXEC(@Sql);
