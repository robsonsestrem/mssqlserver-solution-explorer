USE IntegraTICravil
GO

create or alter procedure Bi.sp_DeletePosicaoEstoque
(
 @qtdadeManterDias int = 60 -- Quantidade de dias para manter conforme data de emissão
)
with encryption
as
begin

	SET STATISTICS TIME ON 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	BEGIN TRY 

		begin transaction
			declare @qtdadeDias int
			       ,@dataMin datetime

			set @qtdadeDias = 
			(select count(x.Data) as TotalDias
				from 
				(
				select count(*) as [Data]
				from bi.HistoricoPosicaoEstoque as t1
				group by cast(t1.DataEmissao as date)
				) as x
			)

			WHILE( @qtdadeDias > @qtdadeManterDias ) 
			  BEGIN 
				  set @dataMin = 
				  (
					select min(t1.DataEmissao) as dataMin from Bi.HistoricoPosicaoEstoque as t1
				  )
				  
				  DELETE FROM bi.historicoposicaoestoque 
				  WHERE  dataemissao <= @dataMin 										  
				  
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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeletePosicaoEstoque]:<b> <br>
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
	SET STATISTICS TIME OFF 

end






