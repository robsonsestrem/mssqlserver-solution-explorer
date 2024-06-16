select case t1.CounterID   
	   when 19 then 'Batch Requests/sec'			   
	   when 20 then 'SQL Compilations/sec'	
	   when 21 then 'SQL Re-Compilations/sec'	 
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
where t1.CounterID in (19,20,21)

union all

select 'Threshold_Compilation' as [SQL Counter]
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
	   , round(t1.CounterValue,2) * 0.1  as CounterValue
from CounterData as t1
where t1.CounterID in (19)

union all

select 'Threshold_Recompilation' as [SQL Counter]
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
	   , round(t1.CounterValue,2) * 0.01  as CounterValue
from CounterData as t1
where t1.CounterID in (19)


