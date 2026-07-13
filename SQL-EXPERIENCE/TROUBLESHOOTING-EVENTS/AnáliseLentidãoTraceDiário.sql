--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo das execu��es para an�lise de usu�rios de sistema YOUR_DATABASE e n�o tarefas.
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO
declare @Dt_Inicial datetime,
		@Dt_Final datetime

SET 	@Dt_Inicial = '20181119'  
SET		@Dt_Final = floor(cast(getdate() as float))	  -- floor faz come�ar do zero naquele dia

select replace(replace(replace(x.Comando, CHAR(9), ''),CHAR(10),''), CHAR(13), '') AS Comando 
     , x.DataBaseName, x.LoginName, x.ApplicationName, x.HostName, x.QTD, x.LastTime,  x.Total_time
	 , x.AVG_Time, x.MIN_Time, x.MAX_Time, x.Total_reads, x.Writes, Total_cpu
from
(
	select 
			t.TextData							AS Comando,
			t.DatabaseName,
			t.LoginName,
			--
			case when t.LoginName = 'guru' and t.DataBaseName = 'YOUR_DATABASE' then 'guruadm'
				 when t.LoginName = 'guru' and t.DataBaseName <> 'YOUR_DATABASE' then 'guruUser'
				else 'outros'
			End									AS RotinasGuru,
			--
			t.ApplicationName,
			t.HostName,
			(select max(t2.EndTime)	
			from Management.TraceSlowQuery as t2
			where t2.TextData = t.TextData)		AS LastTime,
			count(t.TextData)					AS QTD,							-- Qtdade de vezes que a query demorou mais de 30 segundos
			sum(Duration)						AS Total_time,					-- Tempo total das execu��es
			avg(t.Duration)						AS AVG_Time,						-- Tempo m�dio das execu��es
			min(t.Duration)						AS MIN_Time,						-- Menor tempo de execu��o
			Max(t.Duration)						AS MAX_Time,						-- Maior tempo de execu��o								
			sum(CAST(t.Reads	AS bigint))		AS Total_reads,	-- soma destes
			sum(CAST(t.writes AS bigint))		AS Writes,		-- recursos	
			sum(CAST(t.cpu	AS bigint))			AS Total_cpu	-- por execu��o/query
	from Management.TraceSlowQuery as t with(nolock)
	where t.Starttime >= @Dt_Inicial and t.Starttime <= @Dt_Final -- Periodo a ser analizado
	and t.Duration >= 20.00					
		and t.LoginName not in ('cravil\nfe', 'cravil\task', 'cravil\administrator', 'cravil\backupexec', 'cravil\sqlserver', 'cravil\vcenter', 'CRAVIL\rdornel', 'CRAVIL\rdorneldba'
								, 'nt service\mssqlserver','nt service\sqlserveragent', 'nt authority\system', 'YOUR_DATABASE', 'admadriana', 'admcravil', 'admrobson'
								, 'cravil\domo','cravil\infogen03', 'agrosystem', 'consulta', 'YOUR_DATABASE', 'guru', 'cravil\infogen02', 'cravil\infogen01'
								, 'infadriano', 'infedivaldo', 'infedivan', 'infeliezer', 'infivan', 'infjehan'
								, 'infernando', 'infmarcelo', 'inftiago','infneimar', 'suptcadm', 'vpxuser', 'sqlmdsmon')   		
		and t.ApplicationName not in ('Microsoft SQL Server Management Studio - Query', '%DatabaseMail - DatabaseMail%')
		and t.DataBaseName = 'YOUR_DATABASE'

	group by TextData, DatabaseName, LoginName, ApplicationName, HostName
	having count(TextData) > 1 -- trazer as querys demoradas que repetiram mais de uma vez
) as x
where x.RotinasGuru <> 'guruadm' -- and x.LastTime >= '20180701'
order by x.QTD desc, x.LoginName


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo das execu��es para an�lise de tarefas
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
declare @Inicio datetime = '20180101'
	   ,@Fim datetime = floor(cast(getdate()-1 as float))
select 
		convert(varchar(10),t.StartTime,103)			AS StartTime,
		t.DatabaseName,
		count(t.TextData)								AS QTD,	
	    cast(avg(t.Duration) / 60 as numeric(15,2))		AS AverageMinutes,
		cast(max(t.Duration)	/ 60 as numeric(15,2))	AS TopDurationMinutes
						
from YOUR_DATABASE.Management.TraceSlowQuery as t with(nolock)
where t.Starttime between @Inicio and @Fim						
and t.Duration >= 30.00												
and t.LoginName in ('cravil\nfe', 'cravil\task', 'cravil\administrator', 'cravil\backupexec', 'cravil\sqlserver', 'cravil\vcenter', 'CRAVIL\rdornel', 'CRAVIL\rdorneldba'
								, 'nt service\mssqlserver','nt service\sqlserveragent', 'nt authority\system', 'YOUR_DATABASE', 'admadriana', 'admcravil', 'admrobson'
								, 'cravil\domo','cravil\infogen03', 'agrosystem', 'consulta', 'YOUR_DATABASE', 'guru', 'cravil\infogen02', 'cravil\infogen01'
								, 'infadriano', 'infedivaldo', 'infedivan', 'infeliezer', 'infivan', 'infjehan'
								, 'infernando', 'infmarcelo', 'inftiago','infneimar', 'suptcadm', 'vpxuser', 'sqlmdsmon') 
and t.HostName not in ('WTS01', 'WTS02', 'WTS01')
group by   convert(varchar(10),t.StartTime,103)
		 , t.DatabaseName


---------------------------------------------------------------------------------------------------------------------------------------------
-- Conferindo todos os dados que foram armazenados no trace do dia
---------------------------------------------------------------------------------------------------------------------------------------------
Select  --DATALENGTH(Textdata) as bytes
	   TextData
	   , NTUserName, HostName, ApplicationName, LoginName, SPID, cast(Duration /1000/1000.00 as numeric(15,2)) as DurationSegundos,
	   Duration as DurationMicrossegundos, Starttime, EndTime, Reads, writes, CPU, Servername, DatabaseName, rowcounts, SessionLoginName
FROM :: fn_trace_gettable(N'C:\DBACravil\Trace\Querys_Demoradas.trc', default)
where Duration is not null
order by cpu desc


-- Identificar textdata problem�tico do dia 14-01-2018, o RowCount dele � de 454136
-- Segue erro:
-- An error occurred while executing batch. Error message is: Exception of type 'System.OutOfMemoryException' was thrown.


select 484123978 / 1024.00 / 1024.00 as Mb
-- 44292892