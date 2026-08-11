/*
 *
	OBJETIVO: Auditoria de falhas de login no servidor SQL Server via Service Broker
	          e Event Notification, capturando eventos AUDIT_LOGIN_FAILED e
	          armazenando o histórico em tabela dedicada para análise de segurança.
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Histórico de Erros de Login (Audit Login Failed)
-- ============================================================
USE [DBA_PerformanceHub];
GO

-- Criação da fila do Service Broker para receber as notificações de erro de login
CREATE QUEUE [Audit_Erros_Login_Queue];
GO

-- Criação do serviço associado à fila para processamento das notificações
CREATE SERVICE [Audit_Erros_Login_Service]
    ON QUEUE [Audit_Erros_Login_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

-- Criação da notificação de evento no nível do servidor para capturar falhas de login
CREATE EVENT NOTIFICATION [Audit_Erros_Login_Event]
    ON SERVER
    FOR AUDIT_LOGIN_FAILED
    TO SERVICE N'Audit_Erros_Login_Service', N'current database';
GO

-- DROP EVENT NOTIFICATION [Audit_Erros_Login_Event]
-- ON SERVER;

-- Criação da tabela de histórico de erros de login
USE [DBA_PerformanceHub];
GO

CREATE TABLE [Management].[HistoryErrorLogin]
(
    [IdErrorLog] INT IDENTITY(1, 1) NOT NULL
  , [DateError] DATETIME NULL
  , [EventType] NVARCHAR(MAX) NULL
  , [PostTime] NVARCHAR(MAX) NULL
  , [SPID] NVARCHAR(MAX) NULL
  , [TextData] NVARCHAR(MAX) NULL
  , [DatabaseID] NVARCHAR(MAX) NULL
  , [NTUserName] NVARCHAR(MAX) NULL
  , [NTDomainName] NVARCHAR(MAX) NULL
  , [HostName] NVARCHAR(MAX) NULL
  , [ClientProcessID] NVARCHAR(MAX) NULL
  , [ApplicationName] NVARCHAR(MAX) NULL
  , [LoginName] NVARCHAR(MAX) NULL
  , [StartTime] NVARCHAR(MAX) NULL
  , [EventSubClass] NVARCHAR(MAX) NULL
  , [Success] NVARCHAR(MAX) NULL
  , [ServerName] NVARCHAR(MAX) NULL
  , [State] NVARCHAR(MAX) NULL
  , [Error] NVARCHAR(MAX) NULL
  , [DatabaseName] NVARCHAR(MAX) NULL
  , [RequestID] NVARCHAR(MAX) NULL
  , [EventSequence] NVARCHAR(MAX) NULL
  , [Type] NVARCHAR(MAX) NULL
  , [IsSystem] NVARCHAR(MAX) NULL
  , [SessionLoginName] NVARCHAR(MAX) NULL
  , CONSTRAINT [PK_ErrosID] PRIMARY KEY ([IdErrorLog])
)
ON [PRIMARY];
GO

-- Procedure de processamento da fila de auditoria de erros de login
USE [DBA_PerformanceHub];
GO

CREATE OR ALTER PROCEDURE [Management].[sp_ErrorLogin]
    WITH EXECUTE AS OWNER, ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message_body XML;

    -- Loop contínuo para processamento das mensagens da fila
    WHILE (1 = 1)
    BEGIN
        -- Aguarda o recebimento de mensagem na fila com timeout de 1 segundo
        WAITFOR
        (
            RECEIVE TOP (1)
                @message_body = CAST([message_body] AS XML)
            FROM [dbo].[Audit_Erros_Login_Queue]
        ), TIMEOUT 1000;

        -- Se uma mensagem foi recebida, processa o conteúdo do evento
        IF (@@ROWCOUNT >= 1)
        BEGIN
            -- Inserção dos dados extraídos do XML na tabela de histórico
            INSERT INTO [Management].[HistoryErrorLogin]
            (
                [DateError]
              , [EventType]
              , [PostTime]
              , [SPID]
              , [TextData]
              , [DatabaseID]
              , [NTUserName]
              , [NTDomainName]
              , [HostName]
              , [ClientProcessID]
              , [ApplicationName]
              , [LoginName]
              , [StartTime]
              , [EventSubClass]
              , [Success]
              , [ServerName]
              , [State]
              , [Error]
              , [DatabaseName]
              , [RequestID]
              , [EventSequence]
              , [Type]
              , [IsSystem]
              , [SessionLoginName]
            )
            SELECT
                GETDATE() AS [DateError]
              , @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)') AS [EventType]
              , @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'nvarchar(max)') AS [PostTime]
              , @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'nvarchar(max)') AS [SPID]
              , @message_body.value('(/EVENT_INSTANCE/TextData)[1]', 'nvarchar(max)') AS [TextData]
              , @message_body.value('(/EVENT_INSTANCE/DatabaseID)[1]', 'nvarchar(max)') AS [DatabaseID]
              , @message_body.value('(/EVENT_INSTANCE/NTUserName)[1]', 'nvarchar(max)') AS [NTUserName]
              , @message_body.value('(/EVENT_INSTANCE/NTDomainName)[1]', 'nvarchar(max)') AS [NTDomainName]
              , @message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'nvarchar(max)') AS [HostName]
              , @message_body.value('(/EVENT_INSTANCE/ClientProcessID)[1]', 'nvarchar(max)') AS [ClientProcessID]
              , @message_body.value('(/EVENT_INSTANCE/ApplicationName)[1]', 'nvarchar(max)') AS [ApplicationName]
              , @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(max)') AS [LoginName]
              , @message_body.value('(/EVENT_INSTANCE/StartTime)[1]', 'nvarchar(max)') AS [StartTime]
              , @message_body.value('(/EVENT_INSTANCE/EventSubClass)[1]', 'nvarchar(max)') AS [EventSubClass]
              , @message_body.value('(/EVENT_INSTANCE/Success)[1]', 'nvarchar(max)') AS [Success]
              , @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(max)') AS [ServerName]
              , @message_body.value('(/EVENT_INSTANCE/State)[1]', 'nvarchar(max)') AS [State]
              , @message_body.value('(/EVENT_INSTANCE/Error)[1]', 'nvarchar(max)') AS [Error]
              , @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(max)') AS [DatabaseName]
              , @message_body.value('(/EVENT_INSTANCE/RequestID)[1]', 'nvarchar(max)') AS [RequestID]
              , @message_body.value('(/EVENT_INSTANCE/EventSequence)[1]', 'nvarchar(max)') AS [EventSequence]
              , @message_body.value('(/EVENT_INSTANCE/Type)[1]', 'nvarchar(max)') AS [Type]
              , @message_body.value('(/EVENT_INSTANCE/IsSystem)[1]', 'nvarchar(max)') AS [IsSystem]
              , @message_body.value('(/EVENT_INSTANCE/SessionLoginName)[1]', 'nvarchar(max)') AS [SessionLoginName];
        END
    END

    SET NOCOUNT OFF;
END
GO

-- Ativação da fila para executar a procedure de processamento automaticamente
ALTER QUEUE [Audit_Erros_Login_Queue]
    WITH ACTIVATION
    (
        STATUS = ON
      , PROCEDURE_NAME = [Management].[sp_ErrorLogin]
      , MAX_QUEUE_READERS = 1
      , EXECUTE AS OWNER
    );
GO
