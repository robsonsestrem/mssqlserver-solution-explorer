USE [IntegraTICravil]
GO

ALTER PROCEDURE Bi.[sp_HistoryCMV]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET LANGUAGE 'portuguese'; -- feito para formatação da data
	DECLARE @datainicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
	DECLARE @datafinal datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))			 

	DECLARE @resultSet		   INT
		   ,@totalVendas	   VARCHAR(20)
		   ,@totalCusto		   VARCHAR(20)
		   ,@totalCupons	   VARCHAR(20)
		   ,@assuntoEmail      NVARCHAR(50)
		   ,@CorpoEmail		   NVARCHAR(MAX)
		   ,@incrementoHtml	   INT = 1
	
	BEGIN TRY
		BEGIN TRANSACTION 
			SET @resultSet = (
							  SELECT count(v.CupCodigo)	FROM GesCooper90.dbo.VENDASECF as v 
							  WHERE v.CupDatMov between @datainicio and @datafinal 
							  and v.CupSituac = 1						-- trazer os não cancelados
							  and v.CupSitIntegracao = 0				-- trazer os não integrados
							  and (v.CupGNF is null or v.CupGNF = 0)	-- Trazer apenas tipo fiscal, não fiscal sempre traz um valor válido					 												
							 )
			SET @totalVendas = (SELECT CAST(ISNULL(IntegraTICravil.Management.fn_FormatIntToMoney( IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 1) ), 0) AS VARCHAR(20)))

			IF(@resultSet > 0)
				BEGIN		
						SET @totalCupons = (SELECT CAST(ISNULL(IntegraTICravil.Management.fn_FormatIntToMoney( IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 3) ), 0) AS VARCHAR(20)))						
						SET @CorpoEmail = '
											<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
											<tr height=20  style=color:black;>
												<td width=300 style=height:20.0pt>Não foi possível realizar carga no histórico de custo para Receitas.
													<br>Data de movimento: '+convert(varchar(12),@datainicio,105)+'										
													<br>Motivo: Vendas não integradas para o comercial
													<br>Valor total não integrado: R$'+@totalCupons+' 
													<br>Segue abaixo lista destes documentos: 								
												</td>
											</tr>
											</table>
											<br><br>
																
											<TABLE border=0 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:900pt;font-family:Arial;font-size:14px>															
											<tr height=20  style=height:20.0pt align = center>
												<td bgcolor=#0B0B61 width=200> <font color=white>Filial </td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Cupom  </td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Data   </td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Caixa  </td>
												<td bgcolor=#0B0B61 width=200> <font color=white>Cliente</td>
											</tr>
										  ';
			
							SELECT  @CorpoEmail = @CorpoEmail + 
								   CASE
									  WHEN CAST(ROW_NUMBER() OVER(ORDER BY v.CupCodigo ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt align = center>'
									  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align = center>'
								   END +
								   '<td height=20 style=height:15.0pt>' + CAST(v.FilCod AS CHAR(2))				+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + CAST(v.CupCodigo AS VARCHAR(50))		+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + CONVERT(VARCHAR(12),v.CupDatMov,105)	+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + CAST(v.CaiCod AS CHAR(2))				+ '</td>' + 
								   '<td height=20 style=height:15.0pt>' +	CAST(v.CupCliCod AS VARCHAR(20))		+ '</td>' +					   
								   '</tr>'
							  FROM GesCooper90.dbo.VENDASECF as v 
							  WHERE v.CupDatMov between @datainicio and @datafinal 
								and v.CupSituac = 1						-- trazer os não cancelados
								and v.CupSitIntegracao = 0				-- trazer os não integrados
								and (v.CupGNF is null or v.CupGNF = 0)	-- Trazer apenas tipo fiscal					
							  Order by v.CupCodigo

							SELECT @CorpoEmail = @CorpoEmail + 
							 '</table>'+'<br><br>'
				END
			IF(@resultSet = 0)
				BEGIN
							INSERT INTO IntegraTICravil.Bi.HistoricoCMV(  DataIntegracao, CodigoFilial, DataEmissao, NumeroControle, NumeroNFe, Operacao
																		, CodigoProduto, SequenciaItemNota, Codigofamilia, CodigoGrupo, CodigoSubgrupo
																		, CustoMercadoriaVendida, Setor, Secao, CentroCusto, Quantidade, Margem, Peso, Estoque, CustoTotal )
							(
								SELECT GETDATE(), x.Filial, x.Emissao, x.NumControle,x.NF,x.Op, x.Item
									, x.SequenciaItem, x.CodFamilia, x.CodGrupo, x.CodSubgrupo
									, cmv.CustoMedioUnitario, x.Setor, x.Secao, x.CentroCusto
									, x.Qtdade, x.Margem, x.Peso, cmv.Estoque, cmv.CustoTotal
								FROM GesCooper90.dbo.vw_MovimentacaoReceita AS x WITH(NOLOCK)
								CROSS APPLY
								GesCooper90.dbo.GetCustoMercadoria(x.Filial, x.Item, x.Emissao) AS cmv 
								WHERE x.Emissao between @datainicio and @datafinal
							)						
					SET @totalCusto = (SELECT CAST(ISNULL(IntegraTICravil.Management.fn_FormatIntToMoney( IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 2) ), 0) AS VARCHAR(20)))
				      				             			                        	   	   	 											
					SET @CorpoEmail = '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
													<tr height=20  style=color:black;>
														<td width=300 style=height:20.0pt>Integração de hoje das Receitas com CMV realizada com sucesso.
															<br>
															<br>Data de movimento: '+convert(varchar(12),@datainicio,105)+'
															<br>
															<br>Total das vendas: R$ '+@totalVendas+'
															<br>
															<br>Total de CMV: R$ '+@totalCusto+'								
														</td>
													</tr>
													</table>
													<br><br>
							  '		
				 END -- fim da segunda condicional if
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- envia e-mail
			--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			SET @assuntoEmail = 'Carga para Guru Sistemas - Histórico de CMV'
			EXEC msdb.dbo.sp_send_dbmail
									@profile_name =		'CRAVIL',
									@recipients =		'suporte@cravil.com.br;marcon@cravil.com.br;adriana@cravil.com.br', 						
									@subject =			@assuntoEmail,
									@body =				@CorpoEmail
									,@body_format =		'HTML'						
									,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_HistoryCMV]:<b> <br>
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
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END -- fim procedure

GO


