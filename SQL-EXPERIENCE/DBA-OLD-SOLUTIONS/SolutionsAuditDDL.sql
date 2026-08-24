/*
 *
    OBJETIVO: Solução de auditoria de eventos DDL no SQL Server usando Service Broker
              e Event Notification em nível de servidor, com retenção de dados,
              alternativa de trigger de banco e tabela simplificada.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  http://www.dbinternals.com.br/?p=1080
 *  https://www.davemason.me/2016/11/30/sql-server-event-handling%3A-event-notifications
 *  https://learn.microsoft.com/pt-br/sql/t-sql/functions/eventdata-transact-sql
 */
-- ============================================================
-- Contexto geral da solução
-- 1. A tabela Management.DDLTransaction armazena eventos DDL.
-- 2. Event Notification publica eventos DDL 
--    para o Service Broker.
-- 3. A procedure Management.sp_AlterObjects é ativada 
--    pela queue e lê as mensagens.
-- 4. Management.sp_DeleteHistoryDDL aplica retenção dos dados.
-- 5. O trigger de banco e a tabela "dedo duro" 
--    são alternativas simplificadas.
-- ============================================================

-- ============================================================
-- Criação da tabela de auditoria DDL no banco DBA_PerformanceHub
-- ============================================================
USE DBA_PerformanceHub;
GO

CREATE TABLE Management.DDLTransaction
(
    TransID INT IDENTITY(1,1) NOT NULL
  , DateDDl SMALLDATETIME NULL DEFAULT GETDATE()
  , PostTime NVARCHAR(200) NULL
  , SPID NVARCHAR(200) NULL
  , ServerName NVARCHAR(200) NULL
  , DatabaseName NVARCHAR(200) NULL
  , SchemaName NVARCHAR(200) NULL
  , DatabaseUser NVARCHAR(100) NULL DEFAULT USER_NAME()
  , LoginUser NVARCHAR(100) NULL DEFAULT SUSER_NAME()
  , LoginUserSQLTransaction NVARCHAR(100) NULL DEFAULT ORIGINAL_LOGIN()
  , Hostname NVARCHAR(100) NULL DEFAULT HOST_NAME()
  , EventType NVARCHAR(200) NULL DEFAULT ''
  , ObjectName NVARCHAR(200) NULL DEFAULT ''
  , ObjectType NVARCHAR(200) NULL DEFAULT ''
  , Query NVARCHAR(MAX) NULL DEFAULT ''
  , CONSTRAINT PK_DDLTransaction PRIMARY KEY (TransID)
);


-- ============================================================
-- Configuração do Service Broker no banco DBA_PerformanceHub
-- Os comandos SINGLE_USER e MULTI_USER estão 
-- comentados para uso opcional
-- em cenários de dificuldade para habilitar o broker.
-- ============================================================
USE DBA_PerformanceHub;
GO

/*
ALTER DATABASE DBA_PerformanceHub SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE DBA_PerformanceHub SET MULTI_USER WITH ROLLBACK IMMEDIATE;
*/
ALTER DATABASE DBA_PerformanceHub SET TRUSTWORTHY ON;
GO

ALTER DATABASE DBA_PerformanceHub SET ENABLE_BROKER;
GO

-- ============================================================
-- Criação da Queue e Service para Event Notification
-- A queue recebe mensagens de eventos e 
-- o service define o contrato de entrega.
-- ============================================================
CREATE QUEUE [Audit_AlterObjects_Queue];
GO

CREATE SERVICE [Audit_AlterObjects_Service]
ON QUEUE [Audit_AlterObjects_Queue]
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

-- ============================================================
-- Criação do Event Notification em nível de servidor
-- Publica eventos DDL para 
-- o service Audit_AlterObjects_Service.
-- ============================================================
CREATE EVENT NOTIFICATION [Audit_AlterObjects_Event]
ON SERVER WITH FAN_IN
FOR
    CREATE_TABLE
  , ALTER_TABLE
  , DROP_TABLE
  , CREATE_INDEX
  , ALTER_INDEX
  , DROP_INDEX
  , CREATE_VIEW
  , ALTER_VIEW
  , DROP_VIEW
  , CREATE_PROCEDURE
  , ALTER_PROCEDURE
  , DROP_PROCEDURE
  , CREATE_FUNCTION
  , ALTER_FUNCTION
  , DROP_FUNCTION
  , CREATE_TRIGGER
  , ALTER_TRIGGER
  , DROP_TRIGGER
  , CREATE_TYPE
  , DROP_TYPE
  , DROP_STATISTICS
  , UPDATE_STATISTICS
  , CREATE_STATISTICS
  , CREATE_QUEUE
  , ALTER_QUEUE
  , DROP_QUEUE
  , CREATE_DATABASE
  , ALTER_DATABASE
  , DROP_DATABASE
  , CREATE_SERVICE
  , ALTER_SERVICE
  , DROP_SERVICE
TO SERVICE 'Audit_AlterObjects_Service'
  , 'current database';
GO

-- Remoção do Event Notification, se necessário:
-- DROP EVENT NOTIFICATION [Audit_AlterObjects_Event] ON SERVER;

