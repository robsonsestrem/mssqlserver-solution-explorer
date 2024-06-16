-----------------------------------------------------------------------------------------------------------------------------------
-- AJUSTADO PERSISTÊNCIA DOS DADOS 
-----------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE dbo.sp_Gather_Deadlock_Events
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON;
    IF OBJECT_ID('tempdb..#xmlResults') IS NOT NULL DROP TABLE #xmlResults

    CREATE TABLE #xmlResults
    (
          xeTimeStamp datetimeoffset NOT NULL
        , xeProcessID varchar(100) NOT NULL
        , uuid UNIQUEIDENTIFIER NOT NULL
        , xeXML XML NOT NULL
        , PRIMARY KEY CLUSTERED (uuid)
    )    

    DECLARE @TimeZone INT = DATEDIFF(HOUR, GETUTCDATE(), GETDATE())
    DECLARE @Ultimo_Log DATETIME2 = ISNULL((SELECT MAX(xeTimeStamp) FROM dbo.History_Deadlock_Xml_Events WITH(NOLOCK)), '1900-01-01')
    ;WITH src AS 
    (
            SELECT            
            CAST(event_data AS XML) AS xeXML
            FROM 
            sys.fn_xe_file_target_read_file(N'/var/opt/mssql/log_jobs/xe/deadlocks_report*.xel', NULL, NULL, NULL)
    )
    INSERT INTO #xmlResults (xeXML, xeTimeStamp, uuid, xeProcessID)
    SELECT src.xeXML        
        , [xeTimeStamp] = SWITCHOFFSET(DATEADD(HOUR, @TimeZone, src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')), DATEPART(TZOFFSET, src.xeXML.value('(/event/@timestamp)[1]', 'datetimeoffset(7)')))
        , NEWID()
        , xeProcessID = src.xeXML.value('(/event/data/value/deadlock/victim-list/victimProcess/@id)[1]', 'varchar(20)')
    FROM src

    INSERT INTO dbo.History_Deadlock_Xml_Events (xeProcessID, xeTimeStamp, uuid, xeXML)
    SELECT xr.xeProcessID
        , xr.xeTimeStamp
        , uuid
        , xr.xeXML
    FROM #xmlResults xr
    WHERE NOT EXISTS (
        SELECT 1
        FROM dbo.History_Deadlock_Xml_Events dxe
        WHERE dxe.xeTimeStamp = xr.xeTimeStamp
            AND dxe.xeProcessID = xr.xeProcessID
        )
    AND xr.xeTimeStamp > @Ultimo_Log

END
GO


CREATE TABLE dbo.History_Deadlock_Xml_Events
(
   xeTimeStamp datetimeoffset NOT NULL
 , xeProcessID varchar(20) NOT NULL
 , uuid UNIQUEIDENTIFIER NOT NULL
 , xeXML XML NOT NULL
 , CONSTRAINT deadlock_xml_events_pk
 PRIMARY KEY CLUSTERED (uuid)
);


DECLARE @dataInicial datetimeoffset;
SET @dataInicial = '2023-05-12T10:00:00-03:00';

SELECT DATEADD(HOUR, 3, @dataInicial) AS dataAdicionada,
       SWITCHOFFSET(DATEADD(HOUR, 3, @dataInicial), DATEPART(TZOFFSET, @dataInicial)) AS dataAdicionadaPrecisa;

DECLARE @Ultimo_Log DATETIME2 = ISNULL((SELECT MAX(xeTimeStamp) FROM dbo.History_Deadlock_Xml_Events WITH(NOLOCK)), '1900-01-01')
SELECT @Ultimo_Log