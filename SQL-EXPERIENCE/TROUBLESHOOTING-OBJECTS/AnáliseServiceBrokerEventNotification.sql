/*
    OBJETIVO: Gerenciar e diagnosticar Event Notifications e Service Broker na instância,
              incluindo manutenção de filas, correção de owner SID pós-restauração
              e configuração de monitoramento de processos bloqueados.
    PROJETO: mssqlserver-solution-explorer
    REFERÊNCIAS:
        https://msdn.microsoft.com/pt-br/library/ms189529(v=sql.110).aspx
        https://mlucasg.wordpress.com/2013/02/28/monitorando-bloqueios-no-sql-server/
        https://leka.com.br/category/ti/sql/scripts/
*/

-- ################################################################################################
-- OBS.: PARA DESABILITAR ESSAS MONITORIAS: DROPA O EVENT NOTIFICATION OU ALTERA QUEUE PARA OFF
-- ################################################################################################

-- ---------------------------------------------------------------------------
-- Diagnóstico: lista Event Notifications registrados no servidor
-- ---------------------------------------------------------------------------
SELECT * FROM [sys].[server_event_notifications];

-- ---------------------------------------------------------------------------
-- Diagnóstico: tipos de Event Notification disponíveis para implementações futuras
-- ---------------------------------------------------------------------------
SELECT * FROM sys.event_notification_event_types;

-- ---------------------------------------------------------------------------
-- Diagnóstico: status das Service Queues
-- ---------------------------------------------------------------------------
SELECT * FROM sys.service_queues;

-- ---------------------------------------------------------------------------
-- Diagnóstico: stored procedures vinculadas às Queues (activated tasks)
-- ---------------------------------------------------------------------------
SELECT * FROM sys.dm_broker_activated_tasks;

-- ---------------------------------------------------------------------------
-- Desabilita uma Queue para parar de receber mensagens
-- ---------------------------------------------------------------------------
ALTER QUEUE [Audit_DBFileGrowth_Queue] WITH STATUS = OFF;

-- ---------------------------------------------------------------------------
-- Event Notifications não podem ser desabilitadas — apenas criadas ou removidas
-- ---------------------------------------------------------------------------
DROP EVENT NOTIFICATION nome_evento
ON SERVER;

-- ---------------------------------------------------------------------------
-- Diagnóstico: monitores de fila e alocação de memória do broker
-- ---------------------------------------------------------------------------
SELECT * FROM sys.dm_broker_queue_monitors;

SELECT * FROM sys.dm_os_memory_brokers;

-- ---------------------------------------------------------------------------
-- Problema pós-migração: corrige divergência de owner SID entre master e banco
-- ---------------------------------------------------------------------------
/*
An exception occurred while enqueueing a message in the target queue.
Error: 33009, State: 2. The database owner SID recorded in the master database differs from the database owner SID recorded in database 'IntegraTICravil'.
You should correct this situation by resetting the owner of database 'IntegraTICravil' using the ALTER AUTHORIZATION statement.
*/

-- Gera e executa ALTER AUTHORIZATION dinamicamente para o banco corrente
DECLARE @Command VARCHAR(MAX) = 'ALTER AUTHORIZATION ON DATABASE::[YOUR_DATABASE] TO [admrobson]';

SELECT @Command = REPLACE(REPLACE(@Command
    , 'YOUR_DATABASE', SD.Name)
    , 'admrobson', SL.Name)
FROM master..sysdatabases AS SD
JOIN master..syslogins AS SL
    ON SD.SID = SL.SID
WHERE SD.Name = DB_NAME();

PRINT @Command;    -- result -> ALTER AUTHORIZATION ON DATABASE::[IntegraTICravil] TO [CRAVIL\rdornel]
EXEC(@Command);

ALTER AUTHORIZATION ON SCHEMA::Management TO admcravil;
GO

ALTER AUTHORIZATION ON DATABASE::YOUR_DATABASE TO [admrobson];
GO

-- Verifica o owner SID atual do banco YOUR_DATABASE
SELECT CAST(owner_sid AS UNIQUEIDENTIFIER) AS Owner_SID
FROM sys.databases
WHERE name = 'YOUR_DATABASE';    -- EAB380AE-0DA8-46D7-BE69-EA434B4095E0

