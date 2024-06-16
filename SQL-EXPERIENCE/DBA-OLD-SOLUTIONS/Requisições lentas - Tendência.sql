-------------------------------------------------------
-- Para usuários
-------------------------------------------------------
declare @Dt_Inicial datetime = '20180101'
	   ,@Dt_Final datetime = getdate()
select 
 convert(varchar(10),y.StartTime,103)		  AS StartTime	
, y.DataBaseName	
, count(y.TextData)							  AS QTD
, cast(avg(y.Duration) as numeric(15,2))	  AS MediaSegundos
, cast(max(y.Duration) / 60 as numeric(15,2)) AS TopDurationMinutes
from
(
	select x.DataBaseName, x.Duration, x.LoginName, x.RotinasGuru, x.StartTime, x.TextData
	from
	(
		select 		
				t.DatabaseName,				
				case when t.LoginName = 'guru' and t.DataBaseName = 'gescooper90' then 'guruadm'
					 when t.LoginName = 'guru' and t.DataBaseName <> 'gescooper90' then 'guruUser'
				else 'outros'
				End as RotinasGuru,				
				t.LoginName,		
				t.StartTime,
				t.Duration, 
				t.TextData								
		from Maintenance.Management.TraceSlowQuery as t with(nolock)
		where t.Starttime between @Dt_Inicial and @Dt_Final						
		and t.Duration >= 30.00						
		and t.LoginName not in ('CRAVIL\Nfe', 'CRAVIL\Task', 'CRAVIL\administrator', 'CRAVIL\backupexec', 'CRAVIL\sqlserver', 'CRAVIL\vcenter'
							   , 'NT SERVICE\MSSQLSERVER','NT SERVICE\SQLSERVERAGENT', 'NT AUTHORITY\SYSTEM', 'sa', 'admcravil', 'gescooper', 'CRAVIL\domo'
							   , 'admrobson', 'admadriana', 'CRAVIL\TI-01', 'CRAVIL\TI-02', 'CRAVIL\TI-03', 'CRAVIL\TI-04', 'CRAVIL\TI-05'
							   , 'CRAVIL\adm1', 'CRAVIL\adm2', 'CRAVIL\adm3', 'CRAVIL\adm4', 'CRAVIL\adm5', 'CRAVIL\adm6', 'agrosystem', 'dbarobson'
							   , 'CRAVIL\rdorneldba', 'CRAVIL\rdornel', 'CRAVIL\Teclogica', 'CRAVIL\consultorpgi', 'CRAVIL\Altovale', 'CRAVIL\Maxprotection'
							   , 'CRAVIL\Infogen03', 'CRAVIL\Infogen02', 'CRAVIL\Infogen01', 'infadriano', 'infedivaldo', 'infedivan', 'CRAVIL\Networkbrasil'
							   , 'infeliezer', 'infivan', 'infjehan', 'infjoabel', 'infmarcelo', 'inftiago', 'infogenbi','suptcadm', 'vpxuser', 'sqlmdsmon')   		
		and t.ApplicationName not in ('Microsoft SQL Server Management Studio - Query', '%DatabaseMail - DatabaseMail%')	
		and t.DataBaseName = 'gescooper90'	
	) as x
	where x.RotinasGuru <> 'guruadm'

) as y
group by  convert(varchar(10),y.StartTime,103)
		, y.DatabaseName


-------------------------------------------------------------------------------------------------------------------------------------
-- Para as tarefas  ## usuário guru aqui é tratado só como serviço (muito ruim de tratar já que é default das databases guru5 e 6)
-- e o objetivo é direcionado mais para o GesCooper90
-------------------------------------------------------------------------------------------------------------------------------------
declare @Dt_Inicial datetime = '20180101'
	   ,@Dt_Final datetime = getdate()
select 
		convert(varchar(10),t.StartTime,103)			AS StartTime,
		t.DatabaseName,
		count(t.TextData)								AS QTD,	
	    cast(avg(t.Duration) / 60 as numeric(15,2))		AS AverageMinutes,
		cast(max(t.Duration)	/ 60 as numeric(15,2))	AS TopDurationMinutes
						
from Maintenance.Management.TraceSlowQuery as t with(nolock)
where t.Starttime between @Dt_Inicial and @Dt_Final						
and t.Duration >= 30.00						
and t.LoginName in ('CRAVIL\Nfe', 'CRAVIL\Task', 'CRAVIL\administrator', 'CRAVIL\backupexec', 'CRAVIL\sqlserver', 'CRAVIL\vcenter'
							   ,'NT SERVICE\MSSQLSERVER','NT SERVICE\SQLSERVERAGENT', 'NT AUTHORITY\SYSTEM', 'sa', 'admcravil', 'gescooper', 'CRAVIL\rdornel', 'CRAVIL\domo'
							   ,'CRAVIL\Infogen03', 'CRAVIL\Infogen02', 'CRAVIL\Infogen01', 'infadriano', 'infedivaldo', 'infedivan'
							   ,'infeliezer', 'infivan', 'infjehan', 'infjoabel', 'infmarcelo', 'inftiago', 'infogenbi','suptcadm', 'vpxuser', 'sqlmdsmon')  
group by   convert(varchar(10),t.StartTime,103)
		 , t.DatabaseName

	

	