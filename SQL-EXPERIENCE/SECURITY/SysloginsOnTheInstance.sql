/*
 *
	OBJETIVO: Consulta para identificar todos os membros do role de servidor sysadmin
			  na instância do SQL Server, auxiliando na auditoria de segurança
			  e verificação de privilégios administrativos.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/
 */
-- ============================================================
-- Lista todos os logins que são membros do role sysadmin
-- ============================================================
SELECT
    [name]
FROM sys.syslogins
WHERE IS_SRVROLEMEMBER('sysadmin', name) = 1
GO
