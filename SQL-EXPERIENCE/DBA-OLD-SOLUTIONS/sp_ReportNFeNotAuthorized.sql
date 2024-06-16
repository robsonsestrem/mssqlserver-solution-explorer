USE [IntegraTICravil]
GO

CREATE OR ALTER PROCEDURE Erp.[sp_ReportNFeNotAuthorized] 

@ExibirApenasHtml BIT = 0

WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			IF OBJECT_ID('tempdb..#naoAutorizadas') IS NOT NULL
					DROP TABLE #naoAutorizadas;

			create table #naoAutorizadas
			(
				Id int identity(1,1),
				Filial smallint,
				DataHora varchar(30),
				NFe int,
				NumeroNfe int,
				Operacao smallint,
				Situcao varchar(30),
				Chave char(44),
				Status smallint,
				Tipo char(3)
			)
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	
					--*** SETANDO SEMPRE O DIA ANTERIOR AO DA JOB ***--
			DECLARE @inicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
			DECLARE @fim datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))

			DECLARE @vSubject NVARCHAR(255) = 'RELATÓRIO DE NF-e NÃO AUTORIZADAS PELO SEFAZ'

			DECLARE @vBody AS NVARCHAR(MAX) = '';
			DECLARE
					@contaInsert INT = 0,
					@Loop INT = 1;	
	
				INSERT INTO #naoAutorizadas
				select 
						m.NfFilCod as Filial,
						convert(varchar,m.NfDatEmis, 105) + ' - ' + m.NfHorEntSaid as DataHora,			
						m.NfNumDoc as NFe,
						m.NfNumero as Número,
						m.NfOpeEstCod as OP,
						case m.NfSituacao
							when 1 then 'Digitada'
							when 2 then 'Atualizado'
							when 3 then 'NFListada'
							when 4 then 'Cancelado'
							when 5 then 'O.C.Listada'
							when 6 then 'Ordem Atendida'
							when 7 then 'Ordem Atualizada'
							when 8 then 'NF-e à Cancelar'
							when 9 then 'Ag. Conferência'
							when 10 then 'Aguardando Armazenagem'
							when 11 then 'Aguardando Autorização'
							when 12 then 'Aguardando Liberação'
							when 13 then 'Aguardando Processamento'
						else 'Indefinida'
						end as Situação,		
						case 
							when m.NfeChNfe = '' then 'Não Gerada'
							else isnull(m.NfeChNfe,'Não Gerada')			
						END AS Chave,
						ISNULL(cast(m.NfeCStat as varchar(10)), 'Sem Status') as Status,
						m.NfTipDoc as Tipo
									
				from GesCooper90.dbo.MOVESTOQUE AS m with(nolock) 
				inner join GesCooper90.dbo.OPERACAO as p
				on p.OpeEstCod = m.NfOpeEstCod

				where  m.NfDatEmis between @inicio and @fim	
				-- nega as canceladas/inutilizadas, usu denegado ou autorizadas 					
				and m.NfeCStat not in (100, 101, 102, 302)	
				-- traz só aquelas que contém nº de NFE	conforme a situação.
				and 
				( (m.NfTipDoc = 'nfe' and m.NfSituacao not in(10,11,12,13)) or (m.NfTipDoc <> 'nfe' and m.NfSituacao in (10,11,12,13)) )
												   
				and p.OpeDocCod = 1		-- só operações de nota eletrônica que precisa autorização	
			-------------------------------------------------------------------------------------------------------------------------------------------------------------	
				SET @contaInsert = @@ROWCOUNT; -- captura do resultado de inserções

				IF(@contaInsert = 0)
					BEGIN 
						set @vBody = '<br>
								  <h3><font color=black bold=true size= 5> Todas NF-e do dia '+ convert(varchar(20), @inicio, 103) +' foram devidamente autorizadas. </font><td align=center> </h3>'
					END
				ELSE	-- caso tenha registros monta numa tabela
					SET @vBody = 																 -- Abre tabela - Nome das colunas (HTML)
						'
							<h3><font color=black bold=true size= 4> Relação de NF-e não autorizadas </font><td align=center> </h3>
								<table cellpadding=2 cellspacing=1 border=3 align=center>
									<tr>
										<th bgcolor=#0B0B61 width=200> <font color=white> Filial </font></th>										     
										<th bgcolor=#0B0B61 width=200> <font color=white> DataHora </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> NF-e </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> Numero </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> OP </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> Situação </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> Chave </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> Status </font></th>
										<th bgcolor=#0B0B61 width=200> <font color=white> Tipo </font></th>
									</tr>';

					WHILE (@Loop <= @contaInsert)
						BEGIN
							SET @vBody = @vBody +
							(
								SELECT
									'<tr>'+
									'<td>'+CONVERT(VARCHAR(3),n.Filial)+'</td>'+
									'<td>'+n.DataHora+'</td>'+						 -- inserção de dados a partir da 2ª linha (HTML)
									'<td>'+CONVERT(VARCHAR(10),n.NFe)+'</td>'+
									'<td>'+CONVERT(VARCHAR(10),n.NumeroNfe)+'</td>'+
									'<td>'+CONVERT(VARCHAR(3),n.Operacao)+'</td>'+
									'<td>'+n.Situcao+'</td>'+
									'<td>'+n.Chave+'</td>'+
									'<td>'+CONVERT(VARCHAR(3),Status)+'</td>'+
									'<td>'+n.Tipo+'</td>'+
									'</tr>'
								FROM #naoAutorizadas as n
								where n.Id = @Loop
							);
							SET @Loop = @Loop +1;	
						END;

					SET @vBody = @vBody + '</table><br>';													 -- Fecha 2ª tabela (HTML)			

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

				--*** Envia e-mail
				if @ExibirApenasHtml = 0
					exec msdb.dbo.sp_send_dbmail
							@profile_name =		'CRAVIL',
							@recipients =		'setorcontabil@cravil.com.br;suporte@cravil.com.br', 
							@subject =			@vSubject,
							@body =				@vBody,
							@body_format =		'HTML'
							--@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png';
				-- *** Exibe como HTML ao invés de enviar por e-mail
				else 
				SELECT @vBody;

				-- limpa dados temporários
			IF OBJECT_ID('tempdb..#naoAutorizadas') IS NOT NULL
					DROP TABLE #naoAutorizadas;

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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportNFeNotAuthorized]:<b> <br>
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
GO


