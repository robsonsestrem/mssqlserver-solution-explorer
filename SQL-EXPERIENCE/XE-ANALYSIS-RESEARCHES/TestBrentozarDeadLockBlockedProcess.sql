/*
Muitas pessoas querem que você pense que os Eventos Estendidos precisam ser complicados e envolver grandes quantidades de destruição de XML e jogar coisas pelo escritório. 
Estou aqui para lhe dizer que não precisa ser tão ruim.
*/
CREATE EVENT SESSION [blocked_process] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name)) ,
ADD EVENT sqlserver.xml_deadlock_report (
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'E:\DATABASES_SQL\TRACES\blocked_process',
    -- metadatafile = N'c:\temp\XEventSessions\blocked_process.xem',
     max_file_size=(10), -- 65536
     max_rollover_files=10)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO

/* Make sure this path exists before you start the trace! */

/**
Com isso, você criou uma sessão de Eventos Estendidos para capturar processos e impasses bloqueados. 
Por que ambos? O relatório de processo bloqueado faz uso do detector de deadlock. 
Como grandes quantidades de bloqueio são frequentemente sinônimo de impasse, faz sentido pegar os dois ao mesmo tempo. 
Há algumas outras coisas que precisaremos fazer para garantir que você possa coletar processos bloqueados:
**/

EXEC sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
/* Enabled the blocked process report */
EXEC sp_configure 'blocked process threshold', '5';
RECONFIGURE
GO
/* Start the Extended Events session */
ALTER EVENT SESSION [blocked_process] ON SERVER
STATE = START;


/**
 * Coletando os dados sem abrir o deadlock_graph
**/
;WITH events_cte AS (
  SELECT
    xevents.event_data, DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [event time] ,
    xevents.event_data.value('(event/action[@name=client_app_name]/value)[1]', 'nvarchar(128)') AS [client app name],
    xevents.event_data.value('(event/action[@name=client_hostname]/value)[1]', 'nvarchar(max)') AS [client host name],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=database_name]/value)[1]', 'nvarchar(max)') AS [database name],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=database_id]/value)[1]', 'int') AS [database_id],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=object_id]/value)[1]', 'int') AS [object_id],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=index_id]/value)[1]', 'int') AS [index_id],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=duration]/value)[1]', 'bigint') / 1000 AS [duration (ms)],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=lock_mode]/text)[1]', 'varchar') AS [lock_mode],
    xevents.event_data.value('(event[@name=blocked_process_report]/data[@name=login_sid]/value)[1]', 'int') AS [login_sid],
    xevents.event_data.query('(event[@name=blocked_process_report]/data[@name=blocked_process]/value/blocked-process-report)[1]') AS blocked_process_report,
    xevents.event_data.query('(event/data[@name=xml_report]/value/deadlock)[1]') AS deadlock_graph
  FROM    sys.fn_xe_file_target_read_file
    ('E:\DATABASES_SQL\TRACES\blocked_process*.xel', null, null, null)
    CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
SELECT
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN 'Deadlock'
       ELSE 'Blocked Process'
       END AS ReportType,
  [event time],
  CASE [client app name] WHEN '' THEN ' -- N/A -- '
                         ELSE [client app name]
                         END AS [client app _name],
  CASE [client host name] WHEN '' THEN ' -- N/A -- '
                          ELSE [client host name]
                          END AS [client host name],
  [database name],
  COALESCE(OBJECT_SCHEMA_NAME(object_id, database_id), ' -- N/A -- ') AS [schema],
  COALESCE(OBJECT_NAME(object_id, database_id), ' -- N/A -- ') AS [table],
  index_id,
  [duration (ms)],
  lock_mode,
  COALESCE(SUSER_NAME(login_sid), ' -- N/A -- ') AS username,
  CASE WHEN blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NULL
       THEN deadlock_graph
       ELSE blocked_process_report
       END AS Report
FROM events_cte
ORDER BY [event time] DESC;


/**
 * Criar tabela para histórico só do bloqueio com o XML
**/
CREATE TABLE bpr (
    EndTime DATETIME,
    TextData XML,
    EventClass INT DEFAULT(137)
);
GO

