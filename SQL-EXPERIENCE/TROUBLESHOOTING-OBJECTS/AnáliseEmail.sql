/*
    OBJETIVO: Identificar e-mails com falha de envio via Database Mail e consultar
              a view de monitoramento de e-mails do banco YOUR_DATABASE.
    PROJETO: mssqlserver-solution-explorer
    REFERÊNCIA: https://www.mssqltips.com/sqlservertip/1100/setting-up-database-mail-for-sql-server/
*/

-- ---------------------------------------------------------------------------
-- Bloco 1: E-mails com falha de envio nos últimos N dias (sysmail_faileditems)
-- ---------------------------------------------------------------------------
DECLARE @DaysBack INT = 2;

SELECT *
FROM msdb.dbo.sysmail_faileditems
WHERE sent_date > DATEADD(dd, ABS(@DaysBack) * -1, SYSDATETIME());

-- ---------------------------------------------------------------------------
-- Bloco 2: Consulta à view de monitoramento de e-mails enviados
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

SELECT *
FROM Management.vw_MonitoringEmail
WHERE DataEnvio BETWEEN '20170623 00:00:00.000' AND '20170623 23:59:59.997';

