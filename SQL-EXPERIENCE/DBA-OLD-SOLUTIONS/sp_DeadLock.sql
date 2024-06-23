USE IntegraTICravil
GO

ALTER PROCEDURE Management.[sp_DeadLock]

WITH EXECUTE AS OWNER, ENCRYPTION

AS
 BEGIN
     DECLARE @conversation_handle UNIQUEIDENTIFIER;
     DECLARE @message_body XML;
     DECLARE @message_type_name NVARCHAR(128);
     DECLARE @deadlock_graph XML;
     DECLARE @event_datetime DATETIME;
     DECLARE @deadlock_id INT;
     DECLARE @DBname SYSNAME;

     BEGIN TRY
         BEGIN TRAN;
         WAITFOR(
         RECEIVE TOP (1) @conversation_handle = [conversation_handle],
                         @message_body = CAST([message_body] AS XML),
                         @message_type_name = [message_type_name] FROM [dbo].[Audit_DeadLock_Queue]), TIMEOUT 10000;

         IF @message_type_name = 'http://schemas.microsoft.com/SQL/Notifications/EventNotification'
            AND @message_body.exist('(/EVENT_INSTANCE/TextData/deadlock-list)') = 1
             BEGIN

                 SELECT @deadlock_graph = @message_body.query('(/EVENT_INSTANCE/TextData/deadlock-list)'),
                        @event_datetime = @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime'),
                        @DBname = DB_NAME(@message_body.value('(//*/process/@currentdb)[1]', 'varchar(10)'));

                 INSERT INTO IntegraTICravil.Management.HistoryDeadLock
                 ([DateDeadLock],
                  [DatabaseName],
                  [GraphDeadLock]
                 )
                 VALUES
                 (@event_datetime,
                  @DBname,
                  @message_body
                 );
             END;
         ELSE
             BEGIN 
                 END CONVERSATION @conversation_handle;
             END;
         COMMIT TRAN;
     END TRY
     BEGIN CATCH
         ROLLBACK TRAN;
     END CATCH;
 END;


GO


