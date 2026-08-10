/*
    OBJETIVO: Monitorar eventos DDL (Data Definition Language) no SQL Server
              utilizando Service Broker e Event Notification, armazenando
              todas as alterações de objetos (tabelas, índices, views,
              procedures, funções, triggers, etc.) na tabela DDLTransaction.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    http://www.dbinternals.com.br/?p=1080
*/
-- ============================================================
-- Criação da tabela de auditoria DDL no banco DBA_PerformanceHub
-- ============================================================
USE DBA_PerformanceHub;
GO

CREATE TABLE Management.DDLTransaction
(
    TransID                     INT             IDENTITY(1, 1) NOT NULL
  , DateDDl                     SMALLDATETIME   NULL          DEFAULT GETDATE()
  , PostTime                    NVARCHAR(200)   NULL
  , SPID                        NVARCHAR(200)   NULL
  , ServerName                  NVARCHAR(200)   NULL
  , DatabaseName                NVARCHAR(200)   NULL
  , SchemaName                  NVARCHAR(200)   NULL
  , DatabaseUser                NVARCHAR(100)   NULL          DEFAULT USER_NAME()
  , LoginUser                   NVARCHAR(100)   NULL          DEFAULT SUSER_NAME()
  , LoginUserSQLTransaction     NVARCHAR(100)   NULL          DEFAULT ORIGINAL_LOGIN()
  , Hostname                    NVARCHAR(100)   NULL          DEFAULT HOST_NAME()
  , EventType                   NVARCHAR(200)   NULL          DEFAULT ''
  , ObjectName                  NVARCHAR(200)   NULL          DEFAULT ''
  , ObjectType                  NVARCHAR(200)   NULL          DEFAULT ''
  , Query                       NVARCHAR(MAX)   NULL          DEFAULT ''
  , CONSTRAINT PK_DDLTransaction PRIMARY KEY (TransID)
);

-- ============================================================
-- Migração de dados da tabela antiga (se existir)
-- ============================================================
/*
INSERT INTO DBA_PerformanceHub.Management.DDLTransaction
(
    DateDDl
  , PostTime
  , SPID
  , ServerName
  , DatabaseName
  , SchemaName
  , DatabaseUser
  , LoginUser
  , LoginUserSQLTransaction
  , Hostname
  , EventType
  , ObjectName
  , ObjectType
  , Query
)
SELECT
    DateDDl
  , ''
  , ''
  , ''
  , ''
  , ''
  , DatabaseUser
  , LoginUser
  , LoginUserSQLTransaction
  , Hostname
  , EventType
  , ObjectName
  , ObjectType
  , Query
FROM
    DBA_PerformanceHub.Management.DDLTransaction_Old
ORDER BY
    DateDDl ASC;
*/


-- ============================================================
-- Configuração do Service Broker no banco DBA_PerformanceHub
-- ============================================================
USE DBA_PerformanceHub;
GO

/*
ALTER DATABASE DBA_PerformanceHub SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
ALTER DATABASE DBA_PerformanceHub SET MULTI_USER WITH ROLLBACK IMMEDIATE;
*/

ALTER DATABASE DBA_PerformanceHub SET TRUSTWORTHY ON;
GO

ALTER DATABASE DBA_PerformanceHub SET ENABLE_BROKER;
GO


-- ============================================================
-- Criação da Queue e Service para Event Notification
-- ============================================================
CREATE QUEUE [Audit_AlterObjects_Queue];
GO

CREATE SERVICE [Audit_AlterObjects_Service]
    ON QUEUE [Audit_AlterObjects_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION [Audit_AlterObjects_Event]
    ON SERVER WITH FAN_IN
    FOR
        CREATE_TABLE
      , ALTER_TABLE
      , DROP_TABLE
      , CREATE_INDEX
      , ALTER_INDEX
      , DROP_INDEX
      , CREATE_VIEW
      , ALTER_VIEW
      , DROP_VIEW
      , CREATE_PROCEDURE
      , ALTER_PROCEDURE
      , DROP_PROCEDURE
      , CREATE_FUNCTION
      , ALTER_FUNCTION
      , DROP_FUNCTION
      , CREATE_TRIGGER
      , ALTER_TRIGGER
      , DROP_TRIGGER
      , CREATE_TYPE
      , DROP_TYPE
      , DROP_STATISTICS
      , UPDATE_STATISTICS
      , CREATE_STATISTICS
      , CREATE_QUEUE
      , ALTER_QUEUE
      , DROP_QUEUE
      , CREATE_DATABASE
      , ALTER_DATABASE
      , DROP_DATABASE
      , CREATE_SERVICE
      , ALTER_SERVICE
      , DROP_SERVICE
    TO SERVICE 'Audit_AlterObjects_Service'
      , 'current database';
GO

-- DROP EVENT NOTIFICATION [Audit_AlterObjects_Event] ON SERVER;


-- ============================================================
-- Procedure de ativação da queue (processa eventos DDL)
-- ============================================================
CREATE OR ALTER PROCEDURE Management.sp_AlterObjects
    WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message_body XML;

    WHILE (1 = 1)
    BEGIN
        WAITFOR
        (
            RECEIVE TOP (1)
                @message_body = CAST(message_body AS XML)
            FROM
                dbo.Audit_AlterObjects_Queue
        ), TIMEOUT 1000;

        IF (@@ROWCOUNT = 1)
        BEGIN
            INSERT INTO DBA_PerformanceHub.Management.DDLTransaction
            (
                DateDDl
              , PostTime
              , SPID
              , ServerName
              , DatabaseName
              , SchemaName
              , DatabaseUser
              , LoginUser
              , EventType
              , ObjectName
              , ObjectType
              , Query
            )
            SELECT
                GETDATE()
              , @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/UserName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)');
        END;
    END;
END;
GO


-- ============================================================
-- Ativação da queue
-- ============================================================
ALTER QUEUE [Audit_AlterObjects_Queue]
WITH ACTIVATION
(
    STATUS = ON
  , PROCEDURE_NAME = Management.sp_AlterObjects
  , MAX_QUEUE_READERS = 1
  , EXECUTE AS OWNER
);
GO