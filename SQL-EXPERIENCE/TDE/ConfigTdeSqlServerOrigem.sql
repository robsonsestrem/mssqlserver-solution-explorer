USE master
GO
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- RESTORE
-- https://www.dirceuresende.com/blog/sql-server-2008-como-criptografar-seus-dados-utilizando-transparent-data-encryption-tde/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Run this on destination server to create the database master key 
--CREATE MASTER KEY ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
--GO

ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
GO

-- Restoring the certificate and the private key on destination server
--CREATE CERTIFICATE TDE_Careplus_Cert  
--  FROM FILE = N'/home/remote/TDE_Careplus_Cert.cer' -- MS_AgentSigningCertificate.cer
--  WITH PRIVATE KEY ( 
--    FILE = N'/home/remote/TDE_Careplus_Cert_Key.pvk',
--  DECRYPTION BY PASSWORD = 'DP5PdqbgfqG7MHsK'
--  );
--GO

USE [master]
GO
SELECT * FROM sys.symmetric_keys

select * from sys.certificates


SELECT db_name(database_id), encryption_state
FROM sys.dm_database_encryption_keys


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Passos para ativação da TDE em uma base de dados
-- https://learn.microsoft.com/pt-br/sql/relational-databases/security/encryption/transparent-data-encryption?view=sql-server-ver16
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--1. Crie uma chave mestra.
--2. Crie ou obtenha um certificado protegido pela chave mestra.
--3. Crie uma chave de criptografia de banco de dados e proteja-a usando o certificado.
--4. Defina o banco de dados para usar criptografia.
USE master;
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<UseStrongPasswordHere>';
GO
CREATE CERTIFICATE MyServerCert WITH SUBJECT = 'My DEK Certificate';
GO
USE AdventureWorks2012;
GO
CREATE DATABASE ENCRYPTION KEY
WITH ALGORITHM = AES_256
ENCRYPTION BY SERVER CERTIFICATE MyServerCert;
GO
ALTER DATABASE AdventureWorks2012
SET ENCRYPTION ON;
GO


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VISUALIZAR ANDAMENTO DO SCAN POR ALTERAÇÕES EM UMA BASE COM "SET ENCRYPTION ON|OFF"
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    A.[name], 
    A.is_master_key_encrypted_by_server, 
    A.is_encrypted,
    B.*
FROM sys.databases A
JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ALTERAR CERTIFICADO VINCULADO A BASE DE DADOS
-- https://www.mssqltips.com/sqlservertip/5009/updating-an-expired-sql-server-tde-certificate/
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [master]
GO

CREATE CERTIFICATE TDE_Careplus_HMG_Certicate
WITH SUBJECT = 'TDE DEK Certificate Careplus HMG',
EXPIRY_DATE = '20251231';
GO 

-- Cannot change database encryption key while an encryption, decryption, or key change scan is in progress.
-- Caso tenha alterado a base "SET ENCRYPTION ON|OFF", vai ter que esperar o scan e leva em média 2 horas.
-- Warning: The certificate used for encrypting the database encryption key has not been backed up. 
-- You should immediately back up the certificate and the private key associated with the certificate. 
-- If the certificate ever becomes unavailable or if you must restore or attach the database on another server, 
-- you must have backups of both the certificate and the private key or you will not be able to open the database.
-- Completion time: 2023-03-31T07:43:21.7104077-03:00
USE H_HEALTHMAP_CAREPLUS_TDE
GO
ALTER DATABASE ENCRYPTION KEY
ENCRYPTION BY SERVER CERTIFICATE TDE_Careplus_HMG_Certicate;
GO


-- Se você verificar a vinculação do certificado agora, verá que a DEK agora está vinculada ao novo certificado.
USE [master]
GO
SELECT
DB_NAME(db.database_id) DbName, db.encryption_state
, encryptor_type, cer.name, cer.expiry_date, cer.subject
FROM sys.dm_database_encryption_keys db
JOIN sys.certificates cer 
ON db.encryptor_thumbprint = cer.thumbprint
GO


USE [master]
GO
-- Realiza o backup -> Certifique-se de que o nome do arquivo de certificado e o nome do arquivo de chave privada sejam diferentes.
BACKUP CERTIFICATE TDE_Careplus_HMG_Certicate 
TO FILE =  N'/opt/backups_sql/TDE_Careplus_HMG_Certicate.cer'			-- cria o novo arquivo do certificado
WITH PRIVATE KEY ( FILE = N'/opt/backups_sql/TDE_Careplus_HMG_Key.pvk', -- cria o novo arquivo da chave privada
ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q' );
GO


USE [master]
GO
-- Realiza o backup -> Certifique-se de que o nome do arquivo de certificado e o nome do arquivo de chave privada sejam diferentes.
BACKUP CERTIFICATE TDE_Careplus_Cert 
TO FILE =  N'/opt/backups_sql/TDE_Careplus_Certicate_Old.cer'			-- cria o novo arquivo do certificado
WITH PRIVATE KEY ( FILE = N'/opt/backups_sql/TDE_Careplus_Key_Old.pvk', -- cria o novo arquivo da chave privada
ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q' );
GO



BACKUP DATABASE [H_HEALTHMAP_CAREPLUS_TDE] 
TO DISK = N'/var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE.bak' 
WITH NOFORMAT
, NOINIT
, NAME = N'H_HEALTHMAP_CAREPLUS_TDE-Full Database Backup'
, SKIP
, NOREWIND
, STATS = 5


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Buscando por "Database encryption scan for database 'H_HEALTHMAP_CAREPLUS_TDE' is complete"
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
declare @logs table(
data datetime,
ProcessInfo VARCHAR(50),
Text VARCHAR(4000) 
)
insert into @logs
exec sp_readerrorlog; -- função interna

select * from @logs as l
where l.data >= '20230403 00:00:00.000'
and l.data < '20230404 00:00:00.000'
--and l.Text like '%erro%'
order by l.data desc


