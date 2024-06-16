ALTER PROCEDURE Management.[sp_ErrorLogin]
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
		SET NOCOUNT OFF;
     END;
GO
