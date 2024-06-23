use Maintenance
go
select * from Management.DDLTransaction as d
where d.DateDDl >= '20190502' -- and d.DateDDl < '20181206'
and d.DatabaseName = 'rhcravil'
and d.ObjectType <> 'INDEX'
--and d.ObjectName like '%sp_WhoIsActive%'
--and d.LoginUser like '%dornel%'


-----------------------------------------------------------------------------------------------------------------
use Maintenance
go
select * from Management.TraceSlowQuery
where StartTime >= '20190424' -- AND StartTime <= '20171108'
--and applicationName not like '%DatabaseMail - DatabaseMail%'
--and LoginName = 'suptcadm'
and ApplicationName not like '%SQLAgent - TSQL JobStep%'
and ApplicationName not like '%DatabaseMail - DatabaseMail%'
and ApplicationName not like 'Veritas Backup Exec (TM)'


-----------------------------------------------------------------------------------------------------------------
select * from Management.HistoryErrorLogin as t1
where t1.DateError >= '20190424'
--AND t1.TextData NOT LIKE '%network error code%'
order by DateError desc


-----------------------------------------------------------------------------------------------------------------
select * from Management.HistorySecurityChange as t1
order by t1.EventTime desc


-----------------------------------------------------------------------------------------------------------------
select * from Management.HistoryServerConfig as t1
order by t1.DateInsert desc


-----------------------------------------------------------------------------------------------------------------
select * from Management.HistoryDBFileGrowth as t1
order by t1.DateInsert desc


-----------------------------------------------------------------------------------------------------------------
select * from Management.CountPLE


-----------------------------------------------------------------------------------------------------------------
select * from Management.Job_Audit


-----------------------------------------------------------------------------------------------------------------
-- https://gallery.technet.microsoft.com/scriptcenter/SQL-Server-Audit-Events-4fbcb126
-- SQL Server Data and Log File Shrinks --
-----------------------------------------------------------------------------------------------------------------
DECLARE @path NVARCHAR(260)

SELECT @path=path FROM sys.traces WHERE is_default = 1

--Database: Data & Log File Shrink
SELECT TextData, Duration, 
       StartTime, EndTime, 
	   SPID, ApplicationName, 
	   LoginName  
FROM sys.fn_trace_gettable(@path, DEFAULT)
WHERE EventClass IN (116) 
AND TextData like 'DBCC%shrink%'
ORDER BY StartTime DESC