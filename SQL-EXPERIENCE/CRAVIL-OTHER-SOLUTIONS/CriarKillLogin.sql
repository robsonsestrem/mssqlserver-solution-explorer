----------------------------------------------------------------------------------------------------------
-- https://leka.com.br/category/ti/sql/scripts/
----------------------------------------------------------------------------------------------------------
-- apenas para constatar quais tipos de eventos podemos tratar... o que queremos eh o audit_login
----------------------------------------------------------------------------------------------------------
select * from sys.event_notification_event_types with (nolock)
where type_name like '%login%'


use master
go
alter database BASE_DE_ADMINISTRACAO_DO_DBA set enable_broker with rollback immediate
go
 
alter database BASE_DE_ADMINISTRACAO_DO_DBA set TRUSTWORTHY on
go
 

use BASE_DE_ADMINISTRACAO_DO_DBA
go
CREATE QUEUE [Login_Killer_Queue]
GO
 
CREATE SERVICE [Login_Killer_Service]
AUTHORIZATION [dbo]
ON QUEUE [dbo].[Login_Killer_QUEUE]
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO
CREATE ROUTE Login_Killer_Route
WITH SERVICE_NAME = 'Login_Killer_Service',
ADDRESS = 'LOCAL';
GO
DECLARE @AuditServiceBrokerGuid [uniqueidentifier]
,@SQL [varchar](max);
 
-- Pega o service broker guid da base de dados
SELECT @AuditServiceBrokerGuid = [service_broker_guid]
FROM [master].[sys].[databases]
WHERE [name] = 'ADM_BDADOS'
 
-- Cria e executa o SQL dinamico para criar o objeto do evento de notificacao
SET @SQL = 'IF EXISTS (SELECT * FROM sys.server_event_notifications
WHERE name = ''Login_Killer_Notification'')
 
DROP EVENT NOTIFICATION Login_Killer_EventNotification ON SERVER
 
CREATE EVENT NOTIFICATION Login_Killer_EventNotification
ON SERVER
WITH fan_in
FOR AUDIT_LOGIN
TO SERVICE ''Login_Killer_Service'', '''
+ CAST(@AuditServiceBrokerGuid AS [varchar](50)) + ''';'
EXEC (@SQL)
GO

SELECT * FROM [sys].[server_event_notifications]
 
select * from sys.server_event_session_actions with (nolock)

CREATE TABLE [dbo].[DBA_FailedConnectionTracker](
[host_name] [varchar](128) NOT NULL,
[login_name] [varchar](128) NOT NULL,
[spidu] int,
[FailedLoginData] XML
) ;
 
CREATE PROCEDURE dbo.spc_DBA_FailedConnectionTracker
AS
BEGIN
	SET NOCOUNT ON;
	-- looping infinito
	WHILE (1 = 1)
		BEGIN
			DECLARE @messageBody VARBINARY(MAX);
			DECLARE @messageTypeName NVARCHAR(256);
			WAITFOR (
			RECEIVE TOP(1)
			@messageTypeName = message_type_name,
			@messageBody = message_body
			FROM [Login_Killer_Queue]
			), TIMEOUT 500

			-- se nao houver mensagens saia
			IF @@ROWCOUNT = 0
				BEGIN
					BREAK ;
				END ;

			-- se o tipo da mensagem for um EventNotification para a fila atual
			IF (@messageTypeName = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification')
				BEGIN
					DECLARE @XML XML,
					@host_name varchar(128) ,
					@login_name varchar(128) ,
					@SPID varchar(5);
 
					SELECT @XML=CONVERT(XML,@messageBody)
					,@host_name = ''
					,@login_name = ''
					,@SPID ='';
 
					-- Pega o SPID e as informacoes de login
					SELECT @SPID = @XML.value('(/EVENT_INSTANCE/SPID)[1]', 'varchar(5)')
					, @host_name = @XML.value('(/EVENT_INSTANCE/HostName)[1]', 'NVARCHAR(128)')
					, @login_name = @XML.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(128)');
 
					DECLARE @kill varchar(8000) = '';

					--Caso o hostname e o login entrem no criterio abaixo
					if ((@host_name like 'SPO%') and (@login_name like '%_user'))
						SELECT @kill = @kill + 'kill ' + @SPID + ';'
						EXEC(@kill);
 
					--/* esta parte pode ser comentada para não gerar log do kill
					if ((@host_name like 'SPO%') and (@login_name like '%_user'))
						INSERT INTO [dbo].[DBA_FailedConnectionTracker]
						([host_name], [login_name], FailedLoginData,spidu)
						values ( @host_name, @login_name,@XML,@SPID);
					--*/
				END;--fim do if event notification
		END;--fim do while
END;--fim procedure

--inicia a matanca
 
ALTER QUEUE [dbo].[Login_Killer_Queue]
WITH STATUS = on
,ACTIVATION (PROCEDURE_NAME = [spc_DBA_FailedConnectionTracker]
,STATUS = ON
,MAX_QUEUE_READERS = 1
,EXECUTE AS OWNER)
GO