-------------------------------------------------------------------------------------------------------------------------------------------------
-- https://mlucasg.wordpress.com/2013/02/28/monitorando-bloqueios-no-sql-server/
-- 1 – Configuração da instância
--Através da procedure de sistema sp_configure, é preciso configurar o tempo que um bloqueio fica 
--em vigor (em segundos) antes da geração e captura do evento BLOCKED_PROCESS_REPORT. 
--No exemplo abaixo, estamos definindo este tempo em 20 segundos.
-------------------------------------------------------------------------------------------------------------------------------------------------
EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'blocked process threshold', 20
GO
RECONFIGURE
GO


-------------------------------------------------------------------------------------------------------------------------------------------------
-- 2 – Configuração do Service Broker
--O próximo passo é habilitar e configurar o Service Broker. Temos que criar uma fila em um database para armazenar as notificações. 
--Qualquer banco de dados pode ser utilizado. No nosso exemplo, vamos criar um banco exclusivo:
-------------------------------------------------------------------------------------------------------------------------------------------------
CREATE DATABASE DB_Management
GO
ALTER DATABASE DB_Management SET ENABLE_BROKER
GO

USE [DB_Management]
GO

CREATE QUEUE que_events
GO

CREATE SERVICE svc_events
ON QUEUE que_events ( [http://schemas.microsoft.com/SQL/Notifications/PostEventNotification] )
GO

CREATE EVENT NOTIFICATION notify_locks
ON SERVER
WITH fan_in
FOR BLOCKED_PROCESS_REPORT
TO SERVICE 'syseventservice', 'current database'; -- *** importante: current database ***
GO


-------------------------------------------------------------------------------------------------------------------------------------------------
-- 3 – Tratamento do evento
--Agora, precisamos criar uma stored procedure para receber as mensagens da fila e efetuar o tratamento. A idéia é utilizar o 
--comando RECEIVE, que funciona como um SELECT, lendo e removendo a mensagem da fila.
--No meu exemplo, o processo que está bloqueando outros é finalizado, através do comando KILL, e um e-mail é enviado para o 
--Administrador (logicamente que o Database Mail já deve estar configurado e funcionando):
-------------------------------------------------------------------------------------------------------------------------------------------------
SET ARITHABORT ON
GO
--CREATE ou ALTER
ALTER PROCEDURE dbo.prc_ReceiveMsg
AS
BEGIN
	SET ARITHABORT ON

	-- variaveis de trabalho

	DECLARE @spid_blocked int, @spid_blocking int;
	DECLARE @hostname_blocked varchar(255), @hostname_blocking varchar(255);
	DECLARE @loginname_blocked varchar(255), @loginname_blocking varchar(255);
	DECLARE @event_txt varchar(max);
	DECLARE @post_time varchar(32);
	DECLARE @msgs TABLE (message_body xml);

	DECLARE @email_body varchar(max);
	DECLARE @email_subject varchar(64);
	DECLARE @crlf varchar(2);

	DECLARE @cmd nvarchar(255);

	RECEIVE TOP(1) message_body
	FROM que_sysevents
	INTO @msgs;

	SELECT @spid_blocked  = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@spid)[1]', 'int'),
	@hostname_blocked  = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@hostname)[1]', 'varchar(255)'),
	@loginname_blocked = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@loginname)[1]', 'varchar(255)'),

	@spid_blocking = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@spid)[1]', 'int'),
	@hostname_blocking = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@hostname)[1]', 'varchar(255)'),
	@loginname_blocking = message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocking-process/process/@loginname)[1]', 'varchar(255)'),

	@event_txt = CAST(message_body as varchar(max)),
	@post_time = message_body.value('(/EVENT_INSTANCE/PostTime)[1]&#39', 'varchar(32)')
	FROM @msgs
	WHERE message_body IS NOT NULL;

	IF @@ROWCOUNT <= 0
	BEGIN
	PRINT 'Saindo… nenhuma linha encontrada (onde message_body IS NOT NULL)';
	RETURN;
	END

	-- exibir informacoes:
	PRINT 'Usuario atual: ' + USER_NAME()
	PRINT 'Processo bloqueando:'
	PRINT 'SPID  = ' + CAST(@spid_blocking as varchar(5))
	PRINT 'HOST  = ' + @hostname_blocking
	PRINT 'LOGIN = ' + @loginname_blocking
	PRINT 'HORARIO = ' + @post_time

	-- finalizar processo que esta bloqueando:
	SET @cmd = 'KILL ' + CAST(@spid_blocking AS varchar(5))
	EXEC sp_executesql @stmt = @cmd

	-- enviar e-mail:
	SET @crlf =  CHAR(13) + CHAR(10)
	SET @email_body  = 'Informacoes' + @crlf
	SET @email_body += 'Bloqueando: ' + @crlf
	SET @email_body += 'SPID  = ' + CAST(@spid_blocking as varchar(5)) + @crlf
	SET @email_body += 'LOGIN = ' + @loginname_blocking + @crlf
	SET @email_body += 'HOST  = ' + @hostname_blocking + @crlf
	SET @email_body += @crlf
	SET @email_body += 'HORARIO = ' + @post_time + @crlf
	SET @email_body += @crlf + @crlf
	SET @email_body += 'Dados do evento (XML):'
	SET @email_body += @event_txt

	SET @email_subject = 'SQL SERVER – Informacoes sobre processos bloqueados'

	EXEC msdb..sp_send_dbmail
	@recipients = 'dba@minhaempresa.com.br',
	@subject    = @email_subject,
	@body       = @email_body;
	
END
GO


-------------------------------------------------------------------------------------------------------------------------------------------------
-- Finalmente, associo a proc à fila e efetuo a ativação:
-------------------------------------------------------------------------------------------------------------------------------------------------
ALTER QUEUE que_sysevents WITH
STATUS = ON,
RETENTION = OFF,
ACTIVATION (
STATUS = ON,
MAX_QUEUE_READERS = 3,
PROCEDURE_NAME = dbo.prc_ReceiveMsg,
EXECUTE AS 'dbo'
)
;
GO