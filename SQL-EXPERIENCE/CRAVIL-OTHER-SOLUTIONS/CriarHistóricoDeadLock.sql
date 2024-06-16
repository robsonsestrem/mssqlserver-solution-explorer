---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Já de início, é necessário alterar a configuração habilitando o Broker e o Trustworthy:
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE GesCooper90;
GO
ALTER DATABASE integraTICravil SET ENABLE_BROKER ;
GO

-------------------------------------------------------
-- caso de problema de mesmo ID do Service Broker
--ALTER DATABASE guru6 SET NEW_BROKER;
-------------------------------------------------------
ALTER DATABASE integraTICravil SET TRUSTWORTHY ON;
GO

------------------------------------------------------------------------------------------------
-- Automatizando o processo caso tenha problema de mesmo ID do Service Broker
------------------------------------------------------------------------------------------------
--DECLARE @SQL nvarchar(max)
--BEGIN TRY
--    SET @SQL = 'ALTER DATABASE ' + db_name() + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE '
--    PRINT @SQL
--    EXEC sp_executesql @SQL
--END TRY
--BEGIN CATCH
--    SET @SQL = 'ALTER DATABASE ' + db_name() + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE '
--    PRINT @SQL
--    EXEC sp_executesql @SQL
--END CATCH
--GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Indicar em quanto tempo, em segundos, após o início do lock o report (queue) é criado. Isso evita a geração de dados em excesso por locks que duram poucos segundos. 
-- vou parametrizar o servidor para gerar o evento/report (queue) de lock somente se o lock tiver mais de 10 segundos.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EXEC sp_configure 'show advanced options', 1
GO
sp_configure 'blocked process threshold', 10 ;   
GO
RECONFIGURE WITH OVERRIDE;
--Configuration option 'show advanced options' changed from 1 to 1. Run the RECONFIGURE statement to install.
--Configuration option 'blocked process threshold (s)' changed from 10 to 10. Run the RECONFIGURE statement to install.
--EXEC sp_configure 'show advanced options', 1
--GO
--RECONFIGURE
--GO
--EXEC sp_configure 'blocked process threshold', 10
--GO
--RECONFIGURE
--GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Primeiro crio a tabela que irá receber todas os eventos de DeadLock dos bancos de dados.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
 
IF EXISTS (SELECT name FROM sys.tables WHERE name = 'HistoryDeadLock')
	  DROP TABLE HistoryDeadLock;
GO
CREATE TABLE HistoryDeadLock
([IdDeadLock]     [INT] IDENTITY(1, 1) NOT NULL,
 [DateDeadLock]     [DATETIME] NULL,
 [DatabaseName] VARCHAR(255),
 [GraphDeadLock]     XML
 CONSTRAINT [PK_DeadLock] PRIMARY KEY([IdDeadLock])
);


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Em seguida crio a QUEUE, o Service e o Event Notification para esta coleta, note que na criação do Event Notification. 
-- Veja na criação dos Event a ação que é monitorada é a DEADLOCK_GRAPH, que possui o gráfico, mostrado mais abaixo como extrair.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
CREATE QUEUE Audit_DeadLock_Queue; 
GO

CREATE SERVICE Audit_DeadLock_Service ON QUEUE Audit_DeadLock_Queue ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]); 
GO 

USE Maintenance
GO
CREATE EVENT NOTIFICATION Audit_DeadLock_Event ON SERVER
WITH FAN_IN 
FOR DEADLOCK_GRAPH 
TO SERVICE 'Audit_DeadLock_Service', 'current database';

