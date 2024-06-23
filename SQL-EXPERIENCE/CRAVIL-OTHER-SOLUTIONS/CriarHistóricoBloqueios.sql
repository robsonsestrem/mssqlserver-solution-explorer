---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Já de início, é necessário alterar a configuração habilitando o Broker e o Trustworthy:
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance;
GO

Alter Database Maintenance
Set Single_User With Rollback Immediate
go

ALTER DATABASE Maintenance SET ENABLE_BROKER ;
GO

-------------------------------------------------------
-- caso de problema de mesmo ID do Service Broker
--ALTER DATABASE guru6 SET NEW_BROKER;
-------------------------------------------------------
ALTER DATABASE Maintenance SET TRUSTWORTHY ON;
GO

Alter Database Maintenance
Set Multi_User With Rollback Immediate
go
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


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Primeiro crio a tabela que irá receber todas os eventos de locks dos bancos de dados.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Gescooper90.[dbo].[HistoryBlockedProcess]
(
 IdBlock INT IDENTITY(1, 1) NOT NULL,
 DateBlock DATETIME NULL,
 DatabaseName  VARCHAR(255),
 GraphBlock XML
 CONSTRAINT [PK_BlockedProcess] PRIMARY KEY(IdBlock)
); 


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Em seguida crio a QUEUE, o Service e o Event Notification para esta coleta, note que na criação do Event Notification.
-- Veja na criação dos Event a ação que é monitorada é a BLOCKED_PROCESS_REPORT.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
CREATE QUEUE [Audit_Blocked_Process_Queue];
GO

CREATE SERVICE Audit_Blocked_Process_Service 
ON QUEUE [Audit_Blocked_Process_Queue]([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]); -- endereço indicado nos contratos


USE Maintenance
GO
CREATE EVENT NOTIFICATION [Audit_Blocked_Process_Event] 
ON SERVER 
with fan_in
FOR BLOCKED_PROCESS_REPORT 
TO SERVICE N'Audit_Blocked_Process_Service', N'current database';
GO

DROP EVENT NOTIFICATION [Audit_Blocked_Process_Event]  
ON SERVER; 
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Os eventos vem como XML (EVENT_INSTANCE) a partir de um “select” na QUEUE Audit_Blocked_Process_Queue. Como a stored procedure é acionada a cada evento, 
-- ela capta da Audit_Blocked_Process_Queueo XML, desserializa e grava cada campo na tabela tb_BlockedProcess.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
CREATE PROCEDURE Management.sp_BlockedProcess
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
                     INSERT INTO Maintenance.Management.HistoryBlockedProcess
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


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Em seguida vou configurar a QUEUE Audit_Blocked_Process_Queue para acionar a stored procedure tb_BlockedProcess houver um evento e já ativar a QUEUE.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
Alter Queue [Audit_Blocked_Process_Queue]
With Activation 
(
   Status = ON,   
   Procedure_Name = Management.sp_BlockedProcess,
   Max_Queue_Readers = 1,	-- número máximo de instâncias de procedimento armazenado que o Service Broker inicia para essa fila.
   Execute as Owner   
);
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Consulta para análise dos dados coletados
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
;WITH cte_BlockedProcess
     AS (SELECT IdBlock,
                DateBlock,
				DatabaseName,
                GraphBlock
           FROM Management.HistoryBlockedProcess
		   where DateBlock >= '20180626'		   		  	   		   		   
		   )
, ExtraiXML AS(
			 SELECT --CONVERT( VARCHAR(50), [A].GraphBlock.[query]('data(/EVENT_INSTANCE/Duration)')) as Duracao_ms,		
					REPLACE((CAST(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Duration)')  AS VARCHAR(60)) AS MONEY)/1000/1000),',','.')  AS Segundos,
					CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EventType)')		AS VARCHAR(50))											AS Evento,
					REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)),'T',' ')								AS Data_Inicio,
					REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EndTime)')	AS VARCHAR(23)),'T',' ')							AS Data_Fim,			
					[A].DatabaseName																											AS BD,

					CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Mode)')	AS VARCHAR(10))													AS Mode,				  
				  [BlockedProcess].Process.value('@lockMode', 'varchar(max)')																	AS LockMode,
				  [BlockedProcess].Process.value('@waitresource', 'varchar(max)')																AS Waitresource,

					--CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/DatabaseID)')AS VARCHAR(10)) as id_banco,
				  [BlockedProcess].Process.value('@clientapp', 'varchar(max)')																	AS Program_Blocked,
				  [BlockedProcess].Process.value('@spid', 'varchar(max)')																		AS SPID_Blocked,
				  [BlockedProcess].Process.value('@hostname', 'varchar(max)')																	AS Host_Blocked,
				  [BlockedProcess].Process.value('@loginname', 'varchar(max)')																	AS Login_Blocked,
				  [BlockedProcess].Process.value('@isolationlevel', 'varchar(max)')																AS IsolationLevel_Blocked,
				  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockedProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
				  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS Script_Blocked,

				  [BlockingProcess].Process.value('@clientapp', 'varchar(max)')																	AS Program_Blocking,
				  [BlockingProcess].Process.value('@spid', 'varchar(max)')																		AS SPID_Blocking,
				  [BlockingProcess].Process.value('@hostname', 'varchar(max)')																	AS Host_Blocking,
				  [BlockingProcess].Process.value('@loginname', 'varchar(max)')																	AS Login_Blocking,
				  [BlockingProcess].Process.value('@isolationlevel', 'varchar(max)')															AS IsolationLevel_Blocking,
				  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockingProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
				  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS Script_Blocking
			   FROM [cte_BlockedProcess] AS [A]
					CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocked-process/process')  AS [BlockedProcess]([Process]) 
					CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocking-process/process') AS [BlockingProcess]([Process])
		
		)
		select * from ExtraiXML as xml
		ORDER BY xml.Data_Inicio DESC	
						
		--SELECT COUNT(*), xml.LockMode FROM ExtraiXML as xml
		--where xml.Script_Blocking not like '%select%'
		--and xml.Script_Blocking not like '%update%'
		--and xml.Script_Blocking not like '%insert%'
		--and xml.Script_Blocking not like '%delete%'
		--and xml.Script_Blocking not like '%Database Id%'
	
		--group by xml.LockMode
		--order by 1 desc
	
	 
	   --No banco de dados SQL Server máximo por instâncias podem ser criados são 32.767. 
	   --Este último número foi reservado pelo próprio Banco de Dados de Recursos.
	   --Ele é localizado em -> C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Binn
	   --Nome dele é mssqlsystemresource
	   --SELECT	SERVERPROPERTY('ResourceVersion') ResourceVersion,
				--SERVERPROPERTY('ResourceLastUpdateDateTime') ResourceLastUpdateDateTime
	   --GO






