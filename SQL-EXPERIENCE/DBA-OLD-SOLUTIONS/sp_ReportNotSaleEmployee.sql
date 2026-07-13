use IntegraTICravil
go
CREATE OR ALTER PROCEDURE Erp.sp_ReportNotSaleEmployee
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
			DECLARE @datainicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
			DECLARE @datafinal datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))
		BEGIN TRANSACTION
		IF(
			(SELECT  COUNT(*)			
			  FROM  YOUR_DATABASE.dbo.VENDASECF        CUP WITH(NOLOCK)
			 INNER JOIN YOUR_DATABASE.dbo.TRANSACIONADORES TRA WITH(NOLOCK) ON CUP.CupCliCod   = TRA.TraCod
			 INNER JOIN YOUR_DATABASE.dbo.VENDASECFLEVEL2  PAG WITH(NOLOCK) ON CUP.FilCod      = PAG.FilCod
														 AND CUP.CupDatMov   = PAG.CupDatMov
														 AND CUP.CaiCod      = PAG.CaiCod 
														 AND CUP.CaiOpeCod   = PAG.CaiOpeCod 
														 AND CUP.CupCodigo   = PAG.CupCodigo
			WHERE TRA.TraNatJuridica  = 1 -- pessoa f�sica
			  AND TRA.TraNatSocial    = 3 -- funcion�rio
			  AND TRA.TraNatComercial = 2 -- funcion�rio  
			  AND (PAG.cuptottiprec =3 or PAG.cuptotfincod = 4)
			  AND CUP.CupSitIntegracao = 1	-- Trazer s� cupons integrados 
			  AND CUP.FilCod = 60 
			  AND CUP.CupDatMov BETWEEN @datainicio AND @datafinal  			
		    ) > 0)
			BEGIN
				   DECLARE 				
					@Assunto VARCHAR(200) = 'Aten��o - Ocorreram Poss�veis Vendas Indevidas',
					@Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br;denise@cravil.com.br',
					@Mensagem VARCHAR(MAX)
            		      
					SET @Mensagem = '
					Para conhecimento da controladoria,<br>
					segue informa��es sobre vendas nos caixa(s) para funcion�rio(s) no credi�rio, detalhes abaixo:					
					<br><br> 

					<TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:1200t;font-family:Arial;font-size:14px>															
											<tr height=20  style=height:20.0pt align = left>
												<td bgcolor=#0B0B61 width=90> <font color=white>Matr�cula	</td>
												<td bgcolor=#0B0B61 width=450> <font color=white>Nome			</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>Filial		</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>Caixa			</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>Operador		</td>
												<td bgcolor=#0B0B61 width=100> <font color=white>DataVenda	</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>Cupom			</td>										
												<td bgcolor=#0B0B61 width=70> <font color=white>Valor			</td>
												<td bgcolor=#0B0B61 width=100> <font color=white>Vencimento	</td>
												<td bgcolor=#0B0B61 width=90> <font color=white>Situa��o		</td>
											</tr>
										 '	
				   SELECT @Mensagem = @Mensagem + 

				   CASE	  WHEN CAST(ROW_NUMBER() OVER(ORDER BY TRA.TraNom ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt align = left>'
									  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align = left>'
								   END +
								   '<td height=20 style=height:15.0pt>' + CAST(TRA.TraCod AS varchar(10))											+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + TRA.TraNom																+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + CAST(TRA.TraFilCod AS varchar(3))										+ '</td>' +								   
								   '<td height=20 style=height:15.0pt>' + CAST(PAG.CaiCod	AS varchar(3))											+ '</td>' + 								   
								   '<td height=20 style=height:15.0pt>' +	CAST(PAG.CaiOpeCod	AS varchar(10))										+ '</td>' +										   
								   '<td height=20 style=height:15.0pt>' +	CONVERT(VARCHAR(20), PAG.CupDatMov, 103)								+ '</td>' +	
								   '<td height=20 style=height:15.0pt>' +		CAST(PAG.CupCodigo AS varchar(10)) 									+ '</td>' +	
								   '<td height=20 style=height:15.0pt>' +	(SELECT IntegraTICravil.Erp.fn_FormatIntToMoney(PAG.CupTotVlr))	+ '</td>' +	
								   '<td height=20 style=height:15.0pt>' +	CONVERT(VARCHAR(20), PAG.CupTotDatVct, 103) 							+ '</td>' +	
								   --
								   '<td height=20 style=height:15.0pt>' +	CASE when CUP.CupSituac = 1 then 'NORMAL'
																				 when CUP.CupSituac = 0 then 'CANCELADO'
																				ELSE 'INDEFINIDO'
																		    END																		+ '</td>' +
								   --
								   '</tr>'				      
				  FROM YOUR_DATABASE.dbo.VENDASECF CUP WITH(NOLOCK)
					 INNER JOIN YOUR_DATABASE.dbo.TRANSACIONADORES TRA WITH(NOLOCK) ON CUP.CupCliCod   = TRA.TraCod
					 INNER JOIN YOUR_DATABASE.dbo.VENDASECFLEVEL2  PAG WITH(NOLOCK) ON CUP.FilCod      = PAG.FilCod
																 AND CUP.CupDatMov   = PAG.CupDatMov
																 AND CUP.CaiCod      = PAG.CaiCod 
																 AND CUP.CaiOpeCod   = PAG.CaiOpeCod 
																 AND CUP.CupCodigo   = PAG.CupCodigo
				  WHERE TRA.TraNatJuridica  = 1 -- pessoa f�sica
					  AND TRA.TraNatSocial    = 3 -- funcion�rio
					  AND TRA.TraNatComercial = 2 -- funcion�rio  
					  AND (PAG.cuptottiprec =3 or PAG.cuptotfincod = 4)					   
					  AND CUP.CupDatMov BETWEEN @datainicio AND @datafinal  
					  AND CUP.FilCod = 60			
				  SELECT @Mensagem = @Mensagem + 
							 '</table>'+'<br><br>'
				  ---------------------------------------------------------------------------------------------------------------------------------------------------
				  -- ***Envia o e-mail
				  ---------------------------------------------------------------------------------------------------------------------------------------------------
				  EXEC msdb.dbo.sp_send_dbmail
						@profile_name = 'CRAVIL' ,	
						@recipients = @Destinatario ,	
						@subject = @Assunto,			
						@body = @Mensagem,				
						@body_format = 'HTML'
										
			END	-- fim do if
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportNotSaleEmployee]:<b> <br>
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