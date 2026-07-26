/*
    OBJETIVO: Encerrar conexões fantasmas (sleeping com open_tran = 0) de processos de usuário,
              excluindo sessões originadas do servidor local, utilizando cursor para iteração
              sobre sys.sysprocesses e sys.dm_exec_sessions.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Encerramento de conexões fantasma via cursor
-- ============================================================

-- Declaração da variável para armazenar o comando KILL dinâmico
DECLARE @killspidpreza VARCHAR(30);

-- Cursor que identifica sessões sleeping sem transação aberta, de usuários,
-- excluindo conexões do próprio servidor
DECLARE kill_proc_preza CURSOR FOR
SELECT 
    'kill ' + CAST(t1.spid AS VARCHAR(10))
FROM sys.sysprocesses AS t1
INNER JOIN sys.dm_exec_sessions AS t2
    ON t1.spid = t2.session_id
WHERE t1.status = 'sleeping'
    AND t1.open_tran = 0
    AND t2.is_user_process = 1
    AND hostname <> 'CRVSQL01';

OPEN kill_proc_preza;

FETCH NEXT FROM kill_proc_preza INTO @killspidpreza;

WHILE @@FETCH_STATUS = 0
BEGIN
    EXECUTE (@killspidpreza);

    FETCH NEXT FROM kill_proc_preza INTO @killspidpreza;
END;

CLOSE kill_proc_preza;

DEALLOCATE kill_proc_preza;
