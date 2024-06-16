-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Linha de tendência mostrará aumento nos totais diários e semanal de processos bloqueados, indica e justifica baixa de performance.
-----------------------------------------------------------------------------------------------------------------------------------------------------------
--SELECT
--count(IdBlock) as total         
--, DatabaseName
--FROM Management.HistoryBlockedProcess
--where DateBlock >= '2017-03-30 00:00:00.000'   and DateBlock <= '2017-03-30 23:59:59:997'
--group by DatabaseName
--
--select substring(convert(varchar(10),getdate(),103),1,2), convert(varchar(10),getdate(),103)
--
/****************************************TOTALIZADO POR DIA*************************************************************************************************/
SELECT
count(h.IdBlock) as TotalBlock         
,CONVERT(VARCHAR(10), h.DateBlock,103) as Date
,h.DatabaseName
FROM Maintenance.Management.HistoryBlockedProcess as h
WHERE h.DatabaseName is not null and h.DateBlock is not null
and h.DateBlock between '2017-03-24' and GETDATE()  -- a data setada é a primerira registrada na rotina de coleta
group by substring(CONVERT(VARCHAR(10), h.DateBlock, 103), 4, 2)
		,CONVERT(VARCHAR(10), h.DateBlock,103), h.DatabaseName



/****************************************TOTALIZADO POR SEMANA*************************************************************************************************/
	    --SELECT sum(x.TotalBlock) as total,max(x.DateBlock) , x.DatabaseName from(
		--SELECT
		--	count(h.IdBlock) as TotalBlock         
		--	,CONVERT(VARCHAR(12), h.DateBlock,103) as DateBlock
		--	,h.DatabaseName
		--FROM IntegraTICravil.Management.HistoryBlockedProcess as h
		--WHERE h.DatabaseName is not null and h.DateBlock is not null
		--and cast(h.DateBlock as date) 
		--between dateadd(WEEK,-1, cast(cast(floor(cast(GETDATE() as float)) as datetime) as date)) 
		--and cast(getdate() as date)	
		
		--group by substring(CONVERT(VARCHAR(12), h.DateBlock, 103), 4, 2)
		--		,CONVERT(VARCHAR(12), h.DateBlock,103)
		--		, h.DatabaseName	
		--) as x
		--group by x.DatabaseName
-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- No script abaixo foi calculado para trazer a data, porém é escolhido a última data do agrupamento de count por base de dados,
-- ou seja, tenho bloqueios numa base no dia 10 e no dia 11 ele me traz a data do dia 11 e o total desses bloqueios.
-- Obs.: na última semana talvez pode duplicar a data pois ele calcula a data máxima de uma semana pra frente 
-- e depois as anteriores na variável @decremento.
-----------------------------------------------------------------------------------------------------------------------------------------------------------
declare  @decremento smallint
		,@limite smallint		
		,@dia datetime
IF(OBJECT_ID('tempdb.dbo.##semanas')IS NOT NULL) 
	BEGIN
		drop table ##semanas
	END
create table ##semanas
(
TotalBlock int,
DateBlock varchar(12),
DatabaseName varchar(50)
)

set @limite = (select DATEDIFF(WEEK, '2017-03-24', GETDATE()) * -1)  -- a data setada é a primerira registrada na rotina de coleta
set @decremento = 1

WHILE (@limite <= @decremento)
	BEGIN			
		set @dia = (select  cast(dateadd(WEEK,@decremento,	cast(floor(cast(getdate() as float)) as datetime)) as date))

		INSERT INTO ##semanas

		select sum(x.TotalBlock) as TotalBlock, max(x.DateBlock) as LastDayWeek, x.DatabaseName from(
		SELECT
			 count(h.IdBlock) as TotalBlock         
			,CONVERT(VARCHAR(12), h.DateBlock,103) as DateBlock
			,h.DatabaseName
		FROM Maintenance.Management.HistoryBlockedProcess as h
		WHERE h.DatabaseName is not null and h.DateBlock is not null
		and cast(h.DateBlock as date) 
		between dateadd(WEEK,-1, cast(cast(floor(cast(@dia as float)) as datetime) as date)) 
		and cast(@dia as date)	
		
		group by substring(CONVERT(VARCHAR(12), h.DateBlock, 103), 4, 2)
				,CONVERT(VARCHAR(12), h.DateBlock,103)
				, h.DatabaseName	
		) as x
		group by x.DatabaseName	

		set @decremento = @decremento -1
	END

select s.TotalBlock
	 , s.DateBlock
	 , s.DatabaseName
from ##semanas as s

IF(OBJECT_ID('temdb.dbo.##semanas') IS NOT NULL)
	BEGIN
		drop table ##semanas
	END



-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Nova visão para o PowerBI
-----------------------------------------------------------------------------------------------------------------------------------------------------------
select 
x.DateBlock as [Data de Referência]
, x.DatabaseName as [Nome Database]
, count(x.IdBlock) as [Total Block]
from
(
		SELECT
			 h.IdBlock	         
			, cast(h.DateBlock as date) as DateBlock
			, h.DatabaseName
		FROM Maintenance.Management.HistoryBlockedProcess as h
		WHERE h.DatabaseName is not null and h.DateBlock is not null
) as x			
group by x.DateBlock, x.DatabaseName	



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
		, y.data as [Data], coalesce(y.BD, '') as [Database]
		from
		(
			select ROW_NUMBER() over (order by x.Login_Blocked) as TotalPorDia
			, x.Login_Blocked, x.data, x.BD
			from 
			(
				select distinct xml.Login_Blocked, cast(xml.Data_Inicio as date) as [data], xml.BD	
				from ExtraiXML as xml
				--where xml.BD = 'gescooper90'
			) as x
		) as y