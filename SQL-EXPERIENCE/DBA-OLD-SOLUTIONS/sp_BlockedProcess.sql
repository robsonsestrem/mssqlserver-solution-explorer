USE IntegraTICravil
GO

ALTER PROCEDURE Management.[sp_BlockedProcess]

WITH EXECUTE AS OWNER, ENCRYPTION

AS
 BEGIN
     SET NOCOUNT ON;
	 SET ARITHABORT ON; --adicionado 23-03-2017

     DECLARE @message_body XML;
     DECLARE @event_datetime DATETIME;
     DECLARE @DBname SYSNAME;

     WHILE(1 = 1)
         BEGIN
             WAITFOR(
             RECEIVE TOP (1) @message_body = CAST([message_body] AS XML) FROM [dbo].[Audit_Blocked_Process_Queue]), TIMEOUT 1000;

             IF(@@RowCount = 1)
                 BEGIN
				 -- seta variáveis
                 SELECT @event_datetime = @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime'),
                        @DBname = DB_NAME(@message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@currentdb)[1]', 'varchar(10)'));

				 -- insere registros
                     INSERT INTO IntegraTICravil.Management.HistoryBlockedProcess
                     (DateBlock,
					  DatabaseName,
                      GraphBlock
					 )
                     SELECT @event_datetime,
				        @DBname,
                        @message_body;
                 END;
         END;
 END;

GO


