/*
    OBJETIVO: Restauração de bases de dados protegidas por TDE (Transparent Data
              Encryption) em um servidor de destino. Inclui criação da Database
              Master Key, restauração do certificado e da chave privada provenientes
              do servidor de origem, restore do backup criptografado com WITH MOVE,
              e verificação completa do estado de criptografia após o restore.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://learn.microsoft.com/en-us/sql/relational-databases/security/encryption/move-a-tde-protected-database-to-another-sql-server?view=sql-server-ver17
    https://www.dirceuresende.com/blog/sql-server-2008-como-criptografar-seus-dados-utilizando-transparent-data-encryption-tde/
    https://www.mssqltips.com/sqlservertip/5009/updating-an-expired-sql-server-tde-certificate/
*/

-- ###########################################################
-- # SERVIDOR DE DESTINO: RESTAURAÇÃO DE BASE COM TDE       #
-- ###########################################################

-- ============================================================
-- Passo 1: Verificação do estado inicial do servidor de destino
-- ============================================================

-- Antes de iniciar, verifica se já existe uma Master Key, certificados
-- ou bases criptografadas no servidor de destino. Isso evita conflitos
-- com objetos pré-existentes.
USE [master]
;
GO

SELECT
    *
FROM sys.symmetric_keys
;

SELECT
    *
FROM sys.certificates
;

SELECT
    DB_NAME(database_id) AS DbName
    , encryption_state
    , encryptor_type
FROM sys.dm_database_encryption_keys
;
GO

-- ============================================================
-- Passo 2: Criação ou regeneração da Database Master Key (DMK)
-- ============================================================

-- A DMK no database master é obrigatória para proteger o certificado
-- que será restaurado do servidor de origem.
-- Se já existir uma DMK e for necessário recriá-la, faça backup antes
-- de regenerar. Se não existir, crie uma nova.

USE [master]
;
GO

-- Se já existe uma DMK e precisa recriá-la:
-- 1. Faça backup da DMK atual (recomendado)
-- 2. Regenera a DMK com nova senha
BACKUP MASTER KEY
    TO FILE = N'/opt/backups_sql/MasterKey_Destino_Backup.bak'
    ENCRYPTION BY PASSWORD = '021J4qGca*R00spI'
;
GO

ALTER MASTER KEY REGENERATE
    WITH ENCRYPTION BY PASSWORD = '021J4qGca*R00spI'
;
GO

-- Se NÃO existe uma DMK, use CREATE em vez de REGENERATE:
-- CREATE MASTER KEY ENCRYPTION BY PASSWORD = '021J4qGca*R00spI'
-- GO

-- ============================================================
-- Passo 3: Verificação da DMK criada/regenerada
-- ============================================================

-- Confirma que a DMK foi criada com sucesso no database master
-- antes de prosseguir para a restauração do certificado.
USE [master]
;
GO

SELECT
    name
    , principal_id
    , key_length
    , algorithm_desc
FROM sys.symmetric_keys
WHERE name = '##MS_DatabaseMasterKey##'
;
GO

-- ============================================================
-- Passo 4: Restauração do certificado e da chave privada
-- ============================================================

-- O certificado e a chave privada foram exportados do servidor de origem
-- (ver Passo A3 do script ConfigTdeSqlServerOrigem). Sem esses dois arquivos,
-- o RESTORE DATABASE falhará com o erro:
-- "Cannot find server certificate with thumbprint '...'"
-- O certificado deve ser restaurado no database master do servidor de destino.

USE [master]
;
GO

-- Restaura o certificado principal (certificado ativo no servidor de origem)
CREATE CERTIFICATE TDE_YOUR_OBJECT_HMG_Certicate
    FROM FILE = N'/home/remote/TDE_YOUR_OBJECT_HMG_Certicate.cer'
    WITH PRIVATE KEY (
        FILE = N'/home/remote/TDE_YOUR_OBJECT_HMG_Key.pvk'
        , DECRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
    )
;
GO

-- (Opcional) Restaura o certificado antigo, se necessário restaurar
-- backups mais antigos criptografados com o certificado anterior.
-- CREATE CERTIFICATE TDE_YOUR_OBJECT_Certicate_Old
--     FROM FILE = N'/home/remote/TDE_YOUR_OBJECT_Certicate_Old.cer'
--     WITH PRIVATE KEY (
--         FILE = N'/home/remote/TDE_YOUR_OBJECT_Key_Old.pvk'
--         , DECRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
--     )
-- ;
-- GO

