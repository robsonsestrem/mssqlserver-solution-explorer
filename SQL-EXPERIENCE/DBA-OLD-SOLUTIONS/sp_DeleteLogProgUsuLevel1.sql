USE IntegraTICravil
GO

create or alter procedure LogErp.sp_DeleteLogProgUsuLevel1
(
 @qtdadeManterDias int = 365 -- Quantidade de dias para manter
)
with encryption
as
begin	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	BEGIN TRY 

		begin transaction
			declare @qtdadeDias int
			       ,@dataMin date

			set @qtdadeDias = 
			(select count(x.Registros)
				from
				(
				select count(*) as [Registros]
				from IntegraTICravil.LogErp.ProgUsuLevel1LogDML as t1
				group by cast(t1.DateDML as date)
				) as x
			)

			WHILE( @qtdadeDias > @qtdadeManterDias ) 
			  BEGIN 
				  set @dataMin = 
				  (
					  select cast(dateadd(day, 1 ,((select min(t1.DateDML) from IntegraTICravil.LogErp.ProgUsuLevel1LogDML as t1))) as date)
				  )
				  
				  DELETE FROM IntegraTICravil.LogErp.ProgUsuLevel1LogDML
				  WHERE DateDML < @dataMin 										  
				  
				  set @qtdadeDias -= 1
				  				  			  
			  END 
		commit transaction

	END TRY 

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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteLogProgUsuLevel1]:<b> <br>
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

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED 

end






