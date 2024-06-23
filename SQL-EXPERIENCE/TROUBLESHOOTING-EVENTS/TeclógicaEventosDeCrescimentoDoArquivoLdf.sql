----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Concedido pela TECLÓGICA, este vai mostrar os eventos de crescimento do arquivo de log, assim poderá ter noção se o espaço inicial configurado é suficiente, 
-- pois se tiver muitos eventos, é sinal que precisa aumentar o Initial size.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use GesCooper90
go
DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);
 
-- Get the name of the current default trace
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2;
 
-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.',@filename);
SET @ec = CHARINDEX('_',@filename)+1;
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc));
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)));
 
-- set filename without rollover number
SET @filename = @bfn + @efn
 
-- process all trace files
SELECT 
  ftg.StartTime
,te.name AS EventName
,DB_NAME(ftg.databaseid) AS DatabaseName  
,ftg.Filename
,(ftg.IntegerData*8)/1024.0 AS GrowthMB 
,(ftg.duration/1000)/1000 AS Seconds
FROM ::fn_trace_gettable(@filename, DEFAULT) AS ftg 
INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id  
WHERE ftg.EventClass = 93 -- Log File Auto-grow
    AND ftg.databaseid = 5
    ORDER BY ftg.StartTime
	
	
	

