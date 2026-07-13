USE IntegraTICravil
GO

create or ALTER PROCEDURE Erp.sp_CheckXMLManifest
WITH ENCRYPTION
AS
BEGIN 
		SET NOCOUNT ON
		DECLARE @dataManifesto	DATETIME
				,@assuntoEmail  NVARCHAR(70)
				,@CorpoEmail	NVARCHAR(MAX)

		BEGIN TRY
			BEGIN TRANSACTION
			SET @dataManifesto = (SELECT f.FilNfeDatHorManDes FROM YOUR_DATABASE.dbo.FILIAIS as f WHERE f.FilCod = 1)

			IF(	(DATEDIFF(DAY,@dataManifesto, GETDATE()) <= 3 and datepart(WEEKDAY,@dataManifesto) = 6) OR	(DATEDIFF(DAY,@dataManifesto, GETDATE()) < 2 and datepart(WEEKDAY,@dataManifesto) <> 6))
				   BEGIN
					print 'funcionando'
				   END	   

			IF(	(DATEDIFF(DAY,@dataManifesto, GETDATE()) >= 2 and datepart(WEEKDAY,@dataManifesto) <> 6) OR	(DATEDIFF(DAY,@dataManifesto, GETDATE()) > 3 and datepart(WEEKDAY,@dataManifesto) = 6))
				   BEGIN
			
					SET @CorpoEmail = '
											<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
											<tr height=20  style=color:black;>
												<td width=300 style=height:20.0pt>Faz dois dias ou mais que n�o foi realizado download automaticamente de alguma(s) filial(ais).
												<br>Abaixo data de �ltimo xml baixado do sefaz por filial: </td>
											</tr>
											</table>
											<br><br>

											<TABLE border=0 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:900pt;font-family:Arial;font-size:14px>															
											<tr height=20  style=height:20.0pt align = center>
												<td bgcolor=#0B0B61 width=200> <font color=white>Filial</td>
												<td bgcolor=#0B0B61 width=200> <font color=white>�ltimo download XML</td>										
											</tr>
										  ';

					SELECT @CorpoEmail = @CorpoEmail +
			 
						CASE WHEN CAST(ROW_NUMBER() OVER(ORDER BY f.FilNfeDatHorManDes) % 2 as bit) = 1 THEN '<tr height=20 style=height:15.0pt align= center>'
							ELSE '<tr height=20 style=height:15.0pt; background:#E4E4E4; align= center>'
						END +

						'<td height=20 style=height:15.0pt>'+ CAST(f.FilCod AS VARCHAR(10))					+ '</td>'+				
						'<td height=20 style=height:15.0pt>'+ convert(varchar(12),f.FilNfeDatHorManDes,105)	+ '</td>'

					FROM YOUR_DATABASE.dbo.FILIAIS as f
					WHERE f.FilCod = 1

					SELECT @CorpoEmail = @CorpoEmail +
					'</tr></table>'+'<br><br>'
					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- envia e-mail
					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					SET @assuntoEmail = 'Poss�vel falha na rotina de download de xml - Manifesto Destinat�rio'
					EXEC msdb.dbo.sp_send_dbmail
											@profile_name =		'CRAVIL',
											@recipients =		'suporte@cravil.com.br;adriana@cravil.com.br;adami@cravil.com.br', 						
											@subject =			@assuntoEmail,
											@body =				@CorpoEmail
											,@body_format =		'HTML'						
											--,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
				   END	--fim do if
				COMMIT TRANSACTION
			END TRY
			BEGIN CATCH
				ROLLBACK TRANSACTION
				DECLARE @corpoFalha varchar(max)
						, @subject VARCHAR(100)			-- assunto
						, @recipients VARCHAR(100);		-- destinat�rio				
				SET @subject = 'Falha na execu��o de Procedure: '+@@SERVERNAME;
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
					  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_CheckXMLManifest]:<b> <br>
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