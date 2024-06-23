use Maintenance
go
;WITH cte_DeadLock
     AS (SELECT IdDeadLock,
                DateDeadLock,
				DatabaseName,
                GraphDeadLock
           FROM Management.HistoryDeadLock
		   where DateDeadLock >= '20181221' and DateDeadLock < '20181222'
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
     SELECT [p].IdDeadLock,
            [p].[Victim],       
            ISNULL([l].[ObjectName], '')		AS [LockedObject],          
			[l].DatabaseName,
            ISNULL([l].[AssociatedObjectId],'') AS [AssociatedObjectId],
            [p].[ProcessID]						AS [LockProcess],
            [p].[KPID],
            [p].[SPID],
            [p].[SBID],
            [p].[ECID],
            [p].[TranCount],
            [l].[LockEvent],
            ISNULL([l].[LockMode],'')			AS [LockedMode],
            [l].[WaitProcessID],
            ISNULL([l].[WaitMode],'')			AS [WaitMode],
            ISNULL([p].[WaitResource],'')		AS [WaitResource],
            ISNULL([l].[WaitType],'')			AS [WaitType],
            ISNULL([p].[IsolationLevel],'')		AS [IsolationLevel],
            ISNULL([p].[LogUsed],'')			AS [LogUsed],
            ISNULL([p].[ClientApp],'')			AS [ClientApp],
            ISNULL([p].[HostName],'')			AS [HostName],
            ISNULL([p].[LoginName],'')			AS [LoginName],
            ISNULL([p].[TransactionTime],'')	AS [TransactionTime],
            [p].[BatchStarted],
            [p].[BatchCompleted],
			[p].[InputBuffer]
            --REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST([p].[InputBuffer] AS VARCHAR(MAX)),'<inputbuf/>',''),'<inputbuf>',''),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [InputBuffer]
       FROM [Locks] AS [l]
            INNER JOIN [Process] AS [p] ON [p].[ProcessID] = [l].[LockProcessID]
			--where l.DatabaseName in ('rhcravil', 'Edocs')

      ORDER BY [p].[IdDeadLock] ASC,
               [p].[Victim] DESC,
               [p].[ProcessId];



			   
			