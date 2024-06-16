USE Maintenance
GO

--	EXECUTE msdb.dbo.sysmail_configure_sp 'MaxFileSize', '50000000';

CREATE OR ALTER PROCEDURE Management.[sp_ReportBloquedProcess] @ExibirApenasHtml BIT = 0	-- Caso parâmetro for 1, vai me trazer resultado com o script HTML.
WITH ENCRYPTION
AS
BEGIN
		SET NOCOUNT ON;			

		DECLARE @inicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
		DECLARE @fim datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))
		DECLARE @vSubject NVARCHAR(255) = 'Relatório diário - Processos Bloqueados no Sistema'
		DECLARE @vBody AS NVARCHAR(MAX) = '';
		DECLARE	@contaInsert INT = 0
		
			IF OBJECT_ID('tempdb..##ReportBlock') IS NOT NULL
				BEGIN
						drop table ##ReportBlock
				END
			ELSE
				create table ##ReportBlock
				(						
					Segundos varchar(50),
					Evento varchar(50),
					Data_Inicio varchar(23),
					Data_Fim varchar(23),
					BD varchar(50),
					Mode varchar(10),
					LockMode varchar(10),
					WaitResource varchar(100),
					Program_Blocked varchar(100),
					SPID_Blocked varchar(10),
					Host_Blocked varchar(100),
					Login_Blocked varchar(100),
					IsolationLevel_Blocked varchar(100),
					Script_Blocked varchar(max),
					Program_Blocking varchar(100),
					SPID_Blocking varchar(10),
					Host_Blocking varchar(100),
					Login_Blocking varchar(100),
					IsolationLevel_Blocking varchar(100),
					Script_Blocking varchar(max),
				)
				-- inserção dos dados extraídos dos gráficos de bloqueio		
				;WITH cte_BlockedProcess
				 AS   (SELECT IdBlock,
							DateBlock,
							DatabaseName,
							GraphBlock
					   FROM Management.HistoryBlockedProcess
					   WHERE DateBlock between @inicio and @fim
					   )

				INSERT INTO ##ReportBlock
				(
				 Segundos, Evento, Data_Inicio, Data_Fim, BD, Mode, LockMode, WaitResource
				 , Program_Blocked, SPID_Blocked, Host_Blocked, Login_Blocked, IsolationLevel_Blocked, Script_Blocked
				 , Program_Blocking, SPID_Blocking, Host_Blocking, Login_Blocking, IsolationLevel_Blocking, Script_Blocking
				)

				(SELECT 			
						REPLACE((CAST(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Duration)')  AS VARCHAR(60)) AS MONEY)/1000/1000),',','.')  AS Segundos,
						CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EventType)')		AS VARCHAR(50))											AS Evento,
						REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)),'T',' ')								AS Data_Inicio,
						REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EndTime)')	AS VARCHAR(23)),'T',' ')							AS Data_Fim,			
						[A].DatabaseName																											AS BD,
					  CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Mode)')	AS VARCHAR(10))													    AS Mode,				  
					  [BlockedProcess].Process.value('@lockMode', 'varchar(max)')																	AS LockMode,
					  [BlockedProcess].Process.value('@waitresource', 'varchar(max)')																AS Waitresource,
					  [BlockedProcess].Process.value('@clientapp', 'varchar(max)')																	AS Program_Blocked,
					  [BlockedProcess].Process.value('@spid', 'varchar(max)')																		AS SPID_Blocked,
					  [BlockedProcess].Process.value('@hostname', 'varchar(max)')																	AS Host_Blocked,
					  [BlockedProcess].Process.value('@loginname', 'varchar(max)')																	AS Login_Blocked,
					  [BlockedProcess].Process.value('@isolationlevel', 'varchar(max)')																AS IsolationLevel_Blocked,
					  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockedProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
					  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS Script_Blocked,

					  [BlockingProcess].Process.value('@clientapp', 'varchar(max)')																	AS Program_Blocking,
					  [BlockingProcess].Process.value('@spid', 'varchar(max)')																		AS SPID_Blocking,
					  [BlockingProcess].Process.value('@hostname', 'varchar(max)')																	AS Host_Blocking,
					  [BlockingProcess].Process.value('@loginname', 'varchar(max)')																	AS Login_Blocking,
					  [BlockingProcess].Process.value('@isolationlevel', 'varchar(max)')															AS IsolationLevel_Blocking,
					  REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockingProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)
					  ),'<inputbuf>',''),'</inputbuf>','')),CHAR(10),''),CHAR(13),''),CHAR(9),'')													AS Script_Blocking
				   FROM [cte_BlockedProcess] AS [A]
						CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocked-process/process')  AS [BlockedProcess]([Process]) 
						CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocking-process/process') AS [BlockingProcess]([Process])
				   WHERE [BlockedProcess].Process.value('@hostname', 'varchar(max)') NOT IN ('CTI-000492', 'CTI-000370')
				   AND [BlockingProcess].Process.value('@hostname', 'varchar(max)') NOT IN ('CTI-000492', 'CTI-000370')

				 )
				 
		-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- Tratando corpo do e-mail
		-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
					SET @contaInsert = @@ROWCOUNT; -- captura do resultado de inserções

					IF(@contaInsert = 0)
						BEGIN 
							set @vBody = '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
											<tr height=20  style=color:black;>
												<td width=300 style=height:20.0pt>Não houve processos bloqueados.
													<br>Data dos eventos: '+CONVERT(VARCHAR(12),@inicio,105)+'
													<br>Instância: '+@@SERVERNAME+'
													
												</td>
											</tr>
										  </table>
										  <br><br>
										'

							IF @ExibirApenasHtml = 0
								BEGIN
									EXEC msdb.dbo.sp_send_dbmail
									@profile_name =		'CRAVIL',
									@recipients =		'suporte@cravil.com.br', 						
									@subject =			@vSubject,
									@body =				@vBody,
									@body_format =		'HTML'					
									--@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
									-- *** Exibe como HTML ao invés de enviar por e-mail
								END
							ELSE 
							SELECT @vBody;
						END
					ELSE
							BEGIN	-- caso tenha registros monta numa tabela
									SET @vBody = '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
													<tr height=20  style=color:black;>
														<td width=300 style=height:20.0pt>Anexo dados de processos bloqueados disponíveis para análise.
																						<br>Os dados coletados são apenas de bloqueios que duraram mais de 10 segundos.																		
																						<br>Data dos eventos: '+CONVERT(VARCHAR(12),@inicio,105)+'
																						<br>Instância: '+@@SERVERNAME+'
														</td>
													</tr>
													</table>
													<br><br>
												 '
		-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- colocando anexo
		-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
							DECLARE @Query NVARCHAR(max);
							DECLARE @tab char(1) = CHAR(9);
							SET @Query = 
							'SET NOCOUNT ON;	 
							 SELECT 
							 ''Segundos'',''Evento'',''Data_Inicio'',''Data_Fim'',''BD'', ''Mode'', ''LockMode'', ''WaitResource''
							 ,''Program_Blocked'',''SPID_Blocked'',''Host_Blocked'',''Login_Blocked'',''IsolationLevel_Blocked'', ''Script_Blocked''
							 ,''Program_Blocking'',''SPID_Blocking'',''Host_Blocking'',''Login_Blocking'',''IsolationLevel_Blocking'',''Script_Blocking''	 	
	
							 UNION ALL

							 SELECT 
							 Segundos, Evento, Data_Inicio, Data_Fim, BD, Mode, LockMode, WaitResource
							 , Program_Blocked, SPID_Blocked, Host_Blocked, Login_Blocked, IsolationLevel_Blocked, Script_Blocked
							 , Program_Blocking, SPID_Blocking, Host_Blocking, Login_Blocking, IsolationLevel_Blocking, Script_Blocking
							 FROM ##ReportBlock
							'
		-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		-- *** Envia e-mail
		-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
								IF @ExibirApenasHtml = 0
									EXEC msdb.dbo.sp_send_dbmail
											@profile_name =		'CRAVIL',
											@recipients =		'suporte@cravil.com.br', 								
											@subject =			@vSubject,
											@body =				@vBody,
											@body_format =		'HTML',

											@query	= @Query,
											@attach_query_result_as_file = 1
											,@query_attachment_filename ='ProcessosBloqueados.csv'
											,@query_result_header = 0		-- 0 fica sem coluna
											,@query_result_separator= @tab	-- enforce csv
											,@query_result_no_padding= 1	-- trim
											,@query_result_width = 32767	-- stop wordwrap
											--,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
								-- *** Exibe como HTML ao invés de enviar por e-mail
								ELSE 
								SELECT @vBody;
		
						IF OBJECT_ID('tempdb..##ReportBlock') IS NOT NULL
							BEGIN
								drop table ##ReportBlock
							END		
				END	
	SET NOCOUNT OFF;
END

GO


