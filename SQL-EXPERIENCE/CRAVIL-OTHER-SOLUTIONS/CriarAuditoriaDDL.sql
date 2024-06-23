---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Fazendo bom uso do service broker
-- http://www.dbinternals.com.br/?p=1080
-- Recriado a tabela que era alimentada apenas com a trigger database
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--use IntegraTICravil
--go
--Create Table Management.DDLTransaction
--(
-- TransID Int Identity(1,1) Primary Key,

-- DateDDl smallDateTime Default GetDate(),	

-- [PostTime] NVarchar(200),
-- [SPID]	NVarchar(200),
-- [ServerName] NVarchar(200),
-- [DatabaseName] NVarchar(200),
-- [SchemaName] NVarchar(200),

-- DatabaseUser NVarchar(100) Default User_Name(),	

-- LoginUser NVarchar(100) Default Suser_Name(),	

-- --LoginUserSQLTransaction NVarchar(100) Default Original_Login(),

-- Hostname NVarchar(100) Default host_name(),	

-- EventType NVarchar(200) default '',	

-- ObjectName NVarchar(200) default '',	

-- ObjectType NVarchar(200) default '',	

-- Query NVarchar(Max) default ''		
-- )
-----------------------------------------------------------------------------------------------------------------------------------------
 --insert into IntegraTICravil.Management.DDLTransaction
 --select 
 -- DateDDl ,	

 --'',
 --''	,
 --'' ,
 --'' ,
 --'' ,

 --DatabaseUser ,	

 --LoginUser ,	

 --LoginUserSQLTransaction ,

 --Hostname ,	

 --EventType ,	

 --ObjectName ,	

 --ObjectType ,	

 --Query 
 --from IntegraTICravil.Management.DDLTransaction_Old
 --order by DateDDl asc
-----------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
--------------------------------------------------------------------------------------------------------------
-- Colocando o Banco de Dados para Single_User 
--------------------------------------------------------------------------------------------------------------
Alter Database Maintenance
Set Single_User With Rollback Immediate

--------------------------------------------------------------------------------------------------------------
-- Colocando o Banco de Dados que esta como Single_User para Multi_User
--------------------------------------------------------------------------------------------------------------
Alter Database Maintenance
Set Multi_User With Rollback Immediate

--------------------------------------------------------------------------------------------------------------
ALTER DATABASE Maintenance SET TRUSTWORTHY ON;
GO

ALTER DATABASE Maintenance SET ENABLE_BROKER ;
GO

CREATE QUEUE [Audit_AlterObjects_Queue];
GO

CREATE SERVICE [Audit_AlterObjects_Service] 
ON QUEUE [Audit_AlterObjects_Queue]([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION [Audit_AlterObjects_Event] 
    ON SERVER WITH FAN_IN
    FOR 
	   CREATE_TABLE,
	   ALTER_TABLE,
	   DROP_TABLE,
	   CREATE_INDEX,
	   ALTER_INDEX,
	   DROP_INDEX,
	   CREATE_VIEW,
	   ALTER_VIEW,
	   DROP_VIEW,
	   CREATE_PROCEDURE,
	   ALTER_PROCEDURE,
	   DROP_PROCEDURE,
	   CREATE_FUNCTION,
	   ALTER_FUNCTION,
	   DROP_FUNCTION,
	   CREATE_TRIGGER,
	   ALTER_TRIGGER,
	   DROP_TRIGGER,
	   CREATE_TYPE,
	   DROP_TYPE,
	   DROP_STATISTICS,
	   UPDATE_STATISTICS,	   
	   CREATE_STATISTICS,
	   CREATE_QUEUE,
	   ALTER_QUEUE,
	   DROP_QUEUE,
	   CREATE_DATABASE,
	   ALTER_DATABASE,
	   DROP_DATABASE,
	   CREATE_SERVICE,
	   ALTER_SERVICE,
	   DROP_SERVICE	 
	   
    TO SERVICE 'Audit_AlterObjects_Service', 'current database';
GO

DROP EVENT NOTIFICATION [Audit_AlterObjects_Event]  
ON SERVER; 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Necessário fazer procedure para vincular à queue
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go
create or alter PROCEDURE Management.[sp_AlterObjects]
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
                     INSERT INTO Maintenance.Management.DDLTransaction
                     (DateDDl ,                      
                      [PostTime],
                      [SPID],
                      [ServerName],
					  [DatabaseName],
					  [SchemaName],
					  DatabaseUser,
                      LoginUser,                         					                                     
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
                            @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'nvarchar(max)') AS [EventType],                                                                                                                                                                                                  
                            @message_body.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(max)') AS [ObjectName],
                            @message_body.value('(/EVENT_INSTANCE/ObjectType)[1]', 'nvarchar(max)') AS [ObjectType],
                            @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)') AS [CommandText];
                 END;
         END;
 END;
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- VINCULANDO
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
ALTER QUEUE [Audit_AlterObjects_Queue] WITH ACTIVATION
(
  STATUS = ON, 
  PROCEDURE_NAME = Management.[sp_AlterObjects], 
  MAX_QUEUE_READERS = 1, 
  EXECUTE AS OWNER
);
GO
