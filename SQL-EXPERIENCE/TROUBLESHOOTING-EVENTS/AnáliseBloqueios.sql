USE Maintenance
GO
;WITH cte_BlockedProcess
     AS (SELECT IdBlock,
                DateBlock,
				DatabaseName,
                GraphBlock
           FROM Management.HistoryBlockedProcess
		   where DateBlock >= '2019-04-30 13:15:00.997' and DateBlock < '20190501'		  	   		   		   
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
		select (cast(xml.Segundos as decimal(18,2)) / 60) as Minutos, *
		from ExtraiXML as xml
		--where cast(xml.Segundos as decimal(18,2)) > 60.00

		order by 1 desc
						
		--SELECT COUNT(*), xml.LockMode FROM ExtraiXML as xml
		--where xml.Script_Blocking not like '%select%'
		--and xml.Script_Blocking not like '%update%'
		--and xml.Script_Blocking not like '%insert%'
		--and xml.Script_Blocking not like '%delete%'
		--and xml.Script_Blocking not like '%Database Id%'
	
		--group by xml.LockMode
		--order by 1 desc
	
	 
	   --No banco de dados SQL Server máximo por instâncias podem ser criados são 32.767 
	   --Este último número foi reservado pelo próprio Banco de Dados de Recursos.
	   --Ele é localizado em -> C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Binn
	   --Nome dele é mssqlsystemresource
	   --SELECT	SERVERPROPERTY('ResourceVersion') ResourceVersion,
				--SERVERPROPERTY('ResourceLastUpdateDateTime') ResourceLastUpdateDateTime
	   --GO


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Conta usários distintos por dia afetados por bloqueio
-----------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
;WITH cte_BlockedProcess
     AS (SELECT IdBlock,
                DateBlock,
				DatabaseName,
                GraphBlock
           FROM Management.HistoryBlockedProcess
		   where DateBlock >= '20180801'	   		  	   		   		   
		   )
, ExtraiXML AS(
			 SELECT 	
					[A].IdBlock,	
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
		select distinct count(y.TotalPorDia) over (partition by y.data) as [Total Logins Bloqueados Distintos]
		, y.data as [Data]
		from
		(
		select ROW_NUMBER() over (order by x.Login_Blocked) as TotalPorDia
		, x.Login_Blocked, x.data
		from 
		(
		select distinct xml.Login_Blocked, cast(xml.Data_Inicio as date) as [data]	
		from ExtraiXML as xml
		where xml.BD = 'gescooper90'
		) as x
		) as y


