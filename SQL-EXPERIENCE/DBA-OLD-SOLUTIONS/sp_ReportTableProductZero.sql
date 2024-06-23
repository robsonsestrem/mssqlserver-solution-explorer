use IntegraTICravil
go

CREATE OR ALTER PROCEDURE Erp.sp_ReportTableProductZero
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON	
	declare @buscaZero		   INT
		   ,@assuntoEmail      NVARCHAR(70)
		   ,@CorpoEmail		   NVARCHAR(MAX)
	BEGIN TRY
		BEGIN TRANSACTION
			set @buscaZero = (select count(p.ProCod) from GesCooper90.dbo.PRODUTOSLEVEL4 as p where p.ProCodPreco = 0)
			IF(@buscaZero > 0)
				BEGIN
					SET @CorpoEmail = '
											<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
											<tr height=20  style=color:black;>
												<td width=300 style=height:20.0pt>Data de movimento: '+convert(varchar(12),getdate(),105)+'										
													<br>Ação necessária: Deletar este(s) registro(s) com código zero da tabela PRODUTOSLEVEL4.
													<br>Sistema apresentou zero no código de filial para preço, segue o(s) iten(s) abaixo:									 																			
												</td>
											</tr>
											</table>
											<br><br>

											<TABLE border=0 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:900pt;font-family:Arial;font-size:14px>															
											<tr height=20  style=height:20.0pt align = center>
												<td bgcolor=#0B0B61 width=200> <font color=white>Código Produto</td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Código Filial_Preço</td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Data Inicio</td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Data Final</td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Data Alteração</td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Preço</td>
											</tr>
										  ';

					SELECT @CorpoEmail = @CorpoEmail +
			 
						CASE WHEN CAST(ROW_NUMBER() OVER(ORDER BY p.ProCod) AS BIT) % 2 = 1 THEN '<tr height=20 style=height:15.0pt align= center>'
							ELSE '<tr height=20 style=height:15.0pt; background:#E4E4E4; align= center>'
						END +

						'<td height=20 style=height:15.0pt>'+ CAST(p.ProCod AS VARCHAR(10))				+ '</td>'+
						'<td height=20 style=height:15.0pt>'+ CAST(p.ProCodPreco AS VARCHAR(4))			+ '</td>'+
						'<td height=20 style=height:15.0pt>'+	CONVERT(VARCHAR(12),p.ProDatIni,105)		+ '</td>'+
						'<td height=20 style=height:15.0pt>'+	CONVERT(VARCHAR(12),p.Final,105)			+ '</td>'+
						'<td height=20 style=height:15.0pt>'+	CONVERT(VARCHAR(12),p.ProDatAlteracao,105)	+ '</td>'+
						'<td height=20 style=height:15.0pt>'+ CAST(p.ProVlrPreco AS VARCHAR(20))			+ '</td>'

					FROM GesCooper90.dbo.PRODUTOSLEVEL4 as p
					WHERE p.ProCodPreco = 0

					SELECT @CorpoEmail = @CorpoEmail +
					'</tr></table>'+'<br><br>'

					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- envia e-mail
					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					SET @assuntoEmail = 'Inconsistência Sistêmica - Código Zero de Filial para Preço'
					EXEC msdb.dbo.sp_send_dbmail
											@profile_name =		'CRAVIL',
											@recipients =		'suporte@cravil.com.br;adriana@cravil.com.br;adriana@cravil.com.br;', 						
											@subject =			@assuntoEmail,
											@body =				@CorpoEmail
											,@body_format =		'HTML'						
											--,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
				END --fim do if
			COMMIT TRANSACTION
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportTableProductZero]:<b> <br>
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
	SET NOCOUNT OFF
END