/*
 *
    OBJETIVO: Monitorar e encerrar automaticamente processos bloqueados
              utilizando Service Broker com Event Notification para
              BLOCKED_PROCESS_REPORT, configurando o threshold de bloqueio,
              criando fila e serviço, e finalizando o processo bloqueador
              com envio de e-mail de notificação.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://mlucasg.wordpress.com/2013/02/28/monitorando-bloqueios-no-sql-server/
 *
 */
-- ============================================================
-- 1 – Configuração da instância
-- Define o tempo (em segundos) que um bloqueio deve permanecer
-- ativo antes de gerar o evento BLOCKED_PROCESS_REPORT
-- ============================================================
EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO

EXEC sp_configure 'blocked process threshold', 20;
GO
RECONFIGURE;
GO


-- ============================================================
-- 2 – Configuração do Service Broker
-- Criação do banco de dados, fila e serviço para notificações
-- ============================================================
CREATE DATABASE DB_Management;
GO

ALTER DATABASE DB_Management SET ENABLE_BROKER;
GO

USE DB_Management;
GO

CREATE QUEUE que_events;
GO

CREATE SERVICE svc_events
    ON QUEUE que_events
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION notify_locks
    ON SERVER WITH FAN_IN
    FOR BLOCKED_PROCESS_REPORT
    TO SERVICE 'svc_events', 'current database';  -- *** importante: current database ***
GO


-- ============================================================
-- 3 – Tratamento do evento
-- Procedure de ativação da queue: lê mensagens, finaliza processo
-- bloqueador e envia e-mail de notificação
-- ============================================================
SET ARITHABORT ON;
GO

CREATE OR ALTER PROCEDURE dbo.prc_ReceiveMsg
AS
BEGIN
    SET ARITHABORT ON;

    -- Variáveis de trabalho
    DECLARE @spid_blocked INT
          , @spid_blocking INT;
    DECLARE @hostname_blocked VARCHAR(255)
          , @hostname_blocking VARCHAR(255);
    DECLARE @loginname_blocked VARCHAR(255)
          , @loginname_blocking VARCHAR(255);
    DECLARE @event_txt VARCHAR(MAX);
    DECLARE @post_time VARCHAR(32);
    DECLARE @msgs TABLE (message_body XML);

    DECLARE @email_body VARCHAR(MAX);
    DECLARE @email_subject VARCHAR(64);
    DECLARE @crlf VARCHAR(2);

    DECLARE @cmd NVARCHAR(255);

    -- Recebe a mensagem da fila
    RECEIVE TOP (1) message_body
    FROM que_events
    INTO @msgs;

    -- Extrai as informações do XML
    SELECT
        @spid_blocked     = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@spid)[1]', 'INT')
      , @hostname_blocked = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@hostname)[1]', 'VARCHAR(255)')
      , @loginname_blocked = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@loginname)[1]', 'VARCHAR(255)')
      , @spid_blocking    = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@spid)[1]', 'INT')
      , @hostname_blocking = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@hostname)[1]', 'VARCHAR(255)')
      , @loginname_blocking = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@loginname)[1]', 'VARCHAR(255)')
      , @event_txt = CAST(message_body AS VARCHAR(MAX))
      , @post_time = message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'VARCHAR(32)')
    FROM
        @msgs
    WHERE
        message_body IS NOT NULL;

    IF (@@ROWCOUNT <= 0)
    BEGIN
        PRINT 'Saindo… nenhuma linha encontrada (onde message_body IS NOT NULL)';
        RETURN;
    END;

    -- Exibe informações no log
    PRINT 'Usuario atual: ' + USER_NAME();
    PRINT 'Processo bloqueando:';
    PRINT 'SPID  = ' + CAST(@spid_blocking AS VARCHAR(5));
    PRINT 'HOST  = ' + @hostname_blocking;
    PRINT 'LOGIN = ' + @loginname_blocking;
    PRINT 'HORARIO = ' + @post_time;

    -- Finaliza o processo que está bloqueando
    SET @cmd = 'KILL ' + CAST(@spid_blocking AS VARCHAR(5));
    EXEC sp_executesql @stmt = @cmd;

    -- Envia e-mail de notificação
    SET @crlf = CHAR(13) + CHAR(10);
    SET @email_body = 'Informações' + @crlf;
    SET @email_body = @email_body + 'Bloqueando: ' + @crlf;
    SET @email_body = @email_body + 'SPID  = ' + CAST(@spid_blocking AS VARCHAR(5)) + @crlf;
    SET @email_body = @email_body + 'LOGIN = ' + @loginname_blocking + @crlf;
    SET @email_body = @email_body + 'HOST  = ' + @hostname_blocking + @crlf;
    SET @email_body = @email_body + @crlf;
    SET @email_body = @email_body + 'HORARIO = ' + @post_time + @crlf;
    SET @email_body = @email_body + @crlf + @crlf;
    SET @email_body = @email_body + 'Dados do evento (XML):' + @crlf;
    SET @email_body = @email_body + @event_txt;

    SET @email_subject = 'SQL SERVER – Informações sobre processos bloqueados';

    EXEC msdb.dbo.sp_send_dbmail
        @recipients = 'dba@minhaempresa.com.br'
      , @subject = @email_subject
      , @body = @email_body;
END;
GO


-- ============================================================
-- 4 – Ativação da queue
-- Associa a procedure à fila e ativa o processamento
-- ============================================================
ALTER QUEUE que_events
WITH
    STATUS = ON
  , RETENTION = OFF
  , ACTIVATION
    (
        STATUS = ON
      , MAX_QUEUE_READERS = 3
      , PROCEDURE_NAME = dbo.prc_ReceiveMsg
      , EXECUTE AS 'dbo'
    );
GO
