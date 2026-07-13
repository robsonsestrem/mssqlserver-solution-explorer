USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_ReportDeadLock] @ExibirApenasHtml BIT = 0
WITH ENCRYPTION
AS
BEGIN
		SET NOCOUNT ON;
		SET LANGUAGE 'portuguese'; -- feito para formata��o da data
		DECLARE @inicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
		DECLARE @fim datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))
		DECLARE @vSubject NVARCHAR(255) = 'Relat�rio Di�rio - DeadLocks no Sistema'
		DECLARE @vBody AS NVARCHAR(MAX) = '';
		DECLARE	@contaInsert INT = 0
		
				IF OBJECT_ID('tempdb..##ReportDeadlock') IS NOT NULL
					BEGIN
						drop table ##ReportDeadlock
					END
				ELSE
					create table ##ReportDeadlock
					(						
						IdDeadLock varchar(10),
						[Victim] varchar(2),	
						[LockMode] varchar(10),
						[LockedObject] varchar(200),
						DatabaseName varchar(50),
						[AssociatedObjectId] varchar(MAX),
						[LockProcess] varchar(200),
						[KPID] varchar(10),
						[SPID] varchar(10),
						[SBID] varchar(10),
						[ECID] varchar(10),
						[TranCount] varchar(10),
						[LockEvent] varchar(50),
						[LockedMode] varchar(10),
						[WaitProcessID] varchar(50),
						[WaitMode] varchar(10),
						[WaitResource] varchar(100),
						[WaitType] varchar(100),
						[IsolationLevel] varchar(100),
						[LogUsed] varchar(50),
						[ClientApp] varchar(100),
						[HostName] varchar(60),
						[LoginName] varchar(60),
						[TransactionTime] varchar(30),
						[BatchStarted] varchar(30),
						[BatchCompleted] varchar(30),
						[InputBuffer] varchar(MAX)
					)

					-- inser��o dos dados extra�dos dos gr�ficos de bloqueio		
					;WITH cte_DeadLock
					 AS (SELECT IdDeadLock, 
								DateDeadLock,              
								DatabaseName,
								GraphDeadLock
						   FROM Management.HistoryDeadLock
						   WHERE DateDeadLock between @inicio and @fim
						   ),
					 Victims
					 AS (SELECT [ID] = [Victims].[List].value('@id', 'varchar(50)')
						   FROM [cte_DeadLock]
								CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/victim-list/victimProcess') AS [Victims]([List])),
					 Locks
					 AS (SELECT [cte_DeadLock].IdDeadLock,				
								[MainLock].[Process].value('@id', 'varchar(100)')									AS [LockID],
								[OwnerList].[Owner].value('@id', 'varchar(200)')									AS [LockProcessId],
								REPLACE([MainLock].[Process].value('local-name(.)', 'varchar(100)'), 'lock', '')	AS [LockEvent],
								[MainLock].[Process].value('@objectname', 'sysname')								AS [ObjectName],
								[OwnerList].[Owner].value('@mode', 'varchar(10)')									AS [LockMode],
								--[MainLock].[Process].value('@dbid', 'INTEGER') AS [Database_id],
								[cte_DeadLock].DatabaseName															AS DatabaseName,
								[MainLock].[Process].value('@associatedObjectId', 'BIGINT')							AS [AssociatedObjectId],				
								[MainLock].[Process].value('@WaitType', 'varchar(100)')								AS [WaitType],
								[WaiterList].[Owner].value('@id', 'varchar(200)')									AS [WaitProcessId],
								[WaiterList].[Owner].value('@mode', 'varchar(10)')									AS [WaitMode]
						   FROM [cte_DeadLock]
								CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/resource-list') AS [Locks]([list]) 
								CROSS APPLY [Locks].[List].[nodes]('*') AS [MainLock]([Process]) 
								CROSS APPLY [MainLock].[Process].[nodes]('owner-list/owner') AS [OwnerList]([Owner]) 
								CROSS APPLY [MainLock].[Process].[nodes]('waiter-list/waiter') AS [WaiterList]([Owner])),
					 Process
					 AS (SELECT [cte_DeadLock].IdDeadLock,				
								[Victim] = CONVERT( BIT,
													CASE
														WHEN [Deadlock].[Process].value('@id', 'varchar(50)') = ISNULL([Deadlock].[Process].value('../../@victim', 'varchar(50)'), [v].[ID])
														THEN 1
														ELSE 0
													END),				
								[LockMode] = [Deadlock].[Process].value('@lockMode', 'varchar(10)'),
								[ProcessID] = [Process].[ID],
								[KPID] = [Deadlock].[Process].value('@kpid', 'int'),
								[SPID] = [Deadlock].[Process].value('@spid', 'int'),
								[SBID] = [Deadlock].[Process].value('@sbid', 'int'),
								[ECID] = [Deadlock].[Process].value('@ecid', 'int'),
								[IsolationLevel] = [Deadlock].[Process].value('@isolationlevel', 'varchar(200)'),
								[WaitResource] = [Deadlock].[Process].value('@waitresource', 'varchar(200)'),
								[LogUsed] = [Deadlock].[Process].value('@logused', 'int'),
								[ClientApp] = [Deadlock].[Process].value('@clientapp', 'varchar(100)'),
								[HostName] = [Deadlock].[Process].value('@hostname', 'varchar(20)'),
								[LoginName] = [Deadlock].[Process].value('@loginname', 'varchar(20)'),
								[TransactionTime] = CAST([Deadlock].[Process].value('@lasttranstarted', 'datetime') AS DATETIME), -- necess�rio convers�o expl�cita para n�o truncar na formata��o de data
								[BatchStarted] =	CAST([Deadlock].[Process].value('@lastbatchstarted', 'datetime') AS DATETIME),
								[BatchCompleted] =	CAST([Deadlock].[Process].value('@lastbatchcompleted', 'datetime') AS DATETIME),
								[InputBuffer] = [Input].[Buffer].[query]('.'),
								[cte_DeadLock].GraphDeadLock,
								[QueryStatement] = [Execution].[Frame].value('.', 'varchar(max)'),
								[TranCount] = [Deadlock].[Process].value('@trancount', 'int')
						   FROM [cte_DeadLock]
								CROSS APPLY [cte_DeadLock].GraphDeadLock.[nodes]('//deadlock/process-list/process') AS [Deadlock]([Process]) 
								CROSS APPLY (SELECT [Deadlock].[Process].value('@id', 'varchar(50)')) AS [Process]([ID]) LEFT JOIN [Victims] AS [v] ON [Process].[ID] = [v].[ID]
								CROSS APPLY [Deadlock].[Process].[nodes]('inputbuf') AS [Input]([Buffer]) 
								CROSS APPLY [Deadlock].[Process].[nodes]('executionStack') AS [Execution]([Frame]))

					 INSERT INTO ##ReportDeadlock	
	  
					 SELECT [p].IdDeadLock,
							[p].[Victim],			
							ISNULL([p].[LockMode],'')			AS [LockMode],
							ISNULL([l].[ObjectName], '')		AS [LockedObject],          
							[l].DatabaseName,
							ISNULL([l].[AssociatedObjectId],'') AS [AssociatedObjectId],
							[p].[ProcessID]						AS [LockProcess],
							[p].[KPID],
							[p].[SPID],
							[p].[SBID],
							[p].[ECID],
							[p].[TranCount],
							[l].[LockEvent],
							ISNULL([l].[LockMode],'')			AS [LockedMode],
							[l].[WaitProcessID],
							ISNULL([l].[WaitMode],'')			AS [WaitMode],
							ISNULL([p].[WaitResource],'')		AS [WaitResource],
							ISNULL([l].[WaitType],'')			AS [WaitType],
							ISNULL([p].[IsolationLevel],'')		AS [IsolationLevel],
							ISNULL([p].[LogUsed],'')			AS [LogUsed],
							ISNULL([p].[ClientApp],'')			AS [ClientApp],
							ISNULL([p].[HostName],'')			AS [HostName],
							ISNULL([p].[LoginName],'')			AS [LoginName],
							CONVERT(VARCHAR(30),ISNULL([p].[TransactionTime],''),113)	AS [TransactionTime],
							CONVERT(VARCHAR(30),[p].[BatchStarted],113)					AS [BatchStarted],
							CONVERT(VARCHAR(30),[p].[BatchCompleted],113)				AS [BatchCompleted],
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(CAST([p].[InputBuffer] AS VARCHAR(MAX)),'<inputbuf/>',''),'<inputbuf>',''),CHAR(9),''),CHAR(10),''),CHAR(13),'') AS [InputBuffer]
					   FROM [Locks] AS [l]
							INNER JOIN [Process] AS [p] ON [p].[ProcessID] = [l].[LockProcessID]
					  ORDER BY [p].[IdDeadLock] ASC,				 
							   [p].[Victim] DESC,
							   [p].[ProcessId]
	  
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Tratando corpo do e-mail
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
						set @vBody = '
						<html>
							<head></head>
							<body>
							<div align=left>
						'	
						SET @contaInsert = @@ROWCOUNT; -- captura do resultado de inser��es
						IF(@contaInsert = 0)
							BEGIN 
								set @vBody = @vBody + '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
												<tr height=20  style=color:black;>
													<td width=300 style=height:20.0pt>N�o houve registros de DeadLock.
														<br>Data dos eventos: '+CONVERT(VARCHAR(12),@inicio,105)+'
														<br>Inst�ncia: '+@@SERVERNAME+'
													</td>
												</tr>
												
											 </table>											  											 																				  
											'				
								IF @ExibirApenasHtml = 0
									EXEC msdb.dbo.sp_send_dbmail
											@profile_name =		'CRAVIL',
											@recipients =		'suporte@cravil.com.br', 						
											@subject =			@vSubject,
											@body =				@vBody,
											@body_format =		'HTML'							
											--@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
											
											
								-- *** Exibe como HTML ao inv�s de enviar por e-mail
								ELSE 
								SELECT @vBody;
							END
						ELSE	-- caso tenha registros monta numa tabela
						BEGIN
							SET @vBody = @vBody + '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
												   <tr height=20  style=color:black;>
														<td width=300 style=height:20.0pt>Anexo dados de processos que sofreram DeadLock dispon�veis para an�lise.
															<br>Data dos eventos: '+CONVERT(VARCHAR(12),@inicio,105)+'
															<br>Inst�ncia: '+@@SERVERNAME+'
														</td>
													</tr>											
												   '

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Finaliza HTML
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
			set @vBody = @vBody +  '									
									</div>																		
								</body>								
							</html>'

			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- colocando anexo
			-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					DECLARE @Query NVARCHAR(max);
					DECLARE @tab char(1) = CHAR(9);
					SET @Query = 
					'SET NOCOUNT ON;	 
					 SELECT 
					 ''IdDeadLock'',
						''Victim'',
						''LockMode'',
						''LockedObject'',
						''DatabaseName'',
						''AssociatedObjectId'',
						''LockProcess'',
						''KPID'' ,
						''SPID'' ,
						''SBID'' ,
						''ECID'' ,
						''TranCount'',
						''LockEvent'',
						''LockedMode'',
						''WaitProcessID'',
						''WaitMode'',
						''WaitResource'',
						''WaitType'',
						''IsolationLevel'',
						''LogUsed'',
						''ClientApp'',
						''HostName'',
						''LoginName'',
						''TransactionTime'',
						''BatchStarted'',
						''BatchCompleted'',
						''InputBuffer'' 	
	
					 UNION ALL

					 SELECT 
					 *
					 FROM ##ReportDeadlock
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
									,@query_attachment_filename ='DeadLock.csv'
									,@query_result_header = 0		-- 0 fica sem coluna
									,@query_result_separator= @tab	-- enforce csv
									,@query_result_no_padding= 1	-- trim
									,@query_result_width = 32767	-- stop wordwrap
									--,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'
						-- *** Exibe como HTML ao inv�s de enviar por e-mail
						ELSE 
						SELECT @vBody;
					
					END
						IF OBJECT_ID('tempdb..##ReportDeadlock') IS NOT NULL
							BEGIN
								drop table ##ReportDeadlock
							END			
END

GO


