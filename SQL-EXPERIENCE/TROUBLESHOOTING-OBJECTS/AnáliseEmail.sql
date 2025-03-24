---------------------------------------------------------------------------------------------------------------------------
-- Purpose: This query will show messages that failed to send via DBMail.  Are there any alerts that should have gone out that didn't?
--          https://www.mssqltips.com/sqlservertip/1100/setting-up-database-mail-for-sql-server/

DECLARE @DaysBack INT = 2;

SELECT 
  * 
FROM 
  msdb.dbo.sysmail_faileditems
WHERE 
  sent_date > DATEADD(dd, ABS(@DaysBack) * -1, SYSDATETIME());


---------------------------------------------------------------------------------------------------------------------------
-- View de monitoramento
---------------------------------------------------------------------------------------------------------------------------
use Maintenance
go

select * from Management.vw_MonitoringEmail
where DataEnvio between '20170623 00:00:00.000' and '20170623 23:59:59.997'

