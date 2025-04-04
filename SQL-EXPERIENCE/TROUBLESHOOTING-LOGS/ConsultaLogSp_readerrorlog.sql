DECLARE @logs TABLE (
    data DATETIME
   ,ProcessInfo VARCHAR(50)
   ,Text VARCHAR(4000)
)
INSERT INTO @logs
EXEC sys.sp_readerrorlog @p1 = 0    -- É o valor inteiro (int) do log que você deseja exibir. O log de erros atual tem um valor de 0, o anterior é 1 (Errorlog.1), o anterior é 2 (Errorlog.2) e assim por diante.
                        ,@p2 = NULL -- 1 ou NULL = Log de Erro, 2 = Log do SQL Agent
                        ,@p3 = N''  -- primeira string que deseja buscar
                        ,@p4 = N''; -- segunda string para refinar a busca

SELECT
    l.data
   ,l.ProcessInfo
   ,l.Text
FROM @logs AS l
WHERE l.data >= '20250401 06:00:00.000' AND l.data <= '20250401 10:00:00.000'
--AND l.data <= '20240507 23:59:59.997'
--AND l.[Text] NOT LIKE '%Login failed%' AND l.[Text] NOT LIKE '%Error: 18456, Severity: 14, State: 8.%' -- Login failed; Error: 18456, Severity: 14, State: 8.; Process ID 823 was killed by hostname HMNOT005, host process ID 15956;
--AND l.Text LIKE '%was killed%'
--AND l.Text NOT LIKE '%Error: 18456%'
-- 
--AND l.Text LIKE '%was killed%' -- Operating system error 31
ORDER BY l.data DESC


-- EXEMPLO COM MAIS PARÂMETROS E ORDENAÇÃO
-- EXEC master.dbo.xp_readerrorlog 0, 1, N'backup', N'failed', NULL, NULL, N'asc'

/* 
 * QUANDO É ALTERADO CPU
 * SQL Server detected 1 sockets with 4 cores per socket and 8 logical processors per socket, 8 total logical processors; using 8 logical processors based on SQL Server licensing. This is an informational message; no user action is required.
 */





