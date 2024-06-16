use IntegraTICravil
go
ALTER PROCEDURE Management.[sp_AlterObjects]
WITH EXECUTE AS OWNER, ENCRYPTION
AS
 BEGIN
     SET NOCOUNT ON;
 
     DECLARE @message_body XML;
 
     WHILE(1 = 1)
         BEGIN
             WAITFOR(
             RECEIVE TOP (1) @message_body = CAST([message_body] AS XML) FROM [dbo].[Audit_AlterObjects_Queue]), TIMEOUT 1000;
 
             IF(@@RowCount = 1)
                 BEGIN
                     INSERT INTO IntegraTICravil.Management.DDLTransaction
                     (DateDDl ,                      
                      [PostTime],
                      [SPID],
                      [ServerName],
					  [DatabaseName],
					  [SchemaName],
					  DatabaseUser,
                      LoginUser,                         
					  Hostname,                                   
					  [EventType],
                       ObjectName,
                      [ObjectType],
                      Query
					
                     )
                     SELECT GETDATE(),
							@message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'nvarchar(max)') AS [PostTime],
							@message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'nvarchar(max)') AS [SPID],
							@message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'nvarchar(max)') AS [ServerName],
							@message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'nvarchar(max)') AS [DatabaseName],
							@message_body.value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(max)') AS [SchemaName],
							@message_body.value('(/EVENT_INSTANCE/UserName)[1]', 'nvarchar(max)') AS [UserName],
							@message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'nvarchar(max)') AS [LoginName],	
							--HOST_NAME() AS [HostName],				
						    @message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'nvarchar(max)') AS [HostName],													
                            @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)') AS [EventType],                                                                                                                                                                                                  
                            @message_body.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(max)') AS [ObjectName],
                            @message_body.value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(max)') AS [ObjectType],
                            @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)') AS [CommandText];							
                 END;
         END;
 END;
GO
