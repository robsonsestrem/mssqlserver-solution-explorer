/*
    OBJETIVO: Analisar deadlocks registrados na tabela Management.HistoryDeadLock,
              extraindo informações detalhadas do XML de deadlock como processos
              envolvidos, vítima, locks, recursos e scripts, permitindo
              identificação da causa raiz dos deadlocks.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

;WITH cte_DeadLock
AS (
    SELECT
        IdDeadLock
      , DateDeadLock
      , DatabaseName
      , GraphDeadLock
    FROM
        Management.HistoryDeadLock
    WHERE
        DateDeadLock >= '20181221'
        AND DateDeadLock < '20181222'
)
, Victims
AS (
    SELECT
        [ID] = Victims.List.value('@id', 'VARCHAR(50)')
    FROM
        cte_DeadLock
        CROSS APPLY cte_DeadLock.GraphDeadLock.nodes('//deadlock/victim-list/victimProcess') AS Victims(List)
)
, Locks
AS (
    SELECT
        cte_DeadLock.IdDeadLock
      , MainLock.Process.value('@id', 'VARCHAR(100)')                AS LockID
      , OwnerList.Owner.value('@id', 'VARCHAR(200)')                 AS LockProcessID
      , REPLACE(MainLock.Process.value('local-name(.)', 'VARCHAR(100)'), 'lock', '') AS LockEvent
      , MainLock.Process.value('@objectname', 'SYSNAME')             AS ObjectName
      , OwnerList.Owner.value('@mode', 'VARCHAR(10)')                AS LockMode
      , cte_DeadLock.DatabaseName                                    AS DatabaseName
      , MainLock.Process.value('@associatedObjectId', 'BIGINT')      AS AssociatedObjectId
      , MainLock.Process.value('@WaitType', 'VARCHAR(100)')          AS WaitType
      , WaiterList.Owner.value('@id', 'VARCHAR(200)')                AS WaitProcessID
      , WaiterList.Owner.value('@mode', 'VARCHAR(10)')               AS WaitMode
    FROM
        cte_DeadLock
        CROSS APPLY cte_DeadLock.GraphDeadLock.nodes('//deadlock/resource-list') AS Locks(list)
        CROSS APPLY Locks.List.nodes('*') AS MainLock(Process)
        CROSS APPLY MainLock.Process.nodes('owner-list/owner') AS OwnerList(Owner)
        CROSS APPLY MainLock.Process.nodes('waiter-list/waiter') AS WaiterList(Owner)
)
, Process
AS (
    SELECT
        cte_DeadLock.IdDeadLock
      , Victim = CONVERT
        (
            BIT,
            CASE
                WHEN Deadlock.Process.value('@id', 'VARCHAR(50)') = ISNULL(Deadlock.Process.value('../../@victim', 'VARCHAR(50)'), v.ID)
                THEN 1
                ELSE 0
            END
        )
      , LockMode = Deadlock.Process.value('@lockMode', 'VARCHAR(10)')
      , ProcessID = Process.ID
      , KPID = Deadlock.Process.value('@kpid', 'INT')
      , SPID = Deadlock.Process.value('@spid', 'INT')
      , SBID = Deadlock.Process.value('@sbid', 'INT')
      , ECID = Deadlock.Process.value('@ecid', 'INT')
      , IsolationLevel = Deadlock.Process.value('@isolationlevel', 'VARCHAR(200)')
      , WaitResource = Deadlock.Process.value('@waitresource', 'VARCHAR(200)')
      , LogUsed = Deadlock.Process.value('@logused', 'INT')
      , ClientApp = Deadlock.Process.value('@clientapp', 'VARCHAR(100)')
      , HostName = Deadlock.Process.value('@hostname', 'VARCHAR(20)')
      , LoginName = Deadlock.Process.value('@loginname', 'VARCHAR(20)')
      , TransactionTime = Deadlock.Process.value('@lasttranstarted', 'DATETIME')
      , BatchStarted = Deadlock.Process.value('@lastbatchstarted', 'DATETIME')
      , BatchCompleted = Deadlock.Process.value('@lastbatchcompleted', 'DATETIME')
      , InputBuffer = Input.Buffer.query('.')
      , cte_DeadLock.GraphDeadLock
      , QueryStatement = Execution.Frame.value('.', 'VARCHAR(MAX)')
      , TranCount = Deadlock.Process.value('@trancount', 'INT')
    FROM
        cte_DeadLock
        CROSS APPLY cte_DeadLock.GraphDeadLock.nodes('//deadlock/process-list/process') AS Deadlock(Process)
        CROSS APPLY (SELECT Deadlock.Process.value('@id', 'VARCHAR(50)')) AS Process(ID)
        LEFT JOIN Victims AS v
            ON Process.ID = v.ID
        CROSS APPLY Deadlock.Process.nodes('inputbuf') AS Input(Buffer)
        CROSS APPLY Deadlock.Process.nodes('executionStack') AS Execution(Frame)
)

SELECT
    p.IdDeadLock
  , p.Victim
  , ISNULL(l.ObjectName, '')                                                 AS LockedObject
  , l.DatabaseName
  , ISNULL(l.AssociatedObjectId, '')                                         AS AssociatedObjectId
  , p.ProcessID                                                              AS LockProcess
  , p.KPID
  , p.SPID
  , p.SBID
  , p.ECID
  , p.TranCount
  , l.LockEvent
  , ISNULL(l.LockMode, '')                                                   AS LockedMode
  , l.WaitProcessID
  , ISNULL(l.WaitMode, '')                                                   AS WaitMode
  , ISNULL(p.WaitResource, '')                                               AS WaitResource
  , ISNULL(l.WaitType, '')                                                   AS WaitType
  , ISNULL(p.IsolationLevel, '')                                             AS IsolationLevel
  , ISNULL(p.LogUsed, '')                                                    AS LogUsed
  , ISNULL(p.ClientApp, '')                                                  AS ClientApp
  , ISNULL(p.HostName, '')                                                   AS HostName
  , ISNULL(p.LoginName, '')                                                  AS LoginName
  , ISNULL(p.TransactionTime, '')                                            AS TransactionTime
  , p.BatchStarted
  , p.BatchCompleted
  , p.InputBuffer
  -- REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST(p.InputBuffer AS VARCHAR(MAX)),'<inputbuf/>',''),'<inputbuf>',''),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS InputBuffer
FROM
    Locks AS l
    INNER JOIN Process AS p
        ON p.ProcessID = l.LockProcessID
-- WHERE l.DatabaseName IN ('YOUR_DATABASE', 'Edocs')
ORDER BY
    p.IdDeadLock ASC
  , p.Victim DESC
  , p.ProcessID;