;WITH events_cte AS (
    SELECT
        DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [event_time] ,
        xevents.event_data.query('(event[@name=blocked_process_report]/data[@name=blocked_process]/value/blocked-process-report)[1]') AS blocked_process_report
    FROM    sys.fn_xe_file_target_read_file
        (N'E:\DATABASES_SQL\TRACES\blocked_process*.xel', null, null, null)
        CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
)
INSERT INTO bpr (EndTime, TextData)
SELECT
    [event_time],
    blocked_process_report
FROM events_cte
WHERE blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NOT NULL
ORDER BY [event_time] DESC ;

select * from bpr


/********* ALTERNATIVAS ************************************************************************************************************************************************************************/

CREATE EVENT SESSION [blocked_process_report] ON SERVER
ADD EVENT sqlserver.blocked_process_report(
    ACTION(sqlserver.client_app_name,
           sqlserver.client_hostname,
           sqlserver.database_name))
ADD TARGET package0.asynchronous_file_target
(SET filename = N'E:\DATABASES_SQL\TRACES\blocked_process_report',    
     max_file_size=(10), -- 65536
     max_rollover_files=10)
WITH (MAX_DISPATCH_LATENCY = 5SECONDS)
GO



DECLARE @Dt_Ultimo_Registro DATETIME = ISNULL((SELECT
              MAX(Dt_Evento)
            FROM dbo.Historico_Query_Lenta)
          , '1900-01-01')

DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
;with events_block as 
		(
		  SELECT
		     xevents.event_data,
			 DATEADD(HOUR, @TimeZone, xevents.event_data.value('(event/@timestamp)[1]', 'datetime') ) AS dt_evento,
			 xevents.event_data.query('(event[@name=blocked_process_report]/data[@name=blocked_process]/value/blocked-process-report)[1]') AS blocked_process_report
		  FROM sys.fn_xe_file_target_read_file
			('E:\DATABASES_SQL\TRACES\blocked_process_report*.xel', null, null, null)
			CROSS APPLY (SELECT CAST(event_data AS XML) AS event_data) as xevents
		)	 
			  SELECT 

			      [A].dt_evento,			      			    									  
				  CAST([A].event_data.value('(event[@name=blocked_process_report]/data[@name=duration]/value)[1]', 'bigint') / 1000000.0 AS NUMERIC(18, 2)) AS [duration],
				  [BlockedProcess].Process.value('@lastbatchcompleted', 'datetime')																AS lastbatchcompleted_blocked,
				  [BlockingProcess].Process.value('@lastbatchcompleted', 'datetime')															    AS lastbatchcompleted_blocking,


				  [A].event_data.value('(event[@name=blocked_process_report]/data[@name=database_id]/value)[1]', 'int') AS [db_id],
				  [A].event_data.value('(event[@name=blocked_process_report]/data[@name=database_name]/value)[1]', 'nvarchar(max)') AS [db_name],				  
				  [A].event_data.value('(event[@name=blocked_process_report]/data[@name=lock_mode]/value)[1]', 'varchar') AS nr_mode,
				  [A].event_data.value('(event[@name=blocked_process_report]/data[@name=lock_mode]/text)[1]', 'varchar') AS lock_mode,				  				  
				  [A].event_data.value('(event[@name=blocked_process_report]/data[@name=object_id]/value)[1]', 'int') AS object_id,
				  [A].event_data.value('(event[@name=blocked_process_report]/data[@name=index_id]/value)[1]', 'int') AS index_id,
				  
				  [BlockedProcess].Process.value('@waitresource', 'varchar(max)')																AS Waitresource,				  
				  [BlockedProcess].Process.value('@spid', 'varchar(max)')																		AS spid_blocked,
				  [BlockedProcess].Process.value('@status', 'varchar(max)')																		AS status_blocked,
				  [BlockedProcess].Process.value('@clientapp', 'varchar(max)')																	AS program_blocked,				  
				  [BlockedProcess].Process.value('@hostname', 'varchar(max)')																	AS host_blocked,
				  [BlockedProcess].Process.value('@loginname', 'varchar(max)')																	AS login_blocked,
				  [BlockedProcess].Process.value('@isolationlevel', 'varchar(max)')																AS isolationlevel_blocked,
				  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockedProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
				  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS script_blocked,
				  --
				  [BlockingProcess].Process.value('@spid', 'varchar(max)')																		AS spid_blocking,
				  [BlockingProcess].Process.value('@status', 'varchar(max)')																	AS status_blocked,
				  [BlockingProcess].Process.value('@clientapp', 'varchar(max)')																	AS program_blocking,				  
				  [BlockingProcess].Process.value('@hostname', 'varchar(max)')																	AS host_blocking,
				  [BlockingProcess].Process.value('@loginname', 'varchar(max)')																	AS login_blocking,
				  [BlockingProcess].Process.value('@isolationlevel', 'varchar(max)')															AS isolationLevel_blocking,
				  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockingProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
			      ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS script_blocking
			   FROM events_block AS [A]			        
					CROSS APPLY [A].blocked_process_report.[nodes]('//blocked-process-report/blocking-process/process') AS [BlockingProcess]([Process])
					CROSS APPLY [A].blocked_process_report.[nodes]('//blocked-process-report/blocked-process/process') AS [BlockedProcess]([Process])
		       where [A].blocked_process_report.value('(blocked-process-report[@monitorLoop])[1]', 'nvarchar(max)') IS NOT NULL
			   AND [A].dt_evento >= '2022-03-21 19:24:00'
			   


