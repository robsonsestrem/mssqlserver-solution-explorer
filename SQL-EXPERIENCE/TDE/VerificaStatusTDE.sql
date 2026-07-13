-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Processamentos com a criptografia
-----------------------------------------------------------------------------------------------------------------------------------------------------
USE [master]
GO
ALTER DATABASE P_YOUR_DATABASE_TDE
SET ENCRYPTION OFF -- ON|OFF
GO

-- suspende o processo de criptografia
ALTER DATABASE H_YOUR_DATABASE_TDE SET ENCRYPTION SUSPEND;

-- retoma o processo de criptografia
ALTER DATABASE H_YOUR_DATABASE_TDE SET ENCRYPTION RESUME;


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VISUALIZAR ANDAMENTO DO SCAN POR ALTERAÇÕES EM UMA BASE COM "SET ENCRYPTION ON|OFF"
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    A.[name], 
    A.is_master_key_encrypted_by_server, 
    A.is_encrypted,
    B.database_id
   , CASE B.encryption_state 
      WHEN 0 THEN 'No database encryption key present, no encryption'
      WHEN 1 THEN 'Unencrypted'
      WHEN 2 THEN 'Encryption in progress'
      WHEN 3 THEN 'Encrypted'
      WHEN 4 THEN 'Key change in progress'
      WHEN 5 THEN 'Decryption in progress'
      WHEN 6 THEN 'Protection change in progress (The certificate or asymmetric key that is encrypting the database encryption key is being changed.)'      
     END AS encryption_state
   ,B.create_date
   ,B.regenerate_date
   ,B.modify_date
   ,B.set_date
   ,B.opened_date
   ,B.key_algorithm
   ,B.key_length
   ,B.encryptor_thumbprint
   ,B.encryptor_type
   ,B.percent_complete
   ,B.encryption_state_desc
   ,B.encryption_scan_state
   ,B.encryption_scan_state_desc
   ,B.encryption_scan_modify_date
FROM sys.databases A
JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------- VERSÃO MAIS COMPLETA ----------------------------------------
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    A.[name] AS database_name,
    A.is_master_key_encrypted_by_server,
    A.is_encrypted,        
    B.database_id,
    CASE B.encryption_state 
        WHEN 0 THEN 'No database encryption key present, no encryption'
        WHEN 1 THEN 'Unencrypted'
        WHEN 2 THEN 'Encryption in progress'
        WHEN 3 THEN 'Encrypted'
        WHEN 4 THEN 'Key change in progress'
        WHEN 5 THEN 'Decryption in progress'
        WHEN 6 THEN 'Protection change in progress (certificate/asymmetric key change)'
        ELSE 'Unknown (' + CAST(B.encryption_state AS VARCHAR(10)) + ')'
    END AS encryption_state_desc,
    B.encryption_state AS encryption_state_raw,  -- Valor original para depuração    
    --
    CASE B.key_algorithm
        WHEN 'DES' THEN 'DES (Data Encryption Standard - obsoleto, evite)'
        WHEN 'TRIPLE_DES' THEN 'Triple DES (3DES - obsoleto, evite)'
        WHEN 'AES_128' THEN 'AES 128-bit'
        WHEN 'AES_192' THEN 'AES 192-bit'
        WHEN 'AES_256' THEN 'AES 256-bit (recomendado para Enterprise)'
        ELSE ISNULL(B.key_algorithm, 'N/A')
    END AS key_algorithm_desc,
    --
    B.key_algorithm AS key_algorithm_raw,
    B.key_length,
    --
    CASE B.encryptor_type
        WHEN 'SERVICE_MASTER_KEY' THEN 'Service Master Key (SMK - mais simples, mas menos seguro)'
        WHEN 'CERTIFICATE' THEN 'Certificate (recomendado para HA/DR)'
        WHEN 'ASYMMETRIC_KEY' THEN 'Asymmetric Key'
        ELSE ISNULL(B.encryptor_type, 'N/A')
    END AS encryptor_type_desc,
    --
    B.encryptor_type AS encryptor_type_raw,
    B.encryptor_thumbprint,        
    B.create_date,
    B.regenerate_date,
    B.modify_date,
    B.set_date,
    B.opened_date,
    B.percent_complete,
    --
    CASE B.encryption_scan_state
        WHEN 0 THEN 'Scan not started'
        WHEN 1 THEN 'Scan initialized'
        WHEN 2 THEN 'Scan running'
        WHEN 3 THEN 'Scan finished'
        WHEN 4 THEN 'Scan paused'
        ELSE 'Unknown (' + CAST(B.encryption_scan_state AS VARCHAR(10)) + ')'
    END AS encryption_scan_state_desc,
    --
    B.encryption_scan_state AS encryption_scan_state_raw,
    B.encryption_scan_state_desc AS encryption_scan_state_desc_original,
    B.encryption_scan_modify_date

FROM sys.databases A
INNER JOIN sys.dm_database_encryption_keys B ON B.database_id = A.database_id

-- WHERE A.is_encrypted = 1  -- Apenas DBs criptografados
-- WHERE B.encryption_state IN (2, 5)  -- Apenas em progresso (encryption/decryption)

ORDER BY A.[name];


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Não é possível alterar a chave de criptografia do banco de dados enquanto uma verificação de criptografia, descriptografia ou alteração de chave estiver em andamento.
-- Caso tenha alterado a base "SET ENCRYPTION ON|OFF", terá que esperar o scan e levará em média 2 horas.
-- Faça backup do certificado e da chave privada associada a ele.
-- Se o certificado ficar indisponível ou se você precisar restaurar ou conectar o banco de dados em outro servidor,
-- você deverá ter backups tanto do certificado quanto da chave privada, caso contrário, não será possível abrir o banco de dados.
--
-- Como associar um certificado a uma base de dados criptografada:
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE H_YOUR_DATABASE_TDE
GO

ALTER DATABASE ENCRYPTION KEY
ENCRYPTION BY SERVER CERTIFICATE TDE_YOUR_OBJECT_HMG_Certicate;
GO


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Verificar a vinculação do certificado na Base de Dados
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [master]
GO

SELECT
  DB_NAME(db.database_id) DbName
, db.encryption_state
, encryptor_type
, cer.name
, cer.expiry_date
, cer.subject
FROM sys.dm_database_encryption_keys db
JOIN sys.certificates cer 
ON db.encryptor_thumbprint = cer.thumbprint
GO


