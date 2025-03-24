DECLARE @logs TABLE (
    data DATETIME
   ,ProcessInfo VARCHAR(50)
   ,Text VARCHAR(4000)
)
INSERT INTO @logs
EXEC sp_readerrorlog; -- função interna

SELECT
    *
FROM @logs AS l
WHERE l.data >= '20250310 06:00:00.000' AND l.data <= '20250310 16:00:00.000'
--AND l.data <= '20240507 23:59:59.997'
--AND l.[Text] NOT LIKE '%Login failed%' AND l.[Text] NOT LIKE '%Error: 18456, Severity: 14, State: 8.%' -- Login failed; Error: 18456, Severity: 14, State: 8.; Process ID 823 was killed by hostname HMNOT005, host process ID 15956;
AND l.Text LIKE '%was killed%'
--AND l.Text NOT LIKE '%Error: 18456%'
-- 
ORDER BY l.data DESC




