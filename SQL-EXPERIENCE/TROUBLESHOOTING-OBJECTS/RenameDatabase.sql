USE master;  
GO  
--ALTER DATABASE H_HEALTHMAP_CAREPLUS_TDE SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
--GO
ALTER DATABASE H_HEALTHMAP_CAREPLUS_TDE MODIFY NAME = QA1_HEALTHMAP_CAREPLUS_TDE;
GO  
--ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET MULTI_USER;
--GO


--------------------------------------------------------------------------------------------------------------------------------------------
--USE [master];
--GO
--ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
--SET SINGLE_USER WITH ROLLBACK IMMEDIATE
--GO
--ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET OFFLINE
--GO

-- altera datafiles
ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
MODIFY FILE (Name='QA1_HEALTHMAP_CAREPLUS_TDE', FILENAME='/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE.mdf')
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
MODIFY FILE (Name='QA1_HEALTHMAP_CAREPLUS_TDE_log', FILENAME='/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE_log.ldf')
GO

-- altera nome lógico
USE QA1_HEALTHMAP_CAREPLUS_TDE
GO
ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME=N'P_HEALTHMAP', NEWNAME=N'QA1_HEALTHMAP_CAREPLUS_TDE')
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME=N'P_HEALTHMAP_log', NEWNAME=N'QA1_HEALTHMAP_CAREPLUS_TDE_log')
GO

--USE [master];
--GO
--ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET ONLINE
--GO
--ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET MULTI_USER
--GO
--------------------------------------------------------------------------------------------------------------------------------------------

USE QA1_HEALTHMAP_CAREPLUS_TDE
GO
SELECT file_id, name as [logical_file_name], physical_name
FROM sys.database_files
GO
-- 1	P_HEALTHMAP			/var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE.mdf
-- 2	P_HEALTHMAP_log		/var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE_log.ldf


--------------------------------------------------------------------------------------------------------------------------------------------
-- step by step
--------------------------------------------------------------------------------------------------------------------------------------------
-- 1.
-- altera nome de base
USE master;  
GO
ALTER DATABASE H_HEALTHMAP_CAREPLUS_TDE MODIFY NAME = QA1_HEALTHMAP_CAREPLUS_TDE;
GO 


-- 2.
-- altera nome lógico
USE QA1_HEALTHMAP_CAREPLUS_TDE
GO
ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME=N'P_HEALTHMAP', NEWNAME=N'QA1_HEALTHMAP_CAREPLUS_TDE')
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME=N'P_HEALTHMAP_log', NEWNAME=N'QA1_HEALTHMAP_CAREPLUS_TDE_log')
GO


-- 3.
-- altera datafiles
ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
MODIFY FILE (Name='QA1_HEALTHMAP_CAREPLUS_TDE', FILENAME='/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE.mdf')
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
MODIFY FILE (Name='QA1_HEALTHMAP_CAREPLUS_TDE_log', FILENAME='/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE_log.ldf')
GO


-- 4. 
-- valide os resultados
USE QA1_HEALTHMAP_CAREPLUS_TDE
GO
SELECT file_id, name as [logical_file_name], physical_name
FROM sys.database_files
GO


-- 4. 
-- * detach


-- 5.
-- altera fisicamente os nomes no Server
-- mv H_HEALTHMAP_CAREPLUS_TDE.mdf QA1_HEALTHMAP_CAREPLUS_TDE.mdf
-- mv H_HEALTHMAP_CAREPLUS_TDE_log.ldf QA1_HEALTHMAP_CAREPLUS_TDE_log.ldf


-- 6.
-- * attach



