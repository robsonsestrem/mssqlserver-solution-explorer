use Maintenance
go

create or alter procedure Management.sp_AlertPLE
with encryption
as
begin
	set nocount on

	begin try
	begin transaction
	declare  @assuntoEmail      NVARCHAR(70)
		   , @CorpoEmail		NVARCHAR(MAX)
	--
	declare   @contadorDmv bigint
			, @idealCalculado decimal(15,2)
	set @contadorDmv = (select [cntr_value] FROM [sys].[dm_os_performance_counters]
						WHERE [object_name] LIKE '%Manager%'
						AND [counter_name] = 'Page life expectancy')
	set @idealCalculado = (SELECT cast(
										(
											( SELECT COUNT(*) * 8. / 1024. / 1024. AS 'Cached Size (GB)'	FROM [sys].[dm_os_buffer_descriptors] )
											/ 128. * 300.
										)
									   as decimal(15,2))						
						  )

		if(@contadorDmv < @idealCalculado)
			begin
			   -- inserção do histórico
			   INSERT INTO Maintenance.Management.CountPLE
			   SELECT GETDATE() AS [dth_Contador],
			   [object_name] AS [des_Objeto],
			   [counter_name] AS [des_Contador],
			   [cntr_value] AS [val_Contador],
			   @idealCalculado AS [ideal_calculado]
				FROM [sys].[dm_os_performance_counters]
				WHERE [object_name] LIKE '%Manager%'
				AND [counter_name] = 'Page life expectancy'
				
					SET @CorpoEmail = '
											<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
											<tr height=20  style=color:black;>
												<td width=300 style=height:20.0pt><b>Data:</b> '+convert(varchar(30),getdate(),113)+'	
													<br>									
													<br><b>Descrição:</b> O contador de desempenho do SQL Server <b>''Page Life Expectancy''</b> do objeto ''Buffer Manager'' está abaixo do ideal de '+cast(@idealCalculado as varchar(10))+', valor atual é de '+cast(@contadorDmv as varchar(20))+'.
													<br>
													<br><b>Obs.:</b> Esse contador nos diz o tempo em segundos que uma página de memória fica no cache. 
													<br>Quanto maior esse tempo, maior é a chance do SQL Server encontrar a informação que precisa e assim economizar uma busca no disco.								 																			
												</td>
											</tr>
											</table>
											<br><br>																																				
										  '					
					SELECT @CorpoEmail = @CorpoEmail +
					'</tr></table>'+'<br><br>'

					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					-- envia e-mail
					--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					SET @assuntoEmail = 'Server - '+@@SERVERNAME+' - Evidências de Performance no SQL Server (PLE)'
					EXEC msdb.dbo.sp_send_dbmail
											@profile_name =		'CRAVIL',
											@recipients =		'suporte@cravil.com.br;', 						
											@subject =			@assuntoEmail,
											@body =				@CorpoEmail
											,@body_format =		'HTML'			
			  end -- fim do if																	
		commit transaction
		end try
		begin catch
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
					  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_AlertPLE]:<b> <br>
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
		end catch		
		set nocount off
end