
alter Procedure Management.sp_ServerConfig
With Execute as Owner, ENCRYPTION
as
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
			 INSERT INTO IntegraTICravil.Management.HistoryServerConfig
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