---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referências
-- https://msdn.microsoft.com/pt-br/library/ms189529(v=sql.110).aspx
-- https://mlucasg.wordpress.com/2013/02/28/monitorando-bloqueios-no-sql-server/	-- Exemplo de matar processos bloqueados automaticamente
-- https://leka.com.br/category/ti/sql/scripts/
---------------------------------------------------------------------------------------------------------------------------------------------------------
--################################################################################################
-- OBS.: PARA DESABILITAR ESSAS MONITORIAS OU DROPA EVENT NOTIFICATION OU ALTERA QUEUE PARA OFF
--################################################################################################
/***************************************************************************************/
-- listar meus EVENT NOTIFICATION
SELECT * FROM [sys].[server_event_notifications]

/***************************************************************************************/
-- listar os tipos EVENT NOTIFICATION existentes para implementações futuras
SELECT * FROM sys.event_notification_event_types

/***************************************************************************************/
-- mostra status das QUEUE
select * from sys.service_queues

/***************************************************************************************/
-- mostra as procedure vinculadas nas QUEUE
select * from sys.dm_broker_activated_tasks

/***************************************************************************************/
-- Tornando uma QUEUE não disponível, exemplo a seguir torna 
-- a fila ExpenseQueue não disponível para receber mensagens.
ALTER QUEUE [Audit_DBFileGrowth_Queue] WITH STATUS = OFF;

/***************************************************************************************/
-- EVENT NOTIFICATION não pode ser apenas desabilitado, ou cria ou dropa, ex.:
DROP EVENT NOTIFICATION nome_evento  
ON SERVER; 

/***************************************************************************************/
-- Outras validações para identificar

select * from sys.dm_broker_queue_monitors

select * from sys.dm_os_memory_brokers



/*************************************************************** Problema pós Migração ********************************************************************************************************************/
/**********************************************************************************************************************************************************************************************************/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Problema ocorrido mostrado nos alertas
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
An exception occurred while enqueueing a message in the target queue. 
Error: 33009, State: 2. The database owner SID recorded in the master database differs from the database owner SID recorded in database 'IntegraTICravil'. 
You should correct this situation by resetting the owner of database 'IntegraTICravil' using the ALTER AUTHORIZATION statement.
*/
DECLARE @Command VARCHAR(MAX) = 'ALTER AUTHORIZATION ON DATABASE::[Maintenance] TO [admrobson]' 
SELECT @Command = REPLACE(REPLACE(@Command 
            , 'Maintenance', SD.Name)
            , 'admrobson', SL.Name)
FROM master..sysdatabases SD 
JOIN master..syslogins SL ON  SD.SID = SL.SID
WHERE  SD.Name = DB_NAME()
PRINT @Command	-- result -> ALTER AUTHORIZATION ON DATABASE::[IntegraTICravil] TO [CRAVIL\rdornel]
EXEC(@Command)

ALTER AUTHORIZATION ON SCHEMA::Management TO admcravil;    
GO 
 
ALTER AUTHORIZATION ON DATABASE::Maintenance TO [admrobson];
go

SELECT CAST(owner_sid as uniqueidentifier) AS Owner_SID   
FROM sys.databases   
WHERE name = 'Maintenance';--EAB380AE-0DA8-46D7-BE69-EA434B4095E0

-- VER OWNER DE CADA DATABASE
use master
go
SELECT d.name, d.owner_sid, sl.name   
FROM sys.databases AS d  
JOIN sys.sql_logins AS sl  
ON d.owner_sid = sl.sid; 


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
declare @user varchar(50)
SELECT  @user = quotename(SL.Name)
  FROM  master..sysdatabases SD inner join master..syslogins SL
    on  SD.SID = SL.SID
 Where  SD.Name = DB_NAME()

select @user -- deu como [CRAVIL\rdornel]
exec('exec sp_changedbowner ' + @user)

-- Trocando o proprietário
EXEC sp_changedbowner 'admrobson'


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Restore sid when db restored from backup... 
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Command NVARCHAR(MAX) 
SET @Command = N'ALTER AUTHORIZATION ON DATABASE::<<DatabaseName>> TO <<LoginName>>' 
SELECT @Command = REPLACE 
                  ( 
                      REPLACE(@Command, N'<<DatabaseName>>', QUOTENAME(SD.Name)) 
                      , N'<<LoginName>>' 
                      ,
                      QUOTENAME
                      (
                          COALESCE
                          (
                               SL.name 
                              ,(SELECT TOP 1 name FROM sys.server_principals WHERE type_desc = 'SQL_LOGIN' AND is_disabled = 'false' ORDER BY principal_id ASC )
                          )
                      )
                  ) 
FROM sys.databases AS SD
LEFT JOIN sys.server_principals  AS SL 
    ON SL.SID = SD.owner_sid 
WHERE SD.Name = DB_NAME() 

PRINT @command 
EXECUTE(@command) 
GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @SQL nvarchar(max)
BEGIN TRY
    SET @SQL = 'ALTER DATABASE ' + db_name() + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE '
    PRINT @SQL
    EXEC sp_executesql @SQL
END TRY
BEGIN CATCH
    SET @SQL = 'ALTER DATABASE ' + db_name() + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE '
    PRINT @SQL
    EXEC sp_executesql @SQL
END CATCH
GO



ALTER DATABASE IntegraTICravil SET TRUSTWORTHY ON;
GO



EXEC sp_configure 'show advanced options', 1
GO
sp_configure 'blocked process threshold', 10 ;   
GO
RECONFIGURE WITH OVERRIDE;


