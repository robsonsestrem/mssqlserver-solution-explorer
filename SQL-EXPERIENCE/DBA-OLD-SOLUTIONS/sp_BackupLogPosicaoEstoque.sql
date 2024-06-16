use IntegraTICravil
go

create or alter procedure Bi.sp_BackupLogPosicaoEstoque
(
	@limiteSeconds int = 60 
)
with encryption
as
begin

	begin try
		declare 
			  @initialTime datetime = getdate()
			, @seconds int = 0	
			, @WaitForTime as varchar(12) = '00:00:05.000'

		while(@seconds < @limiteSeconds)
		begin	
			BACKUP LOG [IntegraTICravil] TO  DISK = N'F:\Log_SSMS\IntegraTICravil_DeletePosicaoEstoque.trn' 
			WITH NOFORMAT, NOINIT,  NAME = N'IntegraTICravil-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10	

			waitfor delay @WaitForTime

			set @seconds = (select DATEDIFF(SECOND, @initialTime, GETDATE()))		
		end
	end try

	BEGIN CATCH
			ROLLBACK TRANSACTION
			DECLARE @corpoFalha varchar(max)
				  , @subject VARCHAR(100)			-- assunto
				  , @recipients VARCHAR(100);		-- destinatário				
			SET @subject = 'Falha na execução de Procedure: '+@@SERVERNAME;
			SET @recipients = 'suporte@cravil.com.br';
			SET @corpoFalha = '	
				<html>
				<head>
				<meta http-equiv=Content-Type content=text/html; charset=windows-1252>
				</head>
				<body>
				<div align=left>'
			SELECT @corpoFalha = @corpoFalha + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_BackupLogPosicaoEstoque]:<b> <br>
				  </td>
				 </tr>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
					  <br> [ERROR NUMBER] - '+ cast(ERROR_NUMBER() as varchar(10)) + '
					  <br>				  
					  <br> [LINE] - '+ cast(ERROR_LINE() as varchar(10)) + '
					  <br>
					  <br> [MESSAGE] - '+  ERROR_MESSAGE() + '
				   </td>
				  </tr>
			</table>'

			SELECT @corpoFalha = @corpoFalha + 
				'</div>
				</body>
				</html>'

			EXEC [msdb].[dbo].[sp_send_dbmail]
					@recipients = @recipients,
					@subject = @subject,
					@profile_name = 'CRAVIL',
					@body = @corpoFalha,
					@body_format = 'HTML';

			END CATCH
end



