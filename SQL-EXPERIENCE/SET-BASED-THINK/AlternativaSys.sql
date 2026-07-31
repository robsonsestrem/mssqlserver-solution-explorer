/*
	OBJETIVO: Demonstrar alternativas ao uso de cursores em SQL Server,
			  apresentando um exemplo com cursor tradicional e sua versão
			  refatorada utilizando tabela temporária com ROWCOUNT e DELETE
			  para obter o mesmo comportamento de forma mais eficiente.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Exemplo 1: Utilizando CURSOR para percorrer processos ativos
-- ============================================================
DECLARE @processo  SMALLINT;
DECLARE @nm_login  NVARCHAR(256);
DECLARE cur_logins CURSOR FOR
SELECT
      sp.spid
    , sp.uid
FROM master..sysprocesses AS sp
INNER JOIN master..syslogins AS sl
        ON sp.sid = sl.sid
WHERE sp.uid != 0
      AND sp.spid != @@SPID;

OPEN cur_logins;

WHILE 0 = 0
BEGIN
    FETCH cur_logins INTO @processo, @nm_login;

    IF @@FETCH_STATUS <> 0
    BEGIN
        BREAK;
    END;

    SELECT
          @processo AS Processo
        , @nm_login AS Login
END

CLOSE cur_logins
DEALLOCATE cur_logins
GO

-- ============================================================
-- Exemplo 2: Alternativa sem CURSOR utilizando tabela temporária
-- ============================================================
DECLARE @processo_sem_cursor  SMALLINT;
DECLARE @nm_login_sem_cursor  NVARCHAR(256);

SELECT
      sp.spid
    , sp.uid
INTO #t_logins
FROM master..sysprocesses AS sp
INNER JOIN master..syslogins AS sl
        ON sp.sid = sl.sid
WHERE sp.uid != 0
      AND sp.spid != @@SPID;

WHILE 1 = 1
BEGIN
    SET ROWCOUNT 1;

    SELECT
          @processo_sem_cursor = l.spid
        , @nm_login_sem_cursor = SUSER_NAME(l.uid)
    FROM #t_logins AS l;

    IF @@ROWCOUNT = 0
    BEGIN
        BREAK;
    END;

    DELETE FROM #t_logins
    WHERE spid = @processo_sem_cursor;

    SET ROWCOUNT 0;

    SELECT
          @processo_sem_cursor AS Processo
        , @nm_login_sem_cursor AS Login;
END;

DROP TABLE #t_logins;

-- ============================================================
-- Observações sobre as abordagens:
--   1. Cursores são amplamente utilizados, mas consomem muitos
--      recursos do servidor (disco, CPU, memória).
--   2. A abordagem com tabela temporária e ROWCOUNT é uma
--      alternativa mais leve e performática.
--   3. Outra possibilidade é utilizar tabela temporária com
--      campo IDENTITY e varrer a tabela pelo ID incremental.
-- ============================================================