--USE IntegraTICravil
--GO
--CREATE EVENT NOTIFICATION [Audit_Blocked_Process_Event] 
--ON SERVER 
--with fan_in
--FOR BLOCKED_PROCESS_REPORT 
--TO SERVICE N'Audit_Blocked_Process_Service', N'current database';
--GO

--USE IntegraTICravil
--GO
--Alter Queue [Audit_Blocked_Process_Queue]
--With Activation 
--(
--   Status = ON,   
--   Procedure_Name = Management.sp_BlockedProcess,
--   Max_Queue_Readers = 3,	-- número máximo de instâncias de procedimento armazenado que o Service Broker inicia para essa fila.
--   Execute as Owner   
--);
--GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE EVENT NOTIFICATION [Audit_DBFileGrowth_Event]
--    ON SERVER WITH FAN_IN 
--    FOR DATA_FILE_AUTO_GROW, 
--        LOG_FILE_AUTO_GROW 
--    TO SERVICE 'Audit_DBFileGrowth_Service', 'current database';
--GO

--ALTER QUEUE [Audit_DBFileGrowth_Queue] 
--WITH ACTIVATION
--( 
--  STATUS = ON, 
--  PROCEDURE_NAME = Management.[sp_DBFileGrowth], 
--  MAX_QUEUE_READERS = 1, 
--  EXECUTE AS OWNER
--);
--GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE EVENT NOTIFICATION [Audit_ServerConfig_Event] 
--    ON SERVER WITH FAN_IN 
--    FOR ALTER_INSTANCE 
--    TO SERVICE 'Audit_ServerConfig_Service', 'current database';
--GO

--ALTER QUEUE [Audit_ServerConfig_Queue] 
--WITH ACTIVATION
--(
--  STATUS = ON, 
--  PROCEDURE_NAME = Management.sp_ServerConfig, 
--  MAX_QUEUE_READERS = 1, 
--  EXECUTE AS OWNER
--);
--GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE EVENT NOTIFICATION [Audit_AlterObjects_Event] 
--    ON SERVER WITH FAN_IN
--    FOR 
--	   CREATE_TABLE,
--	   ALTER_TABLE,
--	   DROP_TABLE,
--	   CREATE_INDEX,
--	   ALTER_INDEX,
--	   DROP_INDEX,
--	   CREATE_VIEW,
--	   ALTER_VIEW,
--	   DROP_VIEW,
--	   CREATE_PROCEDURE,
--	   ALTER_PROCEDURE,
--	   DROP_PROCEDURE,
--	   CREATE_FUNCTION,
--	   ALTER_FUNCTION,
--	   DROP_FUNCTION,
--	   CREATE_TRIGGER,
--	   ALTER_TRIGGER,
--	   DROP_TRIGGER,
--	   CREATE_TYPE,
--	   DROP_TYPE,
--	   DROP_STATISTICS,
--	   UPDATE_STATISTICS,	   
--	   CREATE_STATISTICS,
--	   CREATE_QUEUE,
--	   ALTER_QUEUE,
--	   DROP_QUEUE,
--	   CREATE_DATABASE,
--	   ALTER_DATABASE,
--	   DROP_DATABASE,
--	   CREATE_SERVICE,
--	   ALTER_SERVICE,
--	   DROP_SERVICE	 
	   
--    TO SERVICE 'Audit_AlterObjects_Service', 'current database';
--GO
--USE IntegraTICravil
--GO
--ALTER QUEUE [Audit_AlterObjects_Queue] WITH ACTIVATION
--(
--  STATUS = ON, 
--  PROCEDURE_NAME = Management.[sp_AlterObjects], 
--  MAX_QUEUE_READERS = 1, 
--  EXECUTE AS OWNER
--);
--GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--USE IntegraTICravil
--GO
--CREATE EVENT NOTIFICATION Audit_DeadLock_Event ON SERVER
--WITH FAN_IN 
--FOR DEADLOCK_GRAPH 
--TO SERVICE 'Audit_DeadLock_Service', 'current database';

--USE IntegraTICravil
--go
--Alter Queue Audit_DeadLock_Queue
--With Activation
--(
--   Status = ON,
--   Procedure_Name = Management.sp_DeadLock,
--   Max_Queue_Readers = 1,
--   Execute as Owner
--);
--GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE EVENT NOTIFICATION [Audit_Erros_Login_Event] ON SERVER FOR AUDIT_LOGIN_FAILED TO SERVICE N'Audit_Erros_Login_Service', N'current database';
--GO

--ALTER QUEUE [Audit_Erros_Login_Queue]
--WITH ACTIVATION
--(
--   STATUS = ON,
--   PROCEDURE_NAME = Management.[sp_ErrorLogin],
--   MAX_QUEUE_READERS = 1,
--   EXECUTE AS OWNER
--);
--GO


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--CREATE EVENT NOTIFICATION Audit_SecurityChange_Event
--    ON SERVER WITH FAN_IN
--    FOR CREATE_LOGIN,
--        ALTER_LOGIN,
--	   DROP_LOGIN,
--	   ADD_SERVER_ROLE_MEMBER,
--	   DROP_SERVER_ROLE_MEMBER,
--	   DDL_DATABASE_SECURITY_EVENTS
--    TO SERVICE 'Audit_SecurityChange_Service', 'current database';
--GO

--ALTER QUEUE Audit_SecurityChange_Queue
--WITH ACTIVATION
--(
--   STATUS = ON,
--   PROCEDURE_NAME = Management.sp_SecurityChange,
--   MAX_QUEUE_READERS = 1,
--   EXECUTE AS OWNER
--);
--GO