--------------------------------------------------------------------------------------------------------------
-- Contruindo uma visão
-- SELECT * FROM History_Deadlocks hd
--------------------------------------------------------------------------------------------------------------
-- forma simples
SELECT * FROM History_Deadlocks hd
ORDER BY hd.dt_event ASC        
        ,hd.processId ASC
        ,hd.isVictim DESC

--------------------------------------------------------------------------------------------------------------
-- sobre o @waitresource
-- https://littlekendra.com/2016/10/17/decoding-key-and-page-waitresource-for-deadlocks-and-blocking/
--------------------------------------------------------------------------------------------------------------
-- KEY: 5:72057594180665344 (46eb0d431bbf) => dbo.PSSOA.PK_PSSOA
-- OBJECT: 5:850102069:0 => 5 é o id da base de dados :: PSSOA
-- OBJECT: 5:549629051:0 => TR_U_PSSOA_SENHA
SELECT OBJECT_NAME('850102069')
SELECT OBJECT_NAME('549629051')

SELECT 
    sc.name as schema_name, 
    so.name as object_name, 
    si.name as index_name
FROM sys.partitions AS p
JOIN sys.objects as so on 
    p.object_id=so.object_id
JOIN sys.indexes as si on 
    p.index_id=si.index_id and 
    p.object_id=si.object_id
JOIN sys.schemas AS sc on 
    so.schema_id=sc.schema_id
WHERE hobt_id = 72057594180665344;
GO

-- Se eu realmente quiser saber exatamente qual linha o bloqueio precisava, posso decodificá-la consultando a própria tabela. 
-- Podemos usar a função não documentada %%lockres%% para encontrar a linha igual a esse valor de hash mágico.
SELECT * FROM PSSOA WITH (NOLOCK) WHERE %%lockres%% = '(46eb0d431bbf)'


--------------------------------------------------------------------------------------------------------------
SELECT * FROM History_Deadlock_Xml_Events xml_xe
WHERE xml_xe.xeTimeStamp BETWEEN '2023-05-12 00:00:00'  AND '2023-05-12 05:00:00'
--------------------------------------------------------------------------------------------------------------
DECLARE @StartTime datetimeoffset;
DECLARE @EndTime datetimeoffset;
DECLARE @Offset int;
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE());
SET @StartTime = DATEADD(HOUR, -20, GETDATE()); -- logs de quantas horas atrás
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

--SELECT StartTime = CONVERT(varchar(30), @StartTime, 127), EndTime = CONVERT(varchar(30), @EndTime, 127)

;WITH src AS
(
SELECT 
      [xeTimeStamp] = DATEADD(HOUR, @TimeZone, x.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)'))  
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [3] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[3]', 'nvarchar(128)')
    , [4] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[4]', 'nvarchar(128)')
    , [5] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[5]', 'nvarchar(128)')
    , [6] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[6]', 'nvarchar(128)')
    , [7] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[7]', 'nvarchar(128)')
    , [8] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[8]', 'nvarchar(128)')
    , [9] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[9]', 'nvarchar(128)')
    , [10] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[10]', 'nvarchar(128)')
    , [11] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[11]', 'nvarchar(128)')
    , [12] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[12]', 'nvarchar(128)')
    , [13] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[13]', 'nvarchar(128)')
    , [14] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[14]', 'nvarchar(128)')
    , [15] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[15]', 'nvarchar(128)')
    , [16] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[16]', 'nvarchar(128)')
    , [17] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[17]', 'nvarchar(128)')
    , [18] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[18]', 'nvarchar(128)')
    , [19] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[19]', 'nvarchar(128)')
    , [20] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[20]', 'nvarchar(128)')
FROM dbo.History_Deadlock_Xml_Events x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT ProcName = t.x
    , [Count] = COUNT(1)
FROM (
SELECT *
FROM src
UNPIVOT
([x] FOR [ProcName] IN (
      [1] 
    , [2] 
    , [3] 
    , [4] 
    , [5] 
    , [6] 
    , [7] 
    , [8] 
    , [9] 
    , [10]
    , [11]
    , [12]
    , [13]
    , [14]
    , [15]
    , [16]
    , [17]
    , [18]
    , [19]
    , [20]
    )) upvt
) t
GROUP BY t.x


--------------------------------------------------------------------------------------------------------------
-- ranking process
SELECT * FROM History_Deadlock_Xml_Events
--------------------------------------------------------------------------------------------------------------
DECLARE @StartTime DATETIMEOFFSET;
DECLARE @EndTime DATETIMEOFFSET;
DECLARE @Offset INT;
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE());
SET @StartTime = DATEADD(HOUR, -20, GETDATE()); -- logs de quantas horas atrás
SET @EndTime = GETDATE();
SET @Offset = DATEDIFF(MINUTE, GETDATE(), GETUTCDATE());
SET @StartTime = DATEADD(MINUTE, @Offset, @StartTime);
SET @EndTime = DATEADD(MINUTE, @Offset, @EndTime);

