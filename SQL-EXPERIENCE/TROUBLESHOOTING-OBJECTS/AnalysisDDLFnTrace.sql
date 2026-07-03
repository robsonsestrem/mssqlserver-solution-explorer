--------------------------------------------------------------------------------------------
-- https://www.mssqltips.com/sqlservertip/8221/who-created-that-sql-server-object/
--------------------------------------------------------------------------------------------
-- Run the following code to pull data from the active default trace file.
DECLARE @trace_path1 NVARCHAR(260)
SELECT @trace_path1=path FROM sys.traces WHERE is_default = 1
 
SELECT LoginName, ObjectName, DatabaseName, ServerName, ApplicationName, StartTime, 
  CASE EventClass
   when 164 then '164 - Altered'
   when 46 then '46 - Created'
   when 47 then '47 - Dropped'
  END as EventClass,
  EventSubClass,
  EventSequence
FROM sys.fn_trace_gettable(@trace_path1, 0)
WHERE EventClass IN (46, 47, 164)
ORDER BY StartTime DESC


--------------------------------------------------------------------------------------------
-- Below is the same script but modified for EventSubClass = 1.
--------------------------------------------------------------------------------------------
DECLARE @trace_path2 NVARCHAR(260)
SELECT @trace_path2=path FROM sys.traces WHERE is_default = 1
 
SELECT LoginName, ObjectName, DatabaseName, ServerName, ApplicationName, StartTime, 
CASE EventClass
   when 164 then '164 - Altered'
   when 46 then '46 - Created'
   when 47 then '47 - Dropped'
END as EventClass,
EventSubClass,
EventSequence
FROM sys.fn_trace_gettable(@trace_path2, 3 )
WHERE EventClass IN (46, 47, 164) and EventSubClass = 1
ORDER BY StartTime DESC
