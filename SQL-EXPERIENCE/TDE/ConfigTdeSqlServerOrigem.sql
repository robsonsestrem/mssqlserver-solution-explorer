/*
    OBJETIVO: Configuração completa de Transparent Data Encryption (TDE) no SQL Server,
              dividida em dois cenários distintos:
              Cenário A: Servidor já possui TDE ativo e precisa preparar as bases
                         para migração a outro servidor (verificação, backup de
                         certificado, chave privada e do banco criptografado).
              Cenário B: Criação de TDE do zero em um servidor, incluindo Master Key,
                         certificado, Database Encryption Key (DEK), ativação de
                         criptografia, monitoramento do scan, backup obrigatório do
                         certificado e procedimento de troca de certificado vinculado.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://www.dirceuresende.com/blog/sql-server-2008-como-criptografar-seus-dados-utilizando-transparent-data-encryption-tde/
    https://learn.microsoft.com/pt-br/sql/relational-databases/security/encryption/transparent-data-encryption?view=sql-server-ver16
    https://www.mssqltips.com/sqlservertip/5009/updating-an-expired-sql-server-tde-certificate/
*/

-- ###########################################################
-- # CENÁRIO A: SERVIDOR COM TDE JÁ CONFIGURADO             #
-- # Preparação das bases para migração a outro servidor    #
-- ###########################################################

-- ============================================================
-- Passo A1: Verificação do estado atual da criptografia
-- ============================================================

-- Identifica quais bases possuem TDE ativo, qual certificado está vinculado,
-- o estado da criptografia e o percentual de conclusão do scan.
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
    , db.percent_complete
    , db.encryptor_type
    , cer.name AS CertificateName
    , cer.expiry_date
    , cer.subject
FROM sys.dm_database_encryption_keys AS db
INNER JOIN sys.certificates AS cer
    ON db.encryptor_thumbprint = cer.thumbprint
;
GO

-- Verifica se as bases estão marcadas como criptografadas em sys.databases
-- e se a Master Key do servidor está protegida
SELECT
    A.[name]
    , A.is_master_key_encrypted_by_server
    , A.is_encrypted
    , B.encryption_state
    , B.percent_complete
FROM sys.databases AS A
INNER JOIN sys.dm_database_encryption_keys AS B
    ON B.database_id = A.database_id
;
GO

-- Lista as chaves simétricas e certificados existentes no database master
-- para confirmar que a DMK e o certificado TDE estão presentes
SELECT
    *
FROM sys.symmetric_keys
;

SELECT
    *
FROM sys.certificates
;
GO

-- ============================================================
-- Passo A2: (Opcional) Backup e regeneração da 
-- Database Master Key
-- ============================================================

-- ATENÇÃO: A regeneração da DMK invalida todos os objetos criptografados
-- pela DMK anterior (credenciais, linked servers com senhas criptografadas,
-- outros certificados). Execute apenas se houver suspeita de comprometimento
-- da DMK ou como parte de uma política de rotação de chaves.
-- Antes de regenerar, faça backup da DMK atual.

USE [master]
;
GO

-- Backup da Master Key atual (recomendado antes de regenerar)
BACKUP MASTER KEY
    TO FILE = N'/opt/backups_sql/MasterKey_Backup.bak'
    ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
;
GO

ALTER MASTER KEY REGENERATE
    WITH ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
;
GO

-- ============================================================
-- Passo A3: Backup do certificado e da chave privada
-- ============================================================

-- O backup do certificado e da chave privada é obrigatório para restaurar
-- a base criptografada em outro servidor. Sem esses dois arquivos, a base
-- restaurada não poderá ser aberta e os dados serão inacessíveis.
-- Certifique-se de que o nome do arquivo de certificado (.cer) seja diferente
-- do nome do arquivo de chave privada (.pvk).

USE [master]
;
GO

-- Backup do certificado atualmente vinculado à base de origem
BACKUP CERTIFICATE TDE_YOUR_OBJECT_Cert
    TO FILE = N'/opt/backups_sql/TDE_YOUR_OBJECT_Certicate_Old.cer'
    WITH PRIVATE KEY (
        FILE = N'/opt/backups_sql/TDE_YOUR_OBJECT_Key_Old.pvk'
        , ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
    )
;
GO

-- ============================================================
-- Passo A4: Backup do banco de dados criptografado
-- ============================================================

