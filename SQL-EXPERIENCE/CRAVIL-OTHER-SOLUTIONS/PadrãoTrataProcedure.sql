-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Uso geral
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go

create or alter procedure sp_NomeProc
with encryption
as
begin 
	set nocount on
	
	begin try
		begin transaction


		commit transaction
	end try


	begin catch
		rollback transaction
			declare @corpofalha varchar(max)
				  , @subject varchar(100)			-- assunto
				  , @recipients varchar(100);		-- destinatário				
			set @subject = 'falha na execução de procedure: '+@@servername;
			set @recipients = 'robson@cravil.com.br';
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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>falha na procedure [sp_nomeproc]:<b> <br>
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


-----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Usado na CooperSystem
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
use CooperSystem
go

create or alter procedure system.sp_NomeProc
as
begin
	set nocount on
	set xact_abort on

	begin try
		begin transaction

		 
		commit transaction
	end try


	begin catch
		select error_number() as errnum, error_message() as errmsg;
		if(xact_state()) = -1  
			begin  
				print 'a transação está em um estado incompatível.' +  
					  ' retroceder transação'  
				rollback transaction;  
			end;  

			-- teste se a transação está ativa e válida. 
			if (xact_state()) = 1  
			begin  
				print 'a transação é compatível.' +   
					  ' transação completada.'  
				commit transaction;     
			end;  
	end catch

	set nocount off
	set xact_abort off

end
