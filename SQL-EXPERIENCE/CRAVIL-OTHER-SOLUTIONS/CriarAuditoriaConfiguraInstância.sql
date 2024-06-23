----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referência
-- http://www.dbinternals.com.br/?p=1077
-- Coleta todas as alterações de segurança feitas em logins no servidor ou em users nos bancos de dados.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go

CREATE TABLE Management.HistoryServerConfig
(	[IdServerConfig] [int] IDENTITY(1,1) NOT NULL,
	DateInsert [datetime] NULL,
	[EventType] [nvarchar](max) NULL,
	[PostTime] [nvarchar](max) NULL,
	[SPID] [nvarchar](max) NULL,
	[ServerName] [nvarchar](max) NULL,
	[LoginName] [nvarchar](max) NULL,
	[PropertyName] [nvarchar](max) NULL,
	[PropertyValue] [nvarchar](max) NULL,
	[Parameters] [xml] NULL,
	[CommandText] [nvarchar](max) NULL
 CONSTRAINT PK_tb_ServerConfig PRIMARY KEY([IdServerConfig])
);


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE QUEUE [Audit_ServerConfig_Queue];
GO

CREATE SERVICE Audit_ServerConfig_Service ON QUEUE [Audit_ServerConfig_Queue]
([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION [Audit_ServerConfig_Event] 
    ON SERVER WITH FAN_IN 
    FOR ALTER_INSTANCE 
    TO SERVICE 'Audit_ServerConfig_Service', 'current database';
GO

DROP EVENT NOTIFICATION [Audit_ServerConfig_Event]  
ON SERVER; 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Management.sp_ServerConfig
WITH EXECUTE AS OWNER, ENCRYPTION
AS
Begin
    Set NoCount On;

    Declare @message_body XML;

    While (1 = 1)
    Begin
       WaitFor 

       ( 
         RECEIVE TOP (1) @message_body = CAST(message_body AS XML) 
            From dbo.Audit_ServerConfig_Queue
       ), TimeOut 1000;

       If (@@RowCount = 1)
       Begin 
			 INSERT INTO Maintenance.Management.HistoryServerConfig
			 (   DateInsert,
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
			 SELECT GETDATE(),
				    @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)') AS [EventType],
				    @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'nvarchar(max)') AS [PostTime],
				    @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'nvarchar(max)') AS [SPID],
				    @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(max)') AS [ServerName],
				    @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(max)') AS [LoginName],
				    @message_body.value('(/EVENT_INSTANCE/PropertyName)[1]', 'nvarchar(max)') AS [PropertyName],
				    @message_body.value('(/EVENT_INSTANCE/PropertyValue)[1]', 'nvarchar(max)') AS [PropertyValue],
				    CAST(@message_body.query('/EVENT_INSTANCE/Parameters/*') AS XML) AS [Parameters],
				    @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)') AS [CommandText];
       End
    End
	Set NoCount off;
End
Go


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER QUEUE [Audit_ServerConfig_Queue] 
WITH ACTIVATION
(
  STATUS = ON, 
  PROCEDURE_NAME = Management.sp_ServerConfig, 
  MAX_QUEUE_READERS = 1, 
  EXECUTE AS OWNER
);
GO