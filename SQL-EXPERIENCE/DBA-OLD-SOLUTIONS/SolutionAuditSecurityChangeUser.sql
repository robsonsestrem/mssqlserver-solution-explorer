/*
 *
	OBJETIVO: Auditoria e coleta de alterações de segurança (logins e usuários) no servidor e bancos de dados
	          via Service Broker e Event Notification, armazenando o histórico em tabela dedicada.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	http://www.dbinternals.com.br/?p=972
 */
-- ============================================================
-- Auditoria de Alterações de Segurança (Security Change Audit)
-- ============================================================
USE [DBA_PerformanceHub];
GO

-- Criação da tabela de histórico de alterações de segurança
CREATE TABLE [Management].[HistorySecurityChange]
(
    [ChangeLogID] INT IDENTITY(1, 1) NOT NULL,
    [LoginName] SYSNAME NULL,
    [UserName] SYSNAME NULL,
    [DatabaseName] SYSNAME NULL,
    [SchemaName] SYSNAME NULL,
    [ObjectName] SYSNAME NULL,
    [ObjectType] VARCHAR(50) NULL,
    [DDLCommand] VARCHAR(MAX) NULL,
    [EventTime] DATETIME NOT NULL CONSTRAINT [DF_HistorySecurityChange_EventTime] DEFAULT (CURRENT_TIMESTAMP),
    CONSTRAINT [PK_HistorySecurityChange] PRIMARY KEY CLUSTERED ([ChangeLogID] ASC)
)
ON [PRIMARY];
GO

-- Criação da fila do Service Broker para receber as notificações de eventos
CREATE QUEUE [Audit_SecurityChange_Queue];
GO

-- Criação do serviço associado à fila para processamento das notificações
CREATE SERVICE [Audit_SecurityChange_Service]
    ON QUEUE [Audit_SecurityChange_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

-- Criação da notificação de evento no nível do servidor para capturar alterações de segurança
CREATE EVENT NOTIFICATION [Audit_SecurityChange_Event]
    ON SERVER
    WITH FAN_IN
    FOR CREATE_LOGIN,
        ALTER_LOGIN,
        DROP_LOGIN,
        ADD_SERVER_ROLE_MEMBER,
        DROP_SERVER_ROLE_MEMBER,
        DDL_DATABASE_SECURITY_EVENTS
    TO SERVICE 'Audit_SecurityChange_Service', 'current database';
GO

-- DROP EVENT NOTIFICATION Audit_SecurityChange_Event ON SERVER;

-- Procedure de processamento da fila de auditoria de segurança
CREATE OR ALTER PROCEDURE [Management].[sp_SecurityChange]
    WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @version INT;
    DECLARE @message_body XML;

    -- Obtém a versão principal do SQL Server para lógica condicional de parsing
    SET @version = (
        SELECT CONVERT(INT, REPLACE(LEFT(CONVERT(VARCHAR, SERVERPROPERTY('ProductVersion')), 2), '.', ''))
    );

    -- Loop contínuo para processamento das mensagens da fila
    WHILE (1 = 1)
    BEGIN
        -- Aguarda o recebimento de mensagem na fila com timeout de 1 segundo
        WAITFOR
        (
            RECEIVE TOP (1)
                @message_body = message_body
            FROM [dbo].[Audit_SecurityChange_Queue]
        ), TIMEOUT 1000;

        -- Se uma mensagem foi recebida, processa o conteúdo do evento
        IF (@@ROWCOUNT = 1)
        BEGIN
            -- Verifica se o evento é de usuário ou se a versão do SQL Server é superior a 9
            IF CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/EventType)')) IN ('DROP_USER', 'CREATE_USER', 'ALTER_USER')
                OR @version > 9
            BEGIN
                -- Inserção de eventos de nível de banco de dados (usuários)
                INSERT INTO [DBA_PerformanceHub].[Management].[HistorySecurityChange]
                (
                    [LoginName]
                  , [UserName]
                  , [DatabaseName]
                  , [SchemaName]
                  , [ObjectName]
                  , [ObjectType]
                  , [DDLCommand]
                )
                SELECT
                    CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/LoginName)')) AS [LoginName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/UserName)')) AS [UserName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/DatabaseName)')) AS [DatabaseName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/DefaultSchema)')) AS [SchemaName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/ObjectName)')) AS [ObjectName]
                  , CONVERT(VARCHAR(50), @message_body.query('data(/EVENT_INSTANCE/ObjectType)')) AS [ObjectType]
                  , CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/TSQLCommand/CommandText)')) AS [DDLCommand];
            END
            ELSE
            BEGIN
                -- Inserção de eventos de nível de servidor (logins e roles)
                INSERT INTO [DBA_PerformanceHub].[Management].[HistorySecurityChange]
                (
                    [LoginName]
                  , [UserName]
                  , [DatabaseName]
                  , [SchemaName]
                  , [ObjectName]
                  , [ObjectType]
                  , [DDLCommand]
                )
                SELECT
                    CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/LoginName)')) AS [LoginName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/UserName)')) AS [UserName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/DatabaseName)')) AS [DatabaseName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/SchemaName)')) AS [SchemaName]
                  , CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/ObjectName)')) AS [ObjectName]
                  , CONVERT(VARCHAR(50), @message_body.query('data(/EVENT_INSTANCE/ObjectType)')) AS [ObjectType]
                  , CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/EventType)'))
                    + ' '
                    + CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/RoleName)'))
                    + ' FOR '
                    + CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/LoginType)'))
                    + ' '
                    + CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/ObjectName)')) AS [DDLCommand];
            END
        END
    END

    SET NOCOUNT OFF;
END
GO

-- Ativação da fila para executar a procedure de processamento automaticamente
ALTER QUEUE [Audit_SecurityChange_Queue]
    WITH ACTIVATION
    (
        STATUS = ON,
        PROCEDURE_NAME = [Management].[sp_SecurityChange],
        MAX_QUEUE_READERS = 1,
        EXECUTE AS OWNER
    );
GO
