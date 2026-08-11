/*
 *
    OBJETIVO: Monitorar eventos de login (AUDIT_LOGIN) via Service Broker,
              identificando tentativas de login de determinados padrões
              (hostname e login específicos) e encerrando automaticamente
              essas conexões com o comando KILL, registrando os eventos
              na tabela DBA_FailedConnectionTracker.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://leka.com.br/category/ti/sql/scripts/
 *
 */
-- ============================================================
-- Consulta para identificar tipos de eventos de login disponíveis
-- ============================================================
SELECT
    *
FROM
    sys.event_notification_event_types WITH (NOLOCK)
WHERE
    type_name LIKE '%login%';


-- ============================================================
-- Configuração do Service Broker no banco de administração
-- ============================================================
USE master;
GO

ALTER DATABASE BASE_DE_ADMINISTRACAO_DO_DBA SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE;
GO

ALTER DATABASE BASE_DE_ADMINISTRACAO_DO_DBA SET TRUSTWORTHY ON;
GO


-- ============================================================
-- Criação da Queue, Service e Route para auditoria de logins
-- ============================================================
USE BASE_DE_ADMINISTRACAO_DO_DBA;
GO

CREATE QUEUE [Login_Killer_Queue];
GO

CREATE SERVICE [Login_Killer_Service]
    AUTHORIZATION [dbo]
    ON QUEUE [dbo].[Login_Killer_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE ROUTE Login_Killer_Route
    WITH SERVICE_NAME = 'Login_Killer_Service'
       , ADDRESS = 'LOCAL';
GO

DECLARE @AuditServiceBrokerGuid UNIQUEIDENTIFIER;
DECLARE @SQL VARCHAR(MAX);

-- Obtém o Service Broker GUID do banco de dados
SELECT @AuditServiceBrokerGuid = service_broker_guid
FROM master.sys.databases
WHERE name = 'BASE_DE_ADMINISTRACAO_DO_DBA';

-- Cria o Event Notification para AUDIT_LOGIN (com SQL dinâmico)
SET @SQL = 'IF EXISTS (SELECT * FROM sys.server_event_notifications WHERE name = ''Login_Killer_Notification'')
            DROP EVENT NOTIFICATION Login_Killer_EventNotification ON SERVER;

            CREATE EVENT NOTIFICATION Login_Killer_EventNotification
                ON SERVER WITH FAN_IN
                FOR AUDIT_LOGIN
                TO SERVICE ''Login_Killer_Service'', '''
                + CAST(@AuditServiceBrokerGuid AS VARCHAR(50)) + ''';';

EXEC (@SQL);
GO


-- ============================================================
-- Verifica a criação do Event Notification
-- ============================================================
SELECT
    *
FROM
    sys.server_event_notifications;

SELECT
    *
FROM
    sys.server_event_session_actions WITH (NOLOCK);


-- ============================================================
-- Tabela para armazenar tentativas de login bloqueadas
-- ============================================================
CREATE TABLE dbo.DBA_FailedConnectionTracker
(
    host_name           VARCHAR(128)    NOT NULL
  , login_name          VARCHAR(128)    NOT NULL
  , spidu               INT
  , FailedLoginData     XML
);
GO


-- ============================================================
-- Procedure de ativação da queue (processa eventos AUDIT_LOGIN)
-- ============================================================
CREATE OR PROCEDURE dbo.spc_DBA_FailedConnectionTracker
AS
BEGIN
    SET NOCOUNT ON;

    -- Loop infinito de processamento da fila
    WHILE (1 = 1)
    BEGIN
        DECLARE @messageBody VARBINARY(MAX);
        DECLARE @messageTypeName NVARCHAR(256);

        WAITFOR
        (
            RECEIVE TOP (1)
                @messageTypeName = message_type_name
              , @messageBody = message_body
            FROM
                dbo.Login_Killer_Queue
        ), TIMEOUT 500;

        -- Se não houver mensagens, sai do loop
        IF (@@ROWCOUNT = 0)
        BEGIN
            BREAK;
        END;

        -- Se o tipo da mensagem for EventNotification
        IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification')
        BEGIN
            DECLARE @XML XML;
            DECLARE @host_name VARCHAR(128);
            DECLARE @login_name VARCHAR(128);
            DECLARE @SPID VARCHAR(5);

            SELECT
                @XML = CONVERT(XML, @messageBody)
              , @host_name = ''
              , @login_name = ''
              , @SPID = '';

            -- Extrai SPID, hostname e login do XML
            SELECT
                @SPID = @XML.value('(/EVENT_INSTANCE/SPID)[1]', 'VARCHAR(5)')
              , @host_name = @XML.value('(/EVENT_INSTANCE/HostName)[1]', 'NVARCHAR(128)')
              , @login_name = @XML.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)');

            -- Se atender ao critério (hostname iniciando com 'SPO%' e login terminando com '_user')
            IF ((@host_name LIKE 'SPO%') AND (@login_name LIKE '%_user'))
            BEGIN
                DECLARE @kill VARCHAR(8000) = '';

                -- Monta e executa o comando KILL para encerrar a sessão
                SELECT @kill = @kill + 'KILL ' + @SPID + ';';
                EXEC(@kill);

                -- Registra o evento na tabela de auditoria
                INSERT INTO dbo.DBA_FailedConnectionTracker
                (
                    host_name
                  , login_name
                  , spidu
                  , FailedLoginData
                )
                VALUES
                (
                    @host_name
                  , @login_name
                  , @SPID
                  , @XML
                );
            END;
        END;  -- fim do IF (EventNotification)
    END;      -- fim do WHILE
END;          -- fim da PROCEDURE
GO


-- ============================================================
-- Ativação da queue (associa a procedure e inicia o processamento)
-- ============================================================
ALTER QUEUE dbo.Login_Killer_Queue
WITH
    STATUS = ON
  , ACTIVATION
    (
        PROCEDURE_NAME = dbo.spc_DBA_FailedConnectionTracker
      , STATUS = ON
      , MAX_QUEUE_READERS = 1
      , EXECUTE AS OWNER
    );
GO
