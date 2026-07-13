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

ALTER DATABASE ORIGINAL_NAME SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE ORIGINAL_NAME MODIFY NAME = UPDATED_NAME;
GO

ALTER DATABASE UPDATED_NAME SET MULTI_USER;
GO

-- ---------------------------------------------------------------------------
-- Bloco 2: Renomeação completa com OFFLINE/ONLINE e atualização de paths físicos
-- ---------------------------------------------------------------------------
USE [master];
GO

ALTER DATABASE UPDATED_NAME
    SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE UPDATED_NAME SET OFFLINE;
GO

-- Altera os paths físicos dos datafiles
ALTER DATABASE UPDATED_NAME
    MODIFY FILE (Name = 'UPDATED_NAME',     FILENAME = '/var/opt/mssql/data/UPDATED_NAME.mdf');
GO

ALTER DATABASE UPDATED_NAME
    MODIFY FILE (Name = 'UPDATED_NAME_log', FILENAME = '/var/opt/mssql/data/UPDATED_NAME_log.ldf');
GO

-- Altera os nomes lógicos dos arquivos
USE [UPDATED_NAME];
GO

ALTER DATABASE UPDATED_NAME MODIFY FILE (NAME = N'P_LOGICAL_NAME',     NEWNAME = N'UPDATED_NAME');
GO

ALTER DATABASE UPDATED_NAME MODIFY FILE (NAME = N'P_LOGICAL_NAME_log', NEWNAME = N'UPDATED_NAME_log');
GO

USE [master];
GO

ALTER DATABASE UPDATED_NAME SET ONLINE;
GO

ALTER DATABASE UPDATED_NAME SET MULTI_USER;
GO

-- ---------------------------------------------------------------------------
-- Bloco 3: Validação — verificar file_id, nome lógico e path físico atual
-- ---------------------------------------------------------------------------
USE [UPDATED_NAME];
GO

SELECT
     file_id
    ,name          AS [logical_file_name]
    ,physical_name
FROM sys.database_files;
GO
-- Resultado esperado antes da renomeação dos arquivos físicos:
-- 1    P_LOGICAL_NAME         /var/opt/mssql/data/ORIGINAL_NAME.mdf
-- 2    P_LOGICAL_NAME_log     /var/opt/mssql/data/H_LOGICAL_NAME_YOUR_OBJECT_TDE_log.ldf

-- ---------------------------------------------------------------------------
-- Bloco 4: Step-by-step — guia sequencial completo de renomeação
-- ---------------------------------------------------------------------------

-- Passo 1: Altera o nome lógico do banco
USE [master];
GO

ALTER DATABASE ORIGINAL_NAME MODIFY NAME = UPDATED_NAME;
GO


-- Passo 2: Altera os nomes lógicos dos arquivos
USE [UPDATED_NAME];
GO

ALTER DATABASE UPDATED_NAME MODIFY FILE (NAME = N'P_LOGICAL_NAME',     NEWNAME = N'UPDATED_NAME');
GO

ALTER DATABASE UPDATED_NAME MODIFY FILE (NAME = N'P_LOGICAL_NAME_log', NEWNAME = N'UPDATED_NAME_log');
GO


-- Passo 3: Altera os paths físicos dos datafiles
ALTER DATABASE UPDATED_NAME
    MODIFY FILE (Name = 'UPDATED_NAME',     FILENAME = '/var/opt/mssql/data/UPDATED_NAME.mdf');
GO

ALTER DATABASE UPDATED_NAME
    MODIFY FILE (Name = 'UPDATED_NAME_log', FILENAME = '/var/opt/mssql/data/UPDATED_NAME_log.ldf');
GO


-- Passo 4: Valide os resultados (* antes do Detach)
USE [UPDATED_NAME];
GO

SELECT
     file_id
    ,name          AS [logical_file_name]
    ,physical_name
FROM sys.database_files;
GO


-- Passo 5: Altera fisicamente os nomes no servidor Linux
-- mv ORIGINAL_NAME.mdf     UPDATED_NAME.mdf
-- mv H_LOGICAL_NAME_YOUR_OBJECT_TDE_log.ldf UPDATED_NAME_log.ldf


-- Passo 6: Attach
