----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referência
-- http://www.dbinternals.com.br/?p=972
-- Coleta todas as alterações de segurança feitas em logins no servidor ou em users nos bancos de dados.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE IntegraTICravil;
GO

CREATE TABLE Management.HistorySecurityChange
(
    ChangeLogID          int IDENTITY(1,1),
    LoginName            SYSNAME,
    UserName             SYSNAME,
    DatabaseName         SYSNAME,
    SchemaName           SYSNAME,
    ObjectName           SYSNAME,
    ObjectType           VARCHAR(50),
    DDLCommand           VARCHAR(MAX),
    EventTime            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT PK_ChangeLogID PRIMARY KEY (ChangeLogID)
);


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE QUEUE Audit_SecurityChange_Queue;
GO
 
CREATE SERVICE Audit_SecurityChange_Service ON QUEUE Audit_SecurityChange_Queue  ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION Audit_SecurityChange_Event
    ON SERVER WITH FAN_IN
    FOR CREATE_LOGIN,
        ALTER_LOGIN,
	   DROP_LOGIN,
	   ADD_SERVER_ROLE_MEMBER,
	   DROP_SERVER_ROLE_MEMBER,
	   DDL_DATABASE_SECURITY_EVENTS
    TO SERVICE 'Audit_SecurityChange_Service', 'current database';
GO

--DROP EVENT NOTIFICATION Audit_SecurityChange_Event  
--ON SERVER; 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE Management.[sp_SecurityChange] 
WITH EXECUTE AS OWNER
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
         RECEIVE TOP(1) @message_body = message_body
         FROM dbo.Audit_SecurityChange_Queue
       ), TIMEOUT 1000;
 
       IF (@@ROWCOUNT = 1)
       BEGIN
        if CONVERT(SYSNAME, @message_body.query('data(/EVENT_INSTANCE/EventType)')) in ('DROP_USER','CREATE_USER','ALTER_USER') or @version>9
        BEGIN
            INSERT INTO Maintenance.Management.HistorySecurityChange(LoginName,UserName,DatabaseName,SchemaName,ObjectName,ObjectType,DDLCommand) 
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
            INSERT INTO Maintenance.Management.HistorySecurityChange(LoginName,UserName,DatabaseName,SchemaName,ObjectName,ObjectType,DDLCommand) 
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


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER QUEUE Audit_SecurityChange_Queue
WITH ACTIVATION
(
   STATUS = ON,
   PROCEDURE_NAME = Management.sp_SecurityChange,
   MAX_QUEUE_READERS = 1,
   EXECUTE AS OWNER
);
GO
