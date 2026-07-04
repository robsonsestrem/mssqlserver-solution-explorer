/*
    OBJETIVO:   Renomear banco de dados no SQL Server (Linux/Windows), incluindo
                nome lógico do banco, nomes lógicos dos arquivos e paths físicos.
    PROJETO:    mssqlserver-solution-explorer
*/

-- ---------------------------------------------------------------------------
-- Bloco 1: Renomeação rápida (SINGLE_USER ? MODIFY NAME ? MULTI_USER)
-- ---------------------------------------------------------------------------
USE [master];
GO

ALTER DATABASE H_HEALTHMAP_CAREPLUS_TDE SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE H_HEALTHMAP_CAREPLUS_TDE MODIFY NAME = QA1_HEALTHMAP_CAREPLUS_TDE;
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET MULTI_USER;
GO

-- ---------------------------------------------------------------------------
-- Bloco 2: Renomeação completa com OFFLINE/ONLINE e atualização de paths físicos
-- ---------------------------------------------------------------------------
USE [master];
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET OFFLINE;
GO

-- Altera os paths físicos dos datafiles
ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
    MODIFY FILE (Name = 'QA1_HEALTHMAP_CAREPLUS_TDE',     FILENAME = '/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE.mdf');
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
    MODIFY FILE (Name = 'QA1_HEALTHMAP_CAREPLUS_TDE_log', FILENAME = '/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE_log.ldf');
GO

-- Altera os nomes lógicos dos arquivos
USE [QA1_HEALTHMAP_CAREPLUS_TDE];
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME = N'P_HEALTHMAP',     NEWNAME = N'QA1_HEALTHMAP_CAREPLUS_TDE');
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME = N'P_HEALTHMAP_log', NEWNAME = N'QA1_HEALTHMAP_CAREPLUS_TDE_log');
GO

USE [master];
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET ONLINE;
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE SET MULTI_USER;
GO

-- ---------------------------------------------------------------------------
-- Bloco 3: Validação — verificar file_id, nome lógico e path físico atual
-- ---------------------------------------------------------------------------
USE [QA1_HEALTHMAP_CAREPLUS_TDE];
GO

SELECT
     file_id
    ,name          AS [logical_file_name]
    ,physical_name
FROM sys.database_files;
GO
-- Resultado esperado antes da renomeação dos arquivos físicos:
-- 1    P_HEALTHMAP         /var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE.mdf
-- 2    P_HEALTHMAP_log     /var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE_log.ldf

-- ---------------------------------------------------------------------------
-- Bloco 4: Step-by-step — guia sequencial completo de renomeação
-- ---------------------------------------------------------------------------

-- Passo 1: Altera o nome lógico do banco
USE [master];
GO

ALTER DATABASE H_HEALTHMAP_CAREPLUS_TDE MODIFY NAME = QA1_HEALTHMAP_CAREPLUS_TDE;
GO


-- Passo 2: Altera os nomes lógicos dos arquivos
USE [QA1_HEALTHMAP_CAREPLUS_TDE];
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME = N'P_HEALTHMAP',     NEWNAME = N'QA1_HEALTHMAP_CAREPLUS_TDE');
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE MODIFY FILE (NAME = N'P_HEALTHMAP_log', NEWNAME = N'QA1_HEALTHMAP_CAREPLUS_TDE_log');
GO


-- Passo 3: Altera os paths físicos dos datafiles
ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
    MODIFY FILE (Name = 'QA1_HEALTHMAP_CAREPLUS_TDE',     FILENAME = '/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE.mdf');
GO

ALTER DATABASE QA1_HEALTHMAP_CAREPLUS_TDE
    MODIFY FILE (Name = 'QA1_HEALTHMAP_CAREPLUS_TDE_log', FILENAME = '/var/opt/mssql/data/QA1_HEALTHMAP_CAREPLUS_TDE_log.ldf');
GO


-- Passo 4: Valide os resultados (* antes do Detach)
USE [QA1_HEALTHMAP_CAREPLUS_TDE];
GO

SELECT
     file_id
    ,name          AS [logical_file_name]
    ,physical_name
FROM sys.database_files;
GO


-- Passo 5: Altera fisicamente os nomes no servidor Linux
-- mv H_HEALTHMAP_CAREPLUS_TDE.mdf     QA1_HEALTHMAP_CAREPLUS_TDE.mdf
-- mv H_HEALTHMAP_CAREPLUS_TDE_log.ldf QA1_HEALTHMAP_CAREPLUS_TDE_log.ldf


-- Passo 6: Attach