DROP EVENT NOTIFICATION Audit_DeadLock_Event  
ON SERVER; 


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Os eventos vem como XML (EVENT_INSTANCE) a partir de um “select” na QUEUE Audit_DeadLock_Queue. Como a stored procedure é acionada a cada evento, 
-- ela capta da Audit_DeadLock_Queue o XML, desserializa e grava cada campo na tabela HistoryDeadLock.
-- Sobre o TIMEOUT -> mensagens disponíveis para o próximo grupo de conversa disponível na fila Audit_DeadLock_Queue. 
-- >>> A instrução aguarda durante 10 segundos ou até que pelo menos uma mensagem esteja disponível, o que ocorrer primeiro. 
-- A instrução retornará um conjunto de resultados que contém todas as colunas de mensagem se pelo menos uma mensagem estiver disponível. 
-- Caso contrário, a instrução retornará um conjunto de resultados vazio.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
-- verificar quem é o owner do schema
CREATE PROCEDURE Management.[sp_DeadLock]
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

                 INSERT INTO Maintenance.Management.HistoryDeadLock
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


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Em seguida vou configurar a QUEUE Audit_DeadLock_Queue para acionar a stored procedure pr_DeadLock houver um evento e já ativar a QUEUE.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
go
Alter Queue Audit_DeadLock_Queue
With Activation
(
   Status = ON,
   Procedure_Name = Management.sp_DeadLock,
   Max_Queue_Readers = 1,
   Execute as Owner
);
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Pelo Management Studio, se você clicar no conteudo do campo gra_DeadLock, será aberto o conteúdo em uma nova guia no formato XML com os dados do deadlock, 
-- mas agora vamos mostrar essas informações de uma forma mais amigável.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use Maintenance
go
;WITH cte_DeadLock
     AS (SELECT top 10 IdDeadLock,
                DateDeadLock,
                GraphDeadLock
           FROM Management.HistoryDeadLock),
     Victims
     AS (SELECT [ID] = [Victims].[List].value('@id', 'varchar(50)')
           FROM [cte_DeadLock]
                CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/victim-list/victimProcess') AS [Victims]([List])),
     Locks
     AS (SELECT [cte_DeadLock].IdDeadLock,
                [MainLock].[Process].value('@id', 'varchar(100)') AS [LockID],
                [OwnerList].[Owner].value('@id', 'varchar(200)') AS [LockProcessId],
                REPLACE([MainLock].[Process].value('local-name(.)', 'varchar(100)'), 'lock', '') AS [LockEvent],
                [MainLock].[Process].value('@objectname', 'sysname') AS [ObjectName],
                [OwnerList].[Owner].value('@mode', 'varchar(10)') AS [LockMode],
                [MainLock].[Process].value('@dbid', 'INTEGER') AS [Database_id],
                [MainLock].[Process].value('@associatedObjectId', 'BIGINT') AS [AssociatedObjectId],
                [MainLock].[Process].value('@WaitType', 'varchar(100)') AS [WaitType],
                [WaiterList].[Owner].value('@id', 'varchar(200)') AS [WaitProcessId],
                [WaiterList].[Owner].value('@mode', 'varchar(10)') AS [WaitMode]
           FROM [cte_DeadLock]
                CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/resource-list') AS [Locks]([list]) 
				CROSS APPLY [Locks].[List].[nodes]('*') AS [MainLock]([Process]) 
				CROSS APPLY [MainLock].[Process].[nodes]('owner-list/owner') AS [OwnerList]([Owner]) 
				CROSS APPLY [MainLock].[Process].[nodes]('waiter-list/waiter') AS [WaiterList]([Owner])),
     Process
     AS (SELECT [cte_DeadLock].IdDeadLock,
                [Victim] = CONVERT( BIT,
                                    CASE
                                        WHEN [Deadlock].[Process].value('@id', 'varchar(50)') = ISNULL([Deadlock].[Process].value('../../@victim', 'varchar(50)'), [v].[ID])
                                        THEN 1
                                        ELSE 0
                                    END),
                [LockMode] = [Deadlock].[Process].value('@lockMode', 'varchar(10)'),
                [ProcessID] = [Process].[ID],
                [KPID] = [Deadlock].[Process].value('@kpid', 'int'),
                [SPID] = [Deadlock].[Process].value('@spid', 'int'),
                [SBID] = [Deadlock].[Process].value('@sbid', 'int'),
                [ECID] = [Deadlock].[Process].value('@ecid', 'int'),
                [IsolationLevel] = [Deadlock].[Process].value('@isolationlevel', 'varchar(200)'),
                [WaitResource] = [Deadlock].[Process].value('@waitresource', 'varchar(200)'),
                [LogUsed] = [Deadlock].[Process].value('@logused', 'int'),
                [ClientApp] = [Deadlock].[Process].value('@clientapp', 'varchar(100)'),
                [HostName] = [Deadlock].[Process].value('@hostname', 'varchar(20)'),
                [LoginName] = [Deadlock].[Process].value('@loginname', 'varchar(20)'),
                [TransactionTime] = [Deadlock].[Process].value('@lasttranstarted', 'datetime'),
                [BatchStarted] = [Deadlock].[Process].value('@lastbatchstarted', 'datetime'),
                [BatchCompleted] = [Deadlock].[Process].value('@lastbatchcompleted', 'datetime'),
                [InputBuffer] = [Input].[Buffer].[query]('.'),
                [cte_DeadLock].GraphDeadLock,
                [QueryStatement] = [Execution].[Frame].value('.', 'varchar(max)'),
                [TranCount] = [Deadlock].[Process].value('@trancount', 'int')
           FROM [cte_DeadLock]
                CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/process-list/process') AS [Deadlock]([Process]) 
				CROSS APPLY (SELECT [Deadlock].[Process].value('@id', 'varchar(50)')) AS [Process]([ID]) LEFT JOIN [Victims] AS [v] ON [Process].[ID] = [v].[ID]
                CROSS APPLY [Deadlock].[Process].[nodes]('inputbuf') AS [Input]([Buffer]) 
				CROSS APPLY [Deadlock].[Process].[nodes]('executionStack') AS [Execution]([Frame]))
     SELECT [p].IdDeadLock,
            [p].[Victim],
            [p].[LockMode],
            [LockedObject] = NULLIF([l].[ObjectName], ''),
            [l].[database_id],
            [l].[AssociatedObjectId],
            [LockProcess] = [p].[ProcessID],
            [p].[KPID],
            [p].[SPID],
            [p].[SBID],
            [p].[ECID],
            [p].[TranCount],
            [l].[LockEvent],
            [LockedMode] = [l].[LockMode],
            [l].[WaitProcessID],
            [l].[WaitMode],
            [p].[WaitResource],
            [l].[WaitType],
            [p].[IsolationLevel],
            [p].[LogUsed],
            [p].[ClientApp],
            [p].[HostName],
            [p].[LoginName],
            [p].[TransactionTime],
            [p].[BatchStarted],
            [p].[BatchCompleted],
            [p].[InputBuffer]
       FROM [Locks] AS [l]
            INNER JOIN [Process] AS [p] ON [p].[ProcessID] = [l].[LockProcessID]
      ORDER BY [p].[IdDeadLock] ASC,
               [p].[Victim] DESC,
               [p].[ProcessId];