--SELECT StartTime = CONVERT(varchar(30), @StartTime, 127), EndTime = CONVERT(varchar(30), @EndTime, 127)

;WITH src AS
(
SELECT 
      [xeTimeStamp] = DATEADD(HOUR, @TimeZone, x.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)'))     
    , [1] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[1]', 'nvarchar(128)')
    , [2] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[2]', 'nvarchar(128)')
    , [3] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[3]', 'nvarchar(128)')
    , [4] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[4]', 'nvarchar(128)')
    , [5] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[5]', 'nvarchar(128)')
    , [6] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[6]', 'nvarchar(128)')
    , [7] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[7]', 'nvarchar(128)')
    , [8] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[8]', 'nvarchar(128)')
    , [9] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[9]', 'nvarchar(128)')
    , [10] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[10]', 'nvarchar(128)')
    , [11] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[11]', 'nvarchar(128)')
    , [12] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[12]', 'nvarchar(128)')
    , [13] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[13]', 'nvarchar(128)')
    , [14] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[14]', 'nvarchar(128)')
    , [15] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[15]', 'nvarchar(128)')
    , [16] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[16]', 'nvarchar(128)')
    , [17] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[17]', 'nvarchar(128)')
    , [18] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[18]', 'nvarchar(128)')
    , [19] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[19]', 'nvarchar(128)')
    , [20] = x.xeXML.value('(/event/data/value/deadlock/process-list/process/executionStack/frame/@procname)[20]', 'nvarchar(128)')
FROM dbo.History_Deadlock_Xml_Events x
WHERE x.xeXML.exist('/event[@name=xml_deadlock_report]') = 1
    AND x.xeXML.exist('/event[@timestamp>=sql:variable(@StartTime)]') = 1
    AND x.xeXML.exist('/event[@timestamp<=sql:variable(@EndTime)]') = 1
)
SELECT *
FROM src
UNPIVOT
([x] FOR [ProcName] IN (
      [1] 
    , [2] 
    , [3] 
    , [4] 
    , [5] 
    , [6] 
    , [7] 
    , [8] 
    , [9] 
    , [10]
    , [11]
    , [12]
    , [13]
    , [14]
    , [15]
    , [16]
    , [17]
    , [18]
    , [19]
    , [20]
    )) upvt



-----------------------------------------------------------------------------------------------------------------------
-- desenvolvendo...
-----------------------------------------------------------------------------------------------------------------------
DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())

