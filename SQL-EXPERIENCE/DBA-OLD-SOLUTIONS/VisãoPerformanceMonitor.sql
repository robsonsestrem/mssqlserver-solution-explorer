use YOUR_DATABASE
go
----------------------------------------------------------------------------------------------------------------------------------------------------
-- Current Disk Queue Length
----------------------------------------------------------------------------------------------------------------------------------------------------
select 
	  case t1.CounterID 
	   when 5 then 'Current Disk Queue Length'
	   when 4 then '% Idle Time'
	   when 6 then 'Avg. Disk Read Queue Length'
	   when 7 then 'Avg. Disk Write Queue Length'
	   when 8 then '% Disk Time'
	   when 9 then 'Disk Read Bytes/sec'
	   when 10 then 'Disk Write Bytes/sec'
	   when 190 then 'Split IO/Sec'
	   end as HardDisk		
	   , convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     )				
	   as DateReference	

	   , convert(date,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2))
		as [Date]

		, datepart(HOUR,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Horas	
	
	   , datepart(MINUTE,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Minutos	
	   , round(t1.CounterValue,2) as CounterValue
from CounterData as t1
where t1.CounterID in (4,5,6,7,8,9,10,190)

----------------------------------------------------------------------------------------------------------------------------------------------------
-- % Processor Time; Processor Queue Length; Thread Count
----------------------------------------------------------------------------------------------------------------------------------------------------
select case t1.CounterID 
	   when 12 then '% Processor Time'
	   when 22 then 'Processor Queue Length'
	   when 11 then 'Thread Count'
	   end as CPU
	   , convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     )				
	   as DateReference
	   , convert(date,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2))
	   as [Date]
	   
	   , datepart(HOUR,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Horas	
	
	   , datepart(MINUTE,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Minutos
	   	  
	   , round(t1.CounterValue,2) as CounterValue
from CounterData as t1
where t1.CounterID in (22,12, 11)


----------------------------------------------------------------------------------------------------------------------------------------------------
-- Memory em Gb
-- http://www.sqlteam.com/forums/topic.asp?topic_id=122326
-- , cast(round(cast(t1.CounterValue AS Numeric(15,4)) /1024/1024/1024, 2) as decimal(10,2)) as totalsize1
-- , CAST(t1.CounterValue / 1073741824.0E AS DECIMAL(10, 2)) as totalsize2
----------------------------------------------------------------------------------------------------------------------------------------------------
select case t1.CounterID 
	   when 131 then 'Available Bytes'
	   when 3 then 'Committed Bytes'
	   when 18 then 'Memory Grants Pending'
	   end as Memory
	   , convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     )				
	   as DateReference	

	   , convert(date,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2))
		as [Date]

		, datepart(HOUR,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Horas	
	
	   , datepart(MINUTE,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Minutos  	  	   
	   , CAST(t1.CounterValue / 1073741824 AS DECIMAL(10, 2)) as CounterValue_Gb

from CounterData as t1
where t1.CounterID in (131, 3, 18)


----------------------------------------------------------------------------------------------------------------------------------------------------
-- Contadores espec�ficos do SQL Server
----------------------------------------------------------------------------------------------------------------------------------------------------
select case t1.CounterID 
	   when 13 then 'Buffer cache hit ratio'	
	   when 14 then 'Page life expectancy'	
	   when 16 then 'Lock Waits/sec'		  
	   when 19 then 'Batch Requests/sec'			   
	   when 20 then 'SQL Compilations/sec'	
	   when 21 then 'SQL Re-Compilations/sec'
	   when 153 then 'Page reads/sec'
	   when 152 then 'Page lookups/sec'
	   when 158 then 'Logins/sec'
	   when 159 then 'Logouts/sec'
	   when 160 then 'User Connections'
	   end as [SQL Counter]
	   , convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     )				
	   as DateReference
	    , convert(date,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2))
		as [Date]

		, datepart(HOUR,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Horas	
	
	   , datepart(MINUTE,convert(datetime,left(t1.CounterDateTime, 4) +  
                          substring(t1.CounterDateTime, 6, 2) +  
                          substring(t1.CounterDateTime, 9, 2) + ' ' +
						  substring(t1.CounterDateTime, 12, 2) + ':' +
						  substring(t1.CounterDateTime, 15, 2) + ':' +
						  substring(t1.CounterDateTime, 18, 2) + '.'+
						  substring(t1.CounterDateTime, 21,3)
			     ))				
	   as Minutos 
	   , round(t1.CounterValue,2) as CounterValue
from CounterData as t1
where t1.CounterID in (13,14,16,19,20,21,153,152,158,159,160)