--USE Maintenance
--GO
--;WITH cte_BlockedProcess
--     AS (SELECT top 10 IdBlock,
--                DateBlock,
--				DatabaseName,
--                GraphBlock
--           FROM Management.HistoryBlockedProcess
--		   where DateBlock >= '20180626'		   		  	   		   		   
--		   )
--, ExtraiXML AS(
--			 SELECT --CONVERT( VARCHAR(50), [A].GraphBlock.[query]('data(/EVENT_INSTANCE/Duration)')) as Duracao_ms,		
--					REPLACE((CAST(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Duration)')  AS VARCHAR(60)) AS MONEY)/1000/1000),',','.')  AS Segundos,
--					CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EventType)')		AS VARCHAR(50))											AS Evento,
--					REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)),'T',' ')								AS Data_Inicio,
--					REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EndTime)')	AS VARCHAR(23)),'T',' ')							AS Data_Fim,			
--					[A].DatabaseName																											AS BD,

--					CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Mode)')	AS VARCHAR(10))													AS Mode,				  
--				  [BlockedProcess].Process.value('@lockMode', 'varchar(max)')																	AS LockMode,
--				  [BlockedProcess].Process.value('@waitresource', 'varchar(max)')																AS Waitresource,

--					--CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/DatabaseID)')AS VARCHAR(10)) as id_banco,
--				  [BlockedProcess].Process.value('@clientapp', 'varchar(max)')																	AS Program_Blocked,
--				  [BlockedProcess].Process.value('@spid', 'varchar(max)')																		AS SPID_Blocked,
--				  [BlockedProcess].Process.value('@hostname', 'varchar(max)')																	AS Host_Blocked,
--				  [BlockedProcess].Process.value('@loginname', 'varchar(max)')																	AS Login_Blocked,
--				  [BlockedProcess].Process.value('@isolationlevel', 'varchar(max)')																AS IsolationLevel_Blocked,
--				  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockedProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
--				  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS Script_Blocked,

--				  [BlockingProcess].Process.value('@clientapp', 'varchar(max)')																	AS Program_Blocking,
--				  [BlockingProcess].Process.value('@spid', 'varchar(max)')																		AS SPID_Blocking,
--				  [BlockingProcess].Process.value('@hostname', 'varchar(max)')																	AS Host_Blocking,
--				  [BlockingProcess].Process.value('@loginname', 'varchar(max)')																	AS Login_Blocking,
--				  [BlockingProcess].Process.value('@isolationlevel', 'varchar(max)')															AS IsolationLevel_Blocking,
--				  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockingProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
--				  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS Script_Blocking
--			   FROM [cte_BlockedProcess] AS [A]
--					CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocked-process/process')  AS [BlockedProcess]([Process]) 
--					CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocking-process/process') AS [BlockingProcess]([Process])
		
--		)
--		select * from ExtraiXML as xml
--		ORDER BY xml.Data_Inicio DESC	