-- ============================================================
-- Passo 5: Verificação do certificado restaurado
-- ============================================================

-- Confirma que o certificado foi criado com sucesso e que a chave privada
-- está acessível. Se a chave privada não estiver acessível, o restore
-- da base falhará.
USE [master]
;
GO

SELECT
    name
    , certificate_id
    , principal_id
    , pvt_key_encryption_type_desc
    , subject
    , expiry_date
    , thumbprint
FROM sys.certificates
;
GO

-- ============================================================
-- Passo 6: Identificação dos nomes lógicos dos arquivos do backup
-- ============================================================

-- Antes do RESTORE DATABASE, é necessário identificar os nomes lógicos
-- dos arquivos de dados e de log contidos no backup, para usar na
-- cláusula WITH MOVE. Substitua o caminho pelo local do arquivo .bak.
RESTORE FILELISTONLY
    FROM DISK = N'/home/remote/H_YOUR_DATABASE_TDE.bak'
;
GO

-- ============================================================
-- Passo 7: Restore do banco de dados criptografado
-- ============================================================

-- O RESTORE DATABASE preserva a criptografia TDE dos dados em repouso.
-- Os nomes lógicos (LogicalName) obtidos no Passo 6 devem corresponder
-- exatamente aos nomes dentro do backup. Os caminhos físicos (PhysicalName)
-- devem apontar para o diretório de dados do servidor de destino.
-- A opção STATS = 5 exibe o progresso a cada 5% concluído.

USE [master]
;
GO

RESTORE DATABASE [H_YOUR_DATABASE_TDE]
    FROM DISK = N'/home/remote/H_YOUR_DATABASE_TDE.bak'
    WITH FILE = 1
    , MOVE N'P_YOUR_DATABASE' TO N'/var/opt/mssql/data/H_YOUR_DATABASE_TDE.mdf'
    , MOVE N'P_YOUR_DATABASE_log' TO N'/var/opt/mssql/data/H_YOUR_DATABASE_TDE_log.ldf'
    , NOUNLOAD
    , REPLACE
    , STATS = 5
;
GO

-- ============================================================
-- Passo 8: Verificação do estado de criptografia após o restore
-- ============================================================

-- Após o restore, a base deve aparecer com encryption_state = 3 (criptografado)
-- e o certificado vinculado deve ser o mesmo restaurado no Passo 4.
-- Valores de encryption_state:
--   0 = sem DEK, 1 = descriptografado, 2 = scan em andamento,
--   3 = criptografado, 4 = alteração de chave em progresso,
--   5 = alteração de proteção em progresso, 6 = alteração de proteção em progresso

USE [master]
;
GO

SELECT
    DB_NAME(db.database_id) AS DbName
    , db.encryption_state
    , db.encryptor_type
    , cer.name AS CertificateName
    , cer.expiry_date
    , cer.subject
FROM sys.dm_database_encryption_keys AS db
INNER JOIN sys.certificates AS cer
    ON db.encryptor_thumbprint = cer.thumbprint
;
GO

-- Visão alternativa: cruzamento com sys.databases para verificar
-- as flags is_encrypted e is_master_key_encrypted_by_server
SELECT
    A.[name]
    , A.is_master_key_encrypted_by_server
    , A.is_encrypted
    , B.encryption_state
    , B.encryptor_type
FROM sys.databases AS A
INNER JOIN sys.dm_database_encryption_keys AS B
    ON B.database_id = A.database_id
;
GO

-- ============================================================
-- Passo 9: Backup do certificado no servidor de destino
-- ============================================================

-- Após restaurar o certificado no servidor de destino, é obrigatório
-- fazer backup dele neste servidor. Sem esse backup, se o database master
-- for corrompido ou o servidor precisar ser reconstruído, a base
-- criptografada será irrecuperável.
USE [master]
;
GO

BACKUP CERTIFICATE TDE_YOUR_OBJECT_HMG_Certicate
    TO FILE = N'/opt/backups_sql/TDE_YOUR_OBJECT_HMG_Certicate_Destino.cer'
    WITH PRIVATE KEY (
        FILE = N'/opt/backups_sql/TDE_YOUR_OBJECT_HMG_Key_Destino.pvk'
        , ENCRYPTION BY PASSWORD = '021J4qGca*R00spI'
    )
;
GO