-- ============================================================
-- Procedure de ativação da queue
-- O Service Broker executa esta procedure 
-- quando mensagens chegam à queue.
-- Cada mensagem XML é convertida em 
-- linha na tabela Management.DDLTransaction.
-- ============================================================
CREATE OR ALTER PROCEDURE Management.sp_AlterObjects
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message_body XML;

    -- Loop contínuo de leitura da queue
    WHILE (1 = 1)
    BEGIN
        WAITFOR
        (
            RECEIVE TOP (1)
                @message_body = CAST(message_body AS XML)
            FROM dbo.Audit_AlterObjects_Queue
        ), TIMEOUT 1000;

        IF (@@ROWCOUNT = 1)
        BEGIN
            INSERT INTO DBA_PerformanceHub.Management.DDLTransaction
            (
                DateDDl
              , PostTime
              , SPID
              , ServerName
              , DatabaseName
              , SchemaName
              , DatabaseUser
              , LoginUser
              , EventType
              , ObjectName
              , ObjectType
              , Query
            )
            SELECT
                GETDATE()
              , @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/UserName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');
        END;
    END;
END;
GO

-- ============================================================
-- Ativação da queue
-- Associa a procedure Management.sp_AlterObjects à queue 
-- para processamento automático.
-- ============================================================
ALTER QUEUE [Audit_AlterObjects_Queue]
WITH ACTIVATION
(
    STATUS = ON
  , PROCEDURE_NAME = Management.sp_AlterObjects
  , MAX_QUEUE_READERS = 1
  , EXECUTE AS OWNER
);
GO

-- ============================================================
-- Retenção de dados da tabela DDLTransaction
-- Remove registros com mais de @qtdadeDias dias, 
-- preservando histórico recente.
-- Observação: ajuste YOUR_DATABASE para o banco 
-- onde a tabela de auditoria reside.
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_DeleteHistoryDDL
(
    @qtdadeManterDias INT = 365 -- Quantidade de dias para manter
)
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        -- Contagem de dias distintos com histórico DDL
        DECLARE @qtdadeDias INT
              , @dataMin DATE

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Registros)
            FROM
            (
                SELECT COUNT(*) AS [Registros]
                FROM [YOUR_DATABASE].[Management].DDLTransaction AS t1
                GROUP BY CAST(t1.DateDDl AS DATE)
            ) AS x
        )

        -- Loop de exclusão dos dias excedentes
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT CAST(DATEADD(DAY, 1,
                (
                    SELECT MIN(t1.DateDDl)
                    FROM [YOUR_DATABASE].[Management].DDLTransaction AS t1
                )) AS DATE)
            )

            DELETE FROM [YOUR_DATABASE].[Management].DDLTransaction
            WHERE DateDDl < @dataMin

            SET @qtdadeDias -= 1
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- Variáveis para envio de e-mail de falha
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100) -- assunto
              , @recipients VARCHAR(100); -- destinatário

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';
        SET @corpoFalha = ''

        -- Montagem do corpo do e-mail de falha
        SELECT @corpoFalha = @corpoFalha + '
| Falha na procedure [sp_DeleteHistoryDDL]:
|
| ---|---|---|
|    [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
|      [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
|      [MESSAGE] - ' + ERROR_MESSAGE() + '
|
'

        SELECT @corpoFalha = @corpoFalha + ''

        -- Envio do e-mail de falha
        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients
          , @subject = @subject
          , @profile_name = 'CRAVIL'
          , @body = @corpoFalha
          , @body_format = 'HTML';
    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO


-- ============================================================
-- Alternativa de auditoria em nível de banco de dados
-- Captura eventos DDL do banco atual 
-- usando EVENTDATA(), sem Service Broker.
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER TRIGGER [tr_YOUR_DATABASE_DDLTransaction_BD]
ON DATABASE
WITH ENCRYPTION
FOR DDL_DATABASE_LEVEL_EVENTS
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @DadosXML XML

    SET @DadosXML = EVENTDATA()

    INSERT INTO DBA_PerformanceHub.Management.DDLTransaction
    (
        EventType
      , ObjectName
      , ObjectType
      , Query
    )
    VALUES
    (
        @DadosXML.value('(EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(200)')
      , @DadosXML.value('(EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(200)')
      , @DadosXML.value('(EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(200)')
      , @DadosXML.value('(EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)')
    )
END
GO

-- ============================================================
-- Alternativa simplificada de tabela de auditoria (dedo duro)
-- Avaliar antes de executar, pois pode conflitar 
-- com a tabela principal já criada neste script.
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE Management.DDLTransaction
(
    TransID INT IDENTITY(1,1) PRIMARY KEY
  , DateDDl SMALLDATETIME DEFAULT GETDATE()
  , DatabaseUser VARCHAR(100) DEFAULT USER_NAME()
  , LoginUser VARCHAR(100) DEFAULT SUSER_NAME()
  , LoginUserSQLTransaction VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
  , Hostname VARCHAR(100) DEFAULT HOST_NAME()
  , EventType NVARCHAR(200) DEFAULT ''
  , ObjectName NVARCHAR(200) DEFAULT ''
  , ObjectType NVARCHAR(200) DEFAULT ''
  , Query NVARCHAR(MAX) DEFAULT ''
)