-- O backup da base criptografada preserva a criptografia dos dados em repouso.
-- Para restaurar em outro servidor, será necessário o certificado e a chave
-- privada (Passo A3) no servidor de destino antes do RESTORE DATABASE.

BACKUP DATABASE [H_YOUR_DATABASE_TDE]
    TO DISK = N'/var/opt/mssql/data/H_YOUR_DATABASE_TDE.bak'
    WITH NOFORMAT
    , NOINIT
    , NAME = N'H_YOUR_DATABASE_TDE-Full Database Backup'
    , SKIP
    , NOREWIND
    , STATS = 5
;
GO

-- ============================================================
-- Passo A5: Verificação da conclusão do scan de criptografia
-- ============================================================

-- Após alterar o estado de criptografia (SET ENCRYPTION ON|OFF), o SQL Server
-- executa um scan assíncrono que percorre todas as páginas da base.
-- Durante o scan, não é possível alterar a DEK nem o certificado vinculado.
-- Busque por "Database encryption scan for database '...' is complete" no error log.
-- Completion time: 2023-03-31T07:43:21.7104077-03:00

DECLARE
    @logs TABLE (
        data DATETIME
        , ProcessInfo VARCHAR(50)
        , Text VARCHAR(4000)
    )
;

INSERT INTO @logs
EXEC sp_readerrorlog
;

SELECT
    *
FROM @logs AS l
WHERE l.data >= '20230403 00:00:00.000'
    AND l.data < '20230404 00:00:00.000'
    --AND l.Text LIKE '%erro%'
ORDER BY
    l.data DESC
;
GO

-- ###########################################################
-- # CENÁRIO B: CRIAÇÃO DE TDE DO ZERO EM UM SERVIDOR       #
-- ###########################################################

-- ============================================================
-- Resumo dos passos para ativação de TDE:
-- 1. Criar uma Database Master Key (DMK) no database master.
-- 2. Criar um certificado protegido pela DMK.
-- 3. Criar uma Database Encryption Key (DEK) protegida pelo certificado.
-- 4. Ativar a criptografia na base de dados (SET ENCRYPTION ON).
-- 5. Monitorar o scan de criptografia até conclusão.
-- 6. Fazer backup obrigatório do certificado e da chave privada.
-- ============================================================

-- ============================================================
-- Passo B1: Criação da Database Master Key (DMK)
-- ============================================================

-- A DMK é criada no database master e protege os certificados que serão
-- usados para proteger as DEKs das bases de dados.
-- Hierarquia de criptografia da TDE:
--   DPAPI → Service Master Key (SMK) → DMK → Certificado → DEK → Dados

USE master
;
GO

CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<UseStrongPasswordHere>'
;
GO

-- ============================================================
-- Passo B2: Criação do certificado protegido pela DMK
-- ============================================================

-- O certificado é usado para proteger a DEK da base de dados.
-- É recomendado definir uma data de expiração (EXPIRY_DATE) para forçar
-- a rotação periódica do certificado e evitar indisponibilidade.

USE master
;
GO

CREATE CERTIFICATE MyServerCert
    WITH SUBJECT = 'My DEK Certificate'
;
GO

-- ============================================================
-- Passo B3: Criação da Database Encryption Key (DEK)
-- ============================================================

-- A DEK é criada dentro da base de dados que será criptografada.
-- O algoritmo AES_256 oferece o nível mais alto de proteção disponível
-- na TDE do SQL Server.
-- A DEK é protegida (criptografada) pelo certificado criado no Passo B2.

USE AdventureWorks2012
;
GO

CREATE DATABASE ENCRYPTION KEY
    WITH ALGORITHM = AES_256
    ENCRYPTION BY SERVER CERTIFICATE MyServerCert
;
GO

-- ============================================================
-- Passo B4: Ativação da criptografia na base de dados
-- ============================================================

-- Após SET ENCRYPTION ON, o SQL Server inicia um scan assíncrono que
-- criptografa todas as páginas da base. A base permanece acessível
-- durante o processo, mas pode haver impacto de performance em I/O.
-- O scan é transparente para aplicações conectadas.

ALTER DATABASE AdventureWorks2012
    SET ENCRYPTION ON
;
GO

-- ============================================================
-- Passo B5: Monitoramento do scan de criptografia
-- ============================================================

-- O scan de criptografia é um processo assíncrono que percorre todas as
-- páginas da base. A coluna percent_complete mostra o progresso (0 a 100).
-- encryption_state = 2 indica que o scan está em andamento.
-- Quando concluído, encryption_state muda para 3 (criptografado) e
-- percent_complete retorna para 0.
-- O tempo de duração depende do tamanho da base e da velocidade de I/O.