-- ---------------------------------------------------------------------------
-- Diagnóstico: owner de cada database na instância
-- ---------------------------------------------------------------------------
USE master;
GO

SELECT
    d.name
    ,d.owner_sid
    ,sl.name
FROM sys.databases AS d
JOIN sys.sql_logins AS sl
    ON d.owner_sid = sl.sid;

-- ---------------------------------------------------------------------------
-- Altera o proprietário do banco para o login atual do owner em master
-- ---------------------------------------------------------------------------
DECLARE @user VARCHAR(50);

SELECT @user = QUOTENAME(SL.Name)
FROM master..sysdatabases AS SD
INNER JOIN master..syslogins AS SL
    ON SD.SID = SL.SID
WHERE SD.Name = DB_NAME();

SELECT @user;    -- deu como [CRAVIL\rdornel]
EXEC('EXEC sp_changedbowner ' + @user);

-- Troca o proprietário diretamente
EXEC sp_changedbowner 'admrobson';



-- ---------------------------------------------------------------------------
-- Restaura o owner SID após restore de backup (corrige owner divergente)
-- ---------------------------------------------------------------------------
DECLARE @Command NVARCHAR(MAX);

SET @Command = N'ALTER AUTHORIZATION ON DATABASE::<<DatabaseName>> TO <<LoginName>>';

SELECT @Command = REPLACE(
    REPLACE(@Command, N'<<DatabaseName>>', QUOTENAME(SD.Name))
    ,N'<<LoginName>>'
    ,QUOTENAME(
        COALESCE(
            SL.name
            ,(SELECT TOP 1 name FROM sys.server_principals WHERE type_desc = 'SQL_LOGIN' AND is_disabled = 'false' ORDER BY principal_id ASC)
        )
    )
)
FROM sys.databases AS SD
LEFT JOIN sys.server_principals AS SL
    ON SL.SID = SD.owner_sid
WHERE SD.Name = DB_NAME();

PRINT @Command;
EXECUTE(@Command);
GO

-- ---------------------------------------------------------------------------
-- Habilita o Service Broker — tenta ENABLE_BROKER; fallback para NEW_BROKER
-- ---------------------------------------------------------------------------
DECLARE @SQL NVARCHAR(MAX);

BEGIN TRY
    SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE';
    PRINT @SQL;
    EXEC sp_executesql @SQL;
END TRY
BEGIN CATCH
    SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE';
    PRINT @SQL;
    EXEC sp_executesql @SQL;
END CATCH;
GO

ALTER DATABASE IntegraTICravil SET TRUSTWORTHY ON;
GO

-- ---------------------------------------------------------------------------
-- Configura o limiar para geração de relatórios de blocked processes (segundos)
-- ---------------------------------------------------------------------------
EXEC sp_configure 'show advanced options', 1;
GO

sp_configure 'blocked process threshold', 10;
GO

RECONFIGURE WITH OVERRIDE;


-- ===========================================================================
-- TEMPLATES DE EVENT NOTIFICATION (comentados — desabilitados por padrão)
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- [TEMPLATE] Monitoramento de Blocked Process: Audit_Blocked_Process_Event
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- [TEMPLATE] Crescimento automático de arquivo: Audit_DBFileGrowth_Event
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- [TEMPLATE] Alterações de configuração: Audit_ServerConfig_Event
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- [TEMPLATE] Alterações de objetos DDL: Audit_AlterObjects_Event
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- [TEMPLATE] Monitoramento de Deadlock: Audit_DeadLock_Event
-- ---------------------------------------------------------------------------
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


-- ---------------------------------------------------------------------------
-- [TEMPLATE] Falhas de login: Audit_Erros_Login_Event
-- ---------------------------------------------------------------------------
--CREATE EVENT NOTIFICATION [Audit_Erros_Login_Event] ON SERVER FOR AUDIT_LOGIN_FAILED
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


-- ---------------------------------------------------------------------------
-- [TEMPLATE] Alterações de segurança: Audit_SecurityChange_Event
-- ---------------------------------------------------------------------------
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