;WITH cte_details AS 
 (
    SELECT
        --DATEADD(HOUR, @TimeZone, dados.event_data.value('@timestamp', 'datetimeoffset(7)')) AS [timestamp],  
        CAST(SWITCHOFFSET(DATEADD(HOUR, @TimeZone, dados.event_data.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')), DATEPART(TZOFFSET, dados.event_data.value('(/event/@timestamp)[1]', 'datetimeoffset(7)'))) AS DATETIME2) AS [timestamp],      
        processo.dados.value('@id', 'varchar(100)') AS [processId],
    	(CASE WHEN vitima.dados.value('@id', 'varchar(100)') = processo.dados.value('@id', 'varchar(100)') THEN 1 ELSE 0 END) AS isVictim,
        -- processo.dados.query('(inputbuf/text())') AS [processSqlCommand],        
        CAST(processo.dados.query('(inputbuf/text())') AS NVARCHAR(MAX)) AS [processSqlCommand],   
        recurso.resourceDBId,
        DB_NAME(recurso.resourceDBId) AS resourceDBName,
        recurso.resourceObjectName,
        processo.dados.value('@waitresource', 'varchar(100)') AS [processWaitResource],
        processo.dados.value('@waittime', 'int') AS [processWaitTime],
        processo.dados.value('@transactionname', 'varchar(60)') AS [processTransactionName],
        processo.dados.value('@status', 'varchar(60)') AS [processStatus],
        processo.dados.value('@spid', 'int') AS [processSPID],
        processo.dados.value('@clientapp', 'varchar(256)') AS [processClientApp],
        processo.dados.value('@hostname', 'varchar(256)') AS [processHostname],
        processo.dados.value('@loginname', 'varchar(256)') AS [processLoginName],
        processo.dados.value('@isolationlevel', 'varchar(256)') AS [processIsolationLevel],
        processo.dados.value('@currentdb', 'varchar(256)') AS [processCurrentDb],
        DB_NAME(processo.dados.value('@currentdb', 'varchar(256)')) AS [processCurrentDbName],
        processo.dados.value('@trancount', 'int') AS [processTranCount],
        processo.dados.value('@lockMode', 'varchar(10)') AS [processLockMode],
    	processo.dados.value('@lasttranstarted', 'datetime') AS [TransactionTime],
    	processo.dados.value('@lastbatchstarted', 'datetime') AS [BatchStarted],
    	processo.dados.value('@lastbatchcompleted', 'datetime') AS [BatchCompleted],
        recurso.resourceFileId,
        recurso.resourcePageId,
        recurso.resourceLockMode,
        recurso.resourceProcessOwner,
        recurso.resourceProcessOwnerMode
    FROM
        History_Deadlock_Xml_Events A
        CROSS APPLY A.xeXML.nodes('//event') AS dados(event_data)
        CROSS APPLY dados.event_data.nodes('data/value/deadlock/victim-list/victimProcess') AS vitima(dados)
        OUTER APPLY dados.event_data.nodes('data/value/deadlock/process-list/process') AS processo(dados)
        LEFT JOIN (
            SELECT
                A.xeTimeStamp,
                recurso.dados.value('@fileid', 'int') AS [resourceFileId],
                recurso.dados.value('@pageid', 'int') AS [resourcePageId],
                recurso.dados.value('@dbid', 'int') AS [resourceDBId],
                recurso.dados.value('@objectname', 'varchar(128)') AS [resourceObjectName],
                recurso.dados.value('@mode', 'varchar(2)') AS [resourceLockMode],
                [owner].dados.value('@id', 'varchar(128)') AS [resourceProcessOwner],
                [owner].dados.value('@mode', 'varchar(2)') AS [resourceProcessOwnerMode]
            FROM 
                History_Deadlock_Xml_Events A
                CROSS APPLY A.xeXML.nodes('//ridlock') AS recurso(dados)
                OUTER APPLY recurso.dados.nodes('owner-list/owner') AS owner(dados)
        ) AS recurso ON recurso.resourceProcessOwner = processo.dados.value('@id', 'varchar(100)') AND recurso.xeTimeStamp = A.xeTimeStamp
 )

SELECT * FROM cte_details AS dataset
WHERE dataset.timestamp BETWEEN '2023-05-17 00:00:00' AND '2023-05-17 05:00:00' -- '2023-05-12 00:00:00' AND '2023-05-12 07:00:00' | '2023-05-16 13:00:00' AND '2023-05-17 00:00:00'
--AND dataset.processSqlCommand LIKE '%UPD_INS_PESSOA%'
--AND dataset.isVictim = '1'
ORDER BY dataset.timestamp ASC, dataset.processId ASC





