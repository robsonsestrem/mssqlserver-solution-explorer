use YOUR_DATABASE
go

create or alter procedure Management.sp_ProcesskillIdle
(
 @idleTime time = '05:00:00.000'
)
with encryption
as
begin 
	set nocount on
	
	begin try
		
		if (object_id('tempdb..##whoisactive') is not null) 
			drop table ##whoisactive

		create table ##whoisactive ( 
		 [dd hh:mm:ss.mss] varchar(8000) null
		, [session_id] smallint null
		, [login_name] nvarchar(128) null
		, [host_name] nvarchar(128) null
		, [status] varchar(30) null
		, [database_name] nvarchar(128) null
		, [open_tran_count] varchar(30) null
		, [program_name] nvarchar(128) null
		, [collection_time] datetime null
		, [start_time] datetime null
		, [login_time] datetime null
		, [sql_text] xml null
		, [sql_command] xml null		
		)

		execute management.sp_whoisactive
		@show_own_spid = 0			-- <> @@spid
		, @show_system_spids = 0	-- session_id > 50
		, @get_outer_command = 1	
		, @output_column_list = 
		'
		, [dd hh:mm:ss.mss]
		, [session_id]
		, [login_name]
		, [host_name]
		, [status]
		, [database_name]
		, [open_tran_count]
		, [program_name]
		, [collection_time]
		, [start_time]
		, [login_time]
		, [sql_text]
		, [sql_command]				
		'
		, @destination_table = 'tempdb..##whoisactive'
		
		---------------------------------------------------------------------------------------------------------------------------------------
		-- salvando informa��es dos processos
		---------------------------------------------------------------------------------------------------------------------------------------
		insert into [YOUR_DATABASE].[Management].[HistoryKillProcess]
		select 
		x.[dd hh:mm:ss.mss], x.session_id, x.login_name, x.[host_name], x.[status], x.[database_name]
		, x.open_tran_count, x.[program_name], x.collection_time, x.start_time, x.login_time, x.sql_text, x.sql_command
		from
		(
			select * 
			, cast(right(t1.[dd hh:mm:ss.mss], 12) as time) as horas
			from ##whoisactive as t1
			where t1.login_name in 
			('cravil\nfe', 'cravil\task', 'cravil\administrator', 'cravil\backupexec', 'cravil\sqlserver', 'cravil\vcenter'
			 ,'nt service\mssqlserver','nt service\sqlserveragent', 'nt authority\system', 'YOUR_DATABASE', 'admadriana'
			 ,'cravil\domo','cravil\infogen03', 'agrosystem', 'consulta', 'YOUR_DATABASE', 'guru', 'cravil\infogen02', 'cravil\infogen01'
			 , 'infadriano', 'infedivaldo', 'infedivan', 'infeliezer', 'infivan', 'infjehan'
			 , 'infernando', 'infmarcelo', 'inftiago','infneimar', 'suptcadm', 'vpxuser', 'sqlmdsmon')  
			and t1.[database_name] in ('YOUR_DATABASE')
		) as x
		where x.horas > @idleTime
		
		---------------------------------------------------------------------------------------------------------------------------------------
		-- concatenando spids
		---------------------------------------------------------------------------------------------------------------------------------------
		declare @query varchar(max) = ''
		select 
		@query = coalesce(@query, ',') + 'kill ' + convert(varchar, x.session_id) + '; '
		from
		(
			select * 
			, cast(right(t1.[dd hh:mm:ss.mss], 12) as time) as horas
			from ##whoisactive as t1
			where t1.login_name in 
			('cravil\nfe', 'cravil\task', 'cravil\administrator', 'cravil\backupexec', 'cravil\sqlserver', 'cravil\vcenter'
			 ,'nt service\mssqlserver','nt service\sqlserveragent', 'nt authority\system', 'YOUR_DATABASE', 'admadriana'
			 ,'cravil\domo','cravil\infogen03', 'agrosystem', 'consulta', 'YOUR_DATABASE', 'guru', 'cravil\infogen02', 'cravil\infogen01'
			 , 'infadriano', 'infedivaldo', 'infedivan', 'infeliezer', 'infivan', 'infjehan'
			 , 'infernando', 'infmarcelo', 'inftiago','infneimar', 'suptcadm', 'vpxuser', 'sqlmdsmon')  
			and t1.[database_name] in ('YOUR_DATABASE')
		) as x
		where x.horas > @idleTime	

		---------------------------------------------------------------------------------------------------------------------------------------
		-- executa matan�a
		---------------------------------------------------------------------------------------------------------------------------------------
		if (len(@query) > 0 and @@ROWCOUNT <> 0)
			exec(@query)		
		
	end try


	begin catch
			rollback transaction
			declare @corpofalha varchar(max)
				  , @subject varchar(100)			-- assunto
				  , @recipients varchar(100);		-- destinat�rio				
			set @subject = 'falha na execu��o de procedure: '+@@servername;
			set @recipients = 'suporte@cravil.com.br';
			set @corpofalha = '	
				<html>
				<head>
				<meta http-equiv=content-type content=text/html; charset=windows-1252>
				</head>
				<body>
				<div align=left>'
			select @corpofalha = @corpofalha + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:arial;font-size:14px>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>falha na procedure [sp_processkillIdle]:<b> <br>
				  </td>
				 </tr>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
					  <br> [error number] - '+ cast(error_number() as varchar(10)) + '
					  <br>				  
					  <br> [line] - '+ cast(error_line() as varchar(10)) + '
					  <br>
					  <br> [message] - '+  error_message() + '
				   </td>
				  </tr>
			</table>'

			select @corpofalha = @corpofalha + 
				'</div>
				</body>
				</html>'

			exec [msdb].[dbo].[sp_send_dbmail]
					@recipients = @recipients,
					@subject = @subject,
					@profile_name = 'cravil',
					@body = @corpofalha,
					@body_format = 'html';

	end catch
end

-- Exemplo
-- execute Management.sp_ProcesskillIdle @idleTime = '05:00:00.000'
