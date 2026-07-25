/*
	OBJETIVO: Restaurar backup completo da base de dados para um novo ambiente,
			  redefinindo os arquivos de dados (.mdf) e log (.ldf).
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Restauração da base de dados a partir de arquivo .bak
-- ============================================================
RESTORE DATABASE [H_YOUR_DATABASE_TDE]
FROM DISK = N'/home/remote/H_YOUR_DATABASE_TDE.bak'
WITH
	FILE = 1
  , MOVE N'P_YOUR_DATABASE'
		TO N'/var/opt/mssql/data/H_YOUR_DATABASE_TDE.mdf'
  , MOVE N'P_YOUR_DATABASE_log'
		TO N'/var/opt/mssql/data/H_YOUR_DATABASE_TDE_log.ldf'
  , NOUNLOAD
  , STATS = 5;
