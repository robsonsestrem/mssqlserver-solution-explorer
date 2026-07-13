-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Linha de tend�ncia mostrar� aumento nos totais di�rios e semanal de DeadLock, indica e justifica baixa de performance.
-----------------------------------------------------------------------------------------------------------------------------------------------------------

/****************************************TOTALIZADO POR DIA*************************************************************************************************/
SELECT
count(d.IdDeadLock) as total         
,CONVERT(VARCHAR(10), d.DateDeadLock,103) as date
,d.DatabaseName
FROM YOUR_DATABASE.Management.HistoryDeadLock as d
WHERE d.DatabaseName is not null and d.DateDeadLock is not null
and d.DateDeadLock between '2017-03-28' and GETDATE()  -- a data setada � a primerira registrada na rotina de coleta
group by substring(CONVERT(VARCHAR(10), d.DateDeadLock, 103), 4, 2)
		,CONVERT(VARCHAR(10), d.DateDeadLock,103), d.DatabaseName


/****************************************TOTALIZADO POR SEMANA*************************************************************************************************/
declare  @decremento smallint
		,@limite smallint		
		,@dia datetime
IF(OBJECT_ID('tempdb.dbo.##semanas')IS NOT NULL) 
	BEGIN
		drop table ##semanas
	END
create table ##semanas
(
TotalDeaLock int,
DateDeadLock varchar(12),
DatabaseName varchar(50)
)

set @limite = (select DATEDIFF(WEEK, '2017-03-28', GETDATE()) * -1)  -- a data setada � a primerira registrada na rotina de coleta
set @decremento = 1

WHILE (@limite <= @decremento)
	BEGIN			
		set @dia = (select  cast(dateadd(WEEK,@decremento,	cast(floor(cast(getdate() as float)) as datetime)) as date))

		INSERT INTO ##semanas

		select sum(x.TotalBlock) as TotalDeadLock, max(x.DateDeadLock) as LastDayWeek, x.DatabaseName from(
		SELECT
			 count(h.IdDeadLock) as TotalBlock         
			,CONVERT(VARCHAR(12), h.DateDeadLock,103) as DateDeadLock
			,h.DatabaseName
		FROM YOUR_DATABASE.Management.HistoryDeadLock as h
		WHERE h.DatabaseName is not null and h.DateDeadLock is not null
		and cast(h.DateDeadLock as date) 
		between dateadd(WEEK,-1, cast(cast(floor(cast(@dia as float)) as datetime) as date)) 
		and cast(@dia as date)	
		
		group by substring(CONVERT(VARCHAR(12), h.DateDeadLock, 103), 4, 2)
				,CONVERT(VARCHAR(12), h.DateDeadLock,103)
				, h.DatabaseName	
		) as x
		group by x.DatabaseName	

		set @decremento = @decremento -1
	END

select 
	   s.TotalDeaLock
	 , s.DateDeadLock
	 , s.DatabaseName
from ##semanas as s

IF(OBJECT_ID('temdb.dbo.##semanas') IS NOT NULL)
	BEGIN
		drop table ##semanas
	END


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Nova vis�o para o PowerBI
-----------------------------------------------------------------------------------------------------------------------------------------------------------
select 
x.DateDeadLock as [Data de Refer�ncia]
,  Case When DatePart(WeekDay, x.DateDeadLock) = 1 Then 'Domingo' 
		When DatePart(WeekDay, x.DateDeadLock) = 2 Then 'Segunda'
		When DatePart(WeekDay, x.DateDeadLock) = 3 Then 'Ter�a'
		When DatePart(WeekDay, x.DateDeadLock) = 4 Then 'Quarta'
		When DatePart(WeekDay, x.DateDeadLock) = 5 Then 'Quinta'
		When DatePart(WeekDay, x.DateDeadLock) = 6 Then 'Sexta'
		When DatePart(WeekDay, x.DateDeadLock) = 7 Then 'S�bado'
	end as [Dia da Semana]
, x.DatabaseName as [Nome Database]
, count(x.IdDeadLock) as [Total DeadLock]
from
(
		SELECT
			 h.IdDeadLock	         
			, cast(h.DateDeadLock as date) as DateDeadLock
			, h.DatabaseName
		FROM YOUR_DATABASE.Management.HistoryDeadLock as h
		WHERE h.DatabaseName is not null and h.DateDeadLock is not null
) as x			
group by x.DateDeadLock, x.DatabaseName	
		

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Conta us�rios distintos por dia afetados por deadLock
-----------------------------------------------------------------------------------------------------------------------------------------------------------
use YOUR_DATABASE
go

;WITH cte_DeadLock
     AS (SELECT IdDeadLock,
                DateDeadLock,
				DatabaseName,
                GraphDeadLock
           FROM Management.HistoryDeadLock
		   where DateDeadLock >= '20181221'		  
		   ),
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
                --[MainLock].[Process].value('@dbid', 'INTEGER') AS [Database_id],
				[cte_DeadLock].DatabaseName AS DatabaseName,
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

	 select distinct
		count(y.TotalPorDia) over (partition by y.TransactionTime) as [Total Logins Distintos Envolvidos] 
		, y.TransactionTime, coalesce(y.DatabaseName, '') as DatabaseName
	 from
	 (
		 select
			ROW_NUMBER() over (order by x.[LoginName]) as TotalPorDia
			, x.LoginName, x.TransactionTime, x.DatabaseName
		 from
		 (
			 SELECT distinct  
					[l].DatabaseName,           
					ISNULL([p].[LoginName],'')			AS [LoginName],
					cast([p].[TransactionTime] as date)	AS [TransactionTime]                        
			 FROM [Locks] AS [l]
					INNER JOIN [Process] AS [p] ON [p].[ProcessID] = [l].[LockProcessID]		
		 ) as x

	 ) as y