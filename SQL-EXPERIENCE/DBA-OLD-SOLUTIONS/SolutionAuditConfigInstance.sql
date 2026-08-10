/*
    OBJETIVO: Solução para auditoria de alterações de configuração no servidor SQL Server,
              capturando todas as alterações de segurança em logins e usuários.
    PROJETO: mssqlserver-solution-explorer

    COMPONENTES:
    - Management.HistoryServerConfig (Tabela de histórico)
    - Audit_ServerConfig_Queue (Fila do Service Broker)
    - Audit_ServerConfig_Service (Serviço do Service Broker)
    - Audit_ServerConfig_Event (Event Notification no servidor)
    - Management.sp_ServerConfig (Procedure de processamento)

    REFERÊNCIAS:
    - http://www.dbinternals.com.br/?p=1077
 */
-- ================================================================================================================================
-- TABELA: HistoryServerConfig
-- Armazena o histórico de alterações de configuração do servidor
-- ================================================================================================================================
CREATE TABLE Management.HistoryServerConfig
(
    [IdServerConfig] [INT] IDENTITY(1, 1) NOT NULL,
    DateInsert [DATETIME] NULL,
    [EventType] [NVARCHAR](MAX) NULL,
    [PostTime] [NVARCHAR](MAX) NULL,
    [SPID] [NVARCHAR](MAX) NULL,
    [ServerName] [NVARCHAR](MAX) NULL,
    [LoginName] [NVARCHAR](MAX) NULL,
    [PropertyName] [NVARCHAR](MAX) NULL,
    [PropertyValue] [NVARCHAR](MAX) NULL,
    [Parameters] [XML] NULL,
    [CommandText] [NVARCHAR](MAX) NULL,
    CONSTRAINT PK_tb_ServerConfig PRIMARY KEY ([IdServerConfig])
)
GO

-- ================================================================================================================================
-- SERVICE BROKER: Configuração da fila e serviço para recebimento de notificações
-- ================================================================================================================================

-- Criação da fila para armazenar as notificações de eventos
CREATE QUEUE [Audit_ServerConfig_Queue]
GO

-- Criação do serviço associado à fila
CREATE SERVICE Audit_ServerConfig_Service
    ON QUEUE [Audit_ServerConfig_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

-- ================================================================================================================================
-- EVENT NOTIFICATION: Monitora alterações de configuração no servidor
-- ================================================================================================================================

-- Criação da notificação de evento para capturar alterações de instância
CREATE EVENT NOTIFICATION [Audit_ServerConfig_Event]
    ON SERVER
    WITH FAN_IN
    FOR ALTER_INSTANCE
    TO SERVICE 'Audit_ServerConfig_Service', 'current database'
GO

-- Comando para remover a notificação (mantido para referência)
-- DROP EVENT NOTIFICATION [Audit_ServerConfig_Event] ON SERVER
GO

-- ================================================================================================================================
-- PROCEDURE: sp_ServerConfig
-- Processa as mensagens da fila e insere os dados no histórico
-- ================================================================================================================================
CREATE OR ALTER PROCEDURE Management.sp_ServerConfig
WITH EXECUTE AS OWNER
   , ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @message_body XML

    -- Loop infinito para processar mensagens continuamente
    WHILE (1 = 1)
    BEGIN
        -- Aguarda recebimento de mensagem na fila (timeout de 1 segundo)
        WAITFOR
        (
            RECEIVE TOP (1)
                @message_body = CAST(message_body AS XML)
            FROM
                dbo.Audit_ServerConfig_Queue
        ),
        TIMEOUT 1000

        -- Se recebeu uma mensagem, processa
        IF (@@ROWCOUNT = 1)
        BEGIN
            INSERT INTO Maintenance.Management.HistoryServerConfig
            (
                DateInsert,
                [EventType],
                [PostTime],
                [SPID],
                [ServerName],
                [LoginName],
                [PropertyName],
                [PropertyValue],
                [Parameters],
                [CommandText]
            )
            SELECT
                GETDATE(),
                @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(MAX)') AS [EventType],
                @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'NVARCHAR(MAX)') AS [PostTime],
                @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'NVARCHAR(MAX)') AS [SPID],
                @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'NVARCHAR(MAX)') AS [ServerName],
                @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(MAX)') AS [LoginName],
                @message_body.value('(/EVENT_INSTANCE/PropertyName)[1]', 'NVARCHAR(MAX)') AS [PropertyName],
                @message_body.value('(/EVENT_INSTANCE/PropertyValue)[1]', 'NVARCHAR(MAX)') AS [PropertyValue],
                CAST(@message_body.query('/EVENT_INSTANCE/Parameters/*') AS XML) AS [Parameters],
                @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)') AS [CommandText]
        END
    END

    SET NOCOUNT OFF
END
GO

-- ================================================================================================================================
-- ATIVAÇÃO DA FILA: Configura a ativação automática da procedure
-- ================================================================================================================================

-- Configura a fila para ativar automaticamente a procedure de processamento
ALTER QUEUE [Audit_ServerConfig_Queue]
WITH ACTIVATION
(
    STATUS = ON,
    PROCEDURE_NAME = Management.sp_ServerConfig,
    MAX_QUEUE_READERS = 1,
    EXECUTE AS OWNER
)
GO

-- ================================================================================================================================
-- COMANDOS DE MANUTENÇÃO (REFERÊNCIA)
-- ================================================================================================================================

-- Para remover a notificação de evento:
-- DROP EVENT NOTIFICATION [Audit_ServerConfig_Event] ON SERVER
-- GO

-- Para desativar a ativação da fila:
-- ALTER QUEUE [Audit_ServerConfig_Queue]
-- WITH ACTIVATION (STATUS = OFF)
-- GO

-- Para consultar os dados coletados:
-- SELECT * FROM Maintenance.Management.HistoryServerConfig
-- ORDER BY DateInsert DESC
-- GO
