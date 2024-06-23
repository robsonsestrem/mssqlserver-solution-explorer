USE master
GO

DROP MASTER KEY

ALTER MASTER KEY REGENERATE WITH ENCRYPTION BY PASSWORD = '021J4qGca*R00spI'
GO

USE [master]
GO
-- Restoring the certificate and the private key on destination server
CREATE CERTIFICATE TDE_Careplus_HMG_Certicate  
  FROM FILE = N'/home/remote/TDE_Careplus_HMG_Certicate.cer'
  WITH PRIVATE KEY ( 
    FILE = N'/home/remote/TDE_Careplus_HMG_Key.pvk',
  DECRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
  );
GO


--USE [master]
--GO
---- Restoring the certificate and the private key on destination server
--CREATE CERTIFICATE TDE_Careplus_Certicate_Old  
--  FROM FILE = N'/home/remote/TDE_Careplus_Certicate_Old.cer'
--  WITH PRIVATE KEY ( 
--    FILE = N'/home/remote/TDE_Careplus_Key_Old.pvk',
--  DECRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
--  );
--GO


select * from sys.symmetric_keys
select * from sys.certificates


-- restore -> script coletado
RESTORE DATABASE [H_HEALTHMAP_CAREPLUS_TDE] 
FROM  DISK = N'/home/remote/H_HEALTHMAP_CAREPLUS_TDE.bak' 
WITH  FILE = 1,  
MOVE N'P_HEALTHMAP' TO N'/var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE.mdf',  
MOVE N'P_HEALTHMAP_log' TO N'/var/opt/mssql/data/H_HEALTHMAP_CAREPLUS_TDE_log.ldf',  
NOUNLOAD,  STATS = 5


SELECT 
    A.[name], 
    A.is_master_key_encrypted_by_server, 
    A.is_encrypted,
    B.*
FROM sys.databases A
JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id


USE [master]
GO
SELECT
DB_NAME(db.database_id) DbName, db.encryption_state
, encryptor_type, cer.name, cer.expiry_date, cer.subject
FROM sys.dm_database_encryption_keys db
JOIN sys.certificates cer 
ON db.encryptor_thumbprint = cer.thumbprint