USE [master]
;
GO

SELECT
    DB_NAME(db.database_id) AS DbName
    , db.encryption_state
    , db.percent_complete
    , db.encryptor_type
    , cer.name AS CertificateName
    , cer.expiry_date
FROM sys.dm_database_encryption_keys AS db
INNER JOIN sys.certificates AS cer
    ON db.encryptor_thumbprint = cer.thumbprint
;
GO

-- Visão alternativa: cruzamento com sys.databases para verificar
-- a flag is_encrypted e is_master_key_encrypted_by_server
SELECT
    A.[name]
    , A.is_master_key_encrypted_by_server
    , A.is_encrypted
    , B.encryption_state
    , B.percent_complete
FROM sys.databases AS A
INNER JOIN sys.dm_database_encryption_keys AS B
    ON B.database_id = A.database_id
;
GO

-- ============================================================
-- Passo B6: Backup obrigatório do certificado 
-- e da chave privada
-- ============================================================

-- Após ativar a TDE, é obrigatório fazer backup do certificado e da chave
-- privada. Sem esses arquivos, não é possível restaurar a base em outro
-- servidor nem recuperá-la após perda do database master.
-- Warning: The certificate used for encrypting the database encryption key
-- has not been backed up. You should immediately back up the certificate
-- and the private key associated with the certificate. If the certificate
-- ever becomes unavailable or if you must restore or attach the database
-- on another server, you must have backups of both the certificate and
-- the private key or you will not be able to open the database.

USE [master]
;
GO

BACKUP CERTIFICATE MyServerCert
    TO FILE = N'/opt/backups_sql/MyServerCert.cer'
    WITH PRIVATE KEY (
        FILE = N'/opt/backups_sql/MyServerCert_Key.pvk'
        , ENCRYPTION BY PASSWORD = '<UseStrongPasswordHere>'
    )
;
GO

-- ============================================================
-- Passo B7: (Opcional) Alteração do certificado vinculado à DEK
-- ============================================================

-- Quando o certificado se aproxima da data de expiração (EXPIRY_DATE),
-- é necessário criar um novo certificado e vincular a DEK a ele.
-- Pré-requisito: não pode haver scan de criptografia em andamento.
-- Caso tenha alterado "SET ENCRYPTION ON|OFF", aguarde o scan concluir
-- (em média 2 horas, dependendo do tamanho da base).
-- Cannot change database encryption key while an encryption, decryption,
-- or key change scan is in progress.

-- B7.1: Criar novo certificado com data de expiração definida
USE [master]
;
GO

CREATE CERTIFICATE TDE_YOUR_OBJECT_HMG_Certicate
    WITH SUBJECT = 'TDE DEK Certificate YOUR_OBJECT HMG'
    , EXPIRY_DATE = '20251231'
;
GO

-- B7.2: Vincular a DEK ao novo certificado
USE H_YOUR_DATABASE_TDE
;
GO

ALTER DATABASE ENCRYPTION KEY
    ENCRYPTION BY SERVER CERTIFICATE TDE_YOUR_OBJECT_HMG_Certicate
;
GO

-- B7.3: Verificar a nova vinculação do certificado
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

-- B7.4: Backup do novo certificado
-- Certifique-se de que o nome do arquivo de certificado (.cer) seja diferente
-- do nome do arquivo de chave privada (.pvk).
USE [master]
;
GO

BACKUP CERTIFICATE TDE_YOUR_OBJECT_HMG_Certicate
    TO FILE = N'/opt/backups_sql/TDE_YOUR_OBJECT_HMG_Certicate.cer'
    WITH PRIVATE KEY (
        FILE = N'/opt/backups_sql/TDE_YOUR_OBJECT_HMG_Key.pvk'
        , ENCRYPTION BY PASSWORD = '06TZMSXFcfFnX%8Q'
    )
;
GO

-- B7.5: Backup do banco de dados criptografado com o novo certificado
BACKUP DATABASE [H_YOUR_DATABASE_TDE]
    TO DISK = N'/var/opt/mssql/data/H_YOUR_DATABASE_TDE.bak'
    WITH NOFORMAT
    , NOINIT
    , NAME = N'H_YOUR_DATABASE_TDE-Full Database Backup'
    , SKIP
    , NOREWIND
    , STATS = 5
;
GO
