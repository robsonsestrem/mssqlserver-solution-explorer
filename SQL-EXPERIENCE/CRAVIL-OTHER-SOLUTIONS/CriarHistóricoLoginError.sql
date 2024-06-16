USE Maintenance
GO

CREATE QUEUE [Audit_Erros_Login_Queue];
GO
CREATE SERVICE [Audit_Erros_Login_Service] ON QUEUE [Audit_Erros_Login_Queue]([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO
CREATE EVENT NOTIFICATION [Audit_Erros_Login_Event] ON SERVER FOR AUDIT_LOGIN_FAILED TO SERVICE N'Audit_Erros_Login_Service', N'current database';
GO

DROP EVENT NOTIFICATION [Audit_Erros_Login_Event]  
ON SERVER; 
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE IntegraTICravil;
GO
CREATE TABLE Management.HistoryErrorLogin
(	[IdErrorLog] [int] IDENTITY(1,1) NOT NULL,
	[DateError] [datetime] NULL,
	[EventType] [nvarchar](max) NULL,
	[PostTime] [nvarchar](max) NULL,
	[SPID] [nvarchar](max) NULL,
	[TextData] [nvarchar](max) NULL,
	[DatabaseID] [nvarchar](max) NULL,
	[NTUserName] [nvarchar](max) NULL,
	[NTDomainName] [nvarchar](max) NULL,
	[HostName] [nvarchar](max) NULL,
	[ClientProcessID] [nvarchar](max) NULL,
	[ApplicationName] [nvarchar](max) NULL,
	[LoginName] [nvarchar](max) NULL,
	[StartTime] [nvarchar](max) NULL,
	[EventSubClass] [nvarchar](max) NULL,
	[Success] [nvarchar](max) NULL,
	[ServerName] [nvarchar](max) NULL,
	[State] [nvarchar](max) NULL,
	[Error] [nvarchar](max) NULL,
	[DatabaseName] [nvarchar](max) NULL,
	[RequestID] [nvarchar](max) NULL,
	[EventSequence] [nvarchar](max) NULL,
	[Type] [nvarchar](max) NULL,
	[IsSystem] [nvarchar](max) NULL,
	[SessionLoginName] [nvarchar](max) NULL
 CONSTRAINT PK_ErrosID PRIMARY KEY(IdErrorLog)
);

GO


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Management.[sp_ErrorLogin]
WITH EXECUTE AS OWNER, ENCRYPTION
AS
     BEGIN
         SET NOCOUNT ON;
         DECLARE @version INT;
         DECLARE @message_body XML;

         WHILE(1 = 1)
             BEGIN
                 WAITFOR(
                 RECEIVE TOP (1) @message_body = CAST(message_body AS XML) FROM dbo.Audit_Erros_Login_Queue), TIMEOUT 1000;

                 IF(@@ROWCOUNT >= 1)
                     BEGIN
					   INSERT INTO Management.HistoryErrorLogin
					   ([DateError],
					    [EventType],
					    [PostTime],
					    [SPID],
					    [TextData],
					    [DatabaseID],
					    [NTUserName],
					    [NTDomainName],
					    [HostName],
					    [ClientProcessID],
					    [ApplicationName],
					    [LoginName],
					    [StartTime],
					    [EventSubClass],
					    [Success],
					    [ServerName],
					    [State],
					    [Error],
					    [DatabaseName],
					    [RequestID],
					    [EventSequence],
					    [Type],
					    [IsSystem],
					    [SessionLoginName]
					   )
					   SELECT GETDATE(),
							@message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)') AS [EventType],
							@message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'nvarchar(max)') AS [PostTime],
							@message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'nvarchar(max)') AS [SPID],
							@message_body.value('(/EVENT_INSTANCE/TextData)[1]', 'nvarchar(max)') AS [TextData],
							@message_body.value('(/EVENT_INSTANCE/DatabaseID)[1]', 'nvarchar(max)') AS [DatabaseID],
							@message_body.value('(/EVENT_INSTANCE/NTUserName)[1]', 'nvarchar(max)') AS [NTUserName],
							@message_body.value('(/EVENT_INSTANCE/NTDomainName)[1]', 'nvarchar(max)') AS [NTDomainName],
							@message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'nvarchar(max)') AS [HostName],
							@message_body.value('(/EVENT_INSTANCE/ClientProcessID)[1]', 'nvarchar(max)') AS [ClientProcessID],
							@message_body.value('(/EVENT_INSTANCE/ApplicationName)[1]', 'nvarchar(max)') AS [ApplicationName],
							@message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(max)') AS [LoginName],
							@message_body.value('(/EVENT_INSTANCE/StartTime)[1]', 'nvarchar(max)') AS [StartTime],
							@message_body.value('(/EVENT_INSTANCE/EventSubClass)[1]', 'nvarchar(max)') AS [EventSubClass],
							@message_body.value('(/EVENT_INSTANCE/Success)[1]', 'nvarchar(max)') AS [Success],
							@message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(max)') AS [ServerName],
							@message_body.value('(/EVENT_INSTANCE/State)[1]', 'nvarchar(max)') AS [State],
							@message_body.value('(/EVENT_INSTANCE/Error)[1]', 'nvarchar(max)') AS [Error],
							@message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(max)') AS [DatabaseName],
							@message_body.value('(/EVENT_INSTANCE/RequestID)[1]', 'nvarchar(max)') AS [RequestID],
							@message_body.value('(/EVENT_INSTANCE/EventSequence)[1]', 'nvarchar(max)') AS [EventSequence],
							@message_body.value('(/EVENT_INSTANCE/Type)[1]', 'nvarchar(max)') AS [Type],
							@message_body.value('(/EVENT_INSTANCE/IsSystem)[1]', 'nvarchar(max)') AS [IsSystem],
							@message_body.value('(/EVENT_INSTANCE/SessionLoginName)[1]', 'nvarchar(max)') AS [SessionLoginName];  
				END;
             END;
     END;
GO


-----------------------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER QUEUE [Audit_Erros_Login_Queue]
WITH ACTIVATION
(
   STATUS = ON,
   PROCEDURE_NAME = Management.[sp_ErrorLogin],
   MAX_QUEUE_READERS = 1,
   EXECUTE AS OWNER
);
GO