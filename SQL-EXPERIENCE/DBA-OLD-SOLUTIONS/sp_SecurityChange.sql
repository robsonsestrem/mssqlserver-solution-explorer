ALTER PROCEDURE Management.[sp_SecurityChange]
WITH EXECUTE AS OWNER, ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @version int
    DECLARE @message_body XML;
    set @version = (SELECT convert (int,REPLACE (LEFT (CONVERT (varchar, SERVERPROPERTY ('ProductVersion')),2), '.', '')))
 
    WHILE (1 = 1)
    BEGIN
       WAITFOR 
       ( 
         RECEIVE TOP(1) @message_body = message_body FROM dbo.Audit_SecurityChange_Queue
       ), TIMEOUT 1000;
 
       IF (@@ROWCOUNT = 1)
       BEGIN
        if CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/EventType)')) in ('DROP_USER','CREATE_USER','ALTER_USER') or @version>9
        BEGIN
            INSERT INTO IntegraTICravil.Management.HistorySecurityChange(LoginName,UserName,DatabaseName,SchemaName,ObjectName,ObjectType,DDLCommand) 
            SELECT CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/LoginName)')), 
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/UserName)')),
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/DatabaseName)')),
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/DefaultSchema)')),
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/ObjectName)')),
                CONVERT(VARCHAR(50), @message_body.query('data(/EVENT_INSTANCE/ObjectType)')),
                CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/TSQLCommand/CommandText)'))
        END
        ELSE
        BEGIN
            INSERT INTO IntegraTICravil.Management.HistorySecurityChange(LoginName,UserName,DatabaseName,SchemaName,ObjectName,ObjectType,DDLCommand) 
            SELECT CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/LoginName)')), 
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/UserName)')),
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/DatabaseName)')),
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/SchemaName)')),
                CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/ObjectName)')),
                CONVERT(VARCHAR(50), @message_body.query('data(/EVENT_INSTANCE/ObjectType)')),
                CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/EventType)')) + ' ' + 
                CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/RoleName)')) + ' FOR ' +
                CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/LoginType)')) + ' ' +
                CONVERT(VARCHAR(MAX), @message_body.query('data(/EVENT_INSTANCE/ObjectName)'))
        END
       END
    END -- fim do while
	SET NOCOUNT ON;
END