USE [IntegraTICravil]
GO

create or alter PROCEDURE Bi.[sp_HistoryCMVTransferencia]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET LANGUAGE 'portuguese'; -- feito para formatação da data
	DECLARE @datainicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
	DECLARE @datafinal datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))			 

	DECLARE
		    @totalOperacoes	   VARCHAR(20)
		   ,@totalCusto		   VARCHAR(20)	
		   ,@resultSetHistory  INT
		   ,@assuntoEmail      NVARCHAR(50)
		   ,@CorpoEmail		   NVARCHAR(MAX)
		   ,@incrementoHtml	   INT = 1
	
	BEGIN TRY
		BEGIN TRANSACTION 			
				set @resultSetHistory = (select COUNT(*) from IntegraTICravil.Bi.HistoricoCMVTransf as t1
											 where t1.DataEmissao >= @datainicio) -- data de movimento		
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				-- Condicional para não enviar e-mail, pois a carga foi realizada com sucesso
				--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				IF(@resultSetHistory > 0)			
				BEGIN
					print 'INTEGRAÇÃO JÁ FOI REALIZADA COM SUCESSO!'
				END
				ELSE
					BEGIN
						SET @totalOperacoes = (SELECT CAST(ISNULL(IntegraTICravil.Erp.fn_FormatIntToMoney( IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 4) ), 0) AS VARCHAR(20)))
										
										INSERT INTO IntegraTICravil.Bi.HistoricoCMVTransf(  DataIntegracao, CodigoFilial, DataEmissao, NumeroControle, NumeroNFe, Operacao
																					, CodigoProduto, SequenciaItemNota, Codigofamilia, CodigoGrupo, CodigoSubgrupo
																					, CustoMercadoriaVendida, Setor, Secao, CentroCusto, Quantidade, Margem, Peso, Estoque, CustoTotal )
										(
											SELECT GETDATE(), x.Filial, x.Emissao, x.NumControle,x.NF,x.Op, x.Item
												, x.SequenciaItem, x.CodFamilia, x.CodGrupo, x.CodSubgrupo
												, cmv.CustoMedioUnitario, x.Setor, x.Secao, x.CentroCusto
												, x.Qtdade, x.Margem, x.Peso, cmv.Estoque, cmv.CustoTotal
											FROM GesCooper90.dbo.vw_MovimentacaoTransferencia AS x WITH(NOLOCK)
											CROSS APPLY
											GesCooper90.dbo.GetCustoMercadoria(x.Filial, x.Item, x.Emissao) AS cmv 
											WHERE x.Emissao between @datainicio and @datafinal
										)						
								SET @totalCusto = (SELECT CAST(ISNULL(IntegraTICravil.Erp.fn_FormatIntToMoney( IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 5) ), 0) AS VARCHAR(20)))
				      				             			                        	   	   	 											
								SET @CorpoEmail = '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
																<tr height=20  style=color:black;>
																	<td width=300 style=height:20.0pt>Integração de hoje para Histórico das Transferências com CMV realizada com sucesso.
																		<br>
																		<br>Data de Movimento: '+convert(varchar(12),@datainicio,105)+'
																		<br>
																		<br>Total das Operações: R$ '+@totalOperacoes+'
																		<br>
																		<br>Total de CMV: R$ '+@totalCusto+'								
																	</td>
																</tr>
																</table>
																<br><br>
										  '		
			
						--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						-- envia e-mail
						--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
						SET @assuntoEmail = 'Carga para Guru Sistemas - Histórico de CMV'
						EXEC msdb.dbo.sp_send_dbmail
												@profile_name =		'CRAVIL',
												@recipients =		'suporte@cravil.com.br;andrey@cravil.com.br', 						
												@subject =			@assuntoEmail,
												@body =				@CorpoEmail
												,@body_format =		'HTML'						
											--,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
					END

		COMMIT TRANSACTION		
	END TRY		
		BEGIN CATCH
			ROLLBACK TRANSACTION
			DECLARE @corpoFalha varchar(max)
				  , @subject VARCHAR(100)			-- assunto
				  , @recipients VARCHAR(100);		-- destinatário				
			SET @subject = 'Falha na execução de Procedure: '+@@SERVERNAME;
			SET @recipients = 'suporte@cravil.com.br;andrey@cravil.com.br';
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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_CMVTransferencia]:<b> <br>
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


