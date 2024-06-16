USE Maintenance
GO

CREATE OR ALTER PROCEDURE Management.sp_ReportCheckListTaskSQL
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @subject VARCHAR(100)			-- assunto
			, @recipients VARCHAR(100);				-- destinatário
			DECLARE @des_MensagemHTML VARCHAR(max);	-- corpo e-mail
			/**************************************************************************************************************/
			/* Início do HTML                                                                                             */

			Set @des_MensagemHTML = '	
			<html>
			<head>
			<meta http-equiv=Content-Type content=text/html; charset=windows-1252>
			</head>

			<body>
			<div align=center>'

			-- TÍTULO
                                                                                  
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>CheckList Diário Task SQL Server - ' + CONVERT(VARCHAR(50), GETDATE(), 103) + '<b></td>
			 </tr>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Informações de Rotinas e Segurança: ' + @@SERVERNAME + '<b></td>
			 </tr>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt></td>
			 </tr>
			</table> '


			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Backups
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Status dos Backups
			  </td> </tr> </table> '

			set @des_MensagemHTML = @des_MensagemHTML + 
			'
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 align = left style=height:15.0pt; background: #FFFF00;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta amarelo indica ausência de Backup(s) conforme definbido em Jobs.
			</td> </tr> </table>
			'

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=200 style=height:20.0pt>Status</td>
			<td width=350 style=height:20.0pt;>Banco de Dados</td>
			<td width=200 style=height:20.0pt;>Tipo Backup</td>
			<td width=200 style=height:20.0pt;>Data Inicio</td>
			<td width=200 style=height:20.0pt;>Data Final</td>
			<td width=150 style=height:20.0pt;>Recovery Model</td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'
			DECLARE @bkp table
			(
			status			varchar(60),
			banco			varchar(60),
			tipoBkp			varchar(60),
			dataInicio		varchar(60),
			dataFinal		varchar(60),
			type			varchar(60),
			backup_finish_date varchar(60),
			recovery_model varchar(60)
			)

			;WITH cte_BackupSets
					 AS (
						 SELECT MAX(isnull([A].[backup_set_id],'')) AS [backup_set_id],
								isnull([A].[type],'') AS [type],
								isnull(UPPER(CONVERT( VARCHAR(100), [B].[name])) ,'') AS [database_name],
								MAX(isnull([A].[backup_start_date],'')) AS [backup_start_date],
								MAX(isnull([A].[backup_finish_date],'')) AS [backup_finish_date],
								isnull(b.recovery_model_desc, '') AS recovery_model
						   FROM [master].[sys].[databases] AS [B]
								LEFT JOIN [msdb].[dbo].[backupset] AS [A] ON [A].[database_name] = [B].[name]
																			 AND [A].[type] IN('D', 'I')
						  GROUP BY [B].[name],
								   [A].[type],
									b.recovery_model_desc

						 UNION

						 SELECT MAX(isnull([A].[backup_set_id],'')) AS [backup_set_id],
								isnull([A].[type],'') AS [type],
								isnull(UPPER(CONVERT( VARCHAR(100), [B].[name])),'') AS [database_name],
								MAX(isnull([A].[backup_start_date],'')) AS [backup_start_date],
								MAX(isnull([A].[backup_finish_date],'')) AS [backup_finish_date],
								isnull(B.recovery_model_desc, '') AS recovery_model
						   FROM [master].[sys].[databases] AS [B]
								LEFT JOIN [msdb].[dbo].[backupset] AS [A] ON [A].[database_name] = [B].[name]
																			 AND [A].[type] IN('L')
						  GROUP BY [B].[name],
								   [A].[type],
									B.recovery_model_desc),
					 cte_BackupFull
					 AS (SELECT MAX(isnull([backup_set_id],'')) AS [backup_set_id],
								isnull([type],'') AS [type],
								isnull([database_name],'') AS [database_name],
								MAX(isnull([backup_start_date],'')) AS [backup_start_date],
								MAX(isnull([backup_finish_date],'')) AS [backup_finish_date],
								recovery_model
						   FROM [cte_BackupSets]
						  GROUP BY [database_name],
								   [type],
								   recovery_model	)

				INSERT INTO @bkp
					 SELECT					
							IsNull(Cast(CASE
								WHEN [A].[type] = 'D' AND CAST(DATEDIFF(day, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name NOT LIKE '%homolog%' THEN 'WARNING'
								WHEN [A].[type] = 'D' AND CAST(DATEDIFF(day, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name LIKE '%homolog%'	  THEN 'DESNECESSÁRIO'
								--
								WHEN ([A].[type] = 'I') 
								AND 
								(	
									(DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) >= 2 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) <> 6) 
									 OR (DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) > 3 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) = 6)	
								) AND A.database_name NOT LIKE '%homolog%' 
								THEN 'WARNING'
								--
								WHEN ([A].[type] = 'I') 
								AND 
								(	
									(DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) >= 2 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) <> 6) 
									 OR (DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) > 3 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) = 6)	
								) AND A.database_name LIKE '%homolog%' 
								THEN 'DESNECESSÁRIO'
								--						
								WHEN [A].[type] = 'L' AND CAST(DATEDIFF(hour, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 and A.database_name LIKE '%homolog%' THEN 'DESNECESSÁRIO'
								WHEN [A].[type] = 'L' AND CAST(DATEDIFF(hour, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name NOT LIKE '%homolog%' 
													  and A.recovery_model <> 'SIMPLE' THEN 'WARNING'
								WHEN [A].[type] = 'L' AND CAST(DATEDIFF(hour, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name NOT LIKE '%homolog%' 
													  and A.recovery_model = 'SIMPLE' THEN 'DESNECESSÁRIO'
								--
								WHEN ([A].[type] IS NULL OR A.type = '') AND A.recovery_model = 'SIMPLE' THEN 'DESNECESSÁRIO'
								WHEN ([A].[type] IS NULL OR A.type = '') AND A.recovery_model <> 'SIMPLE' AND A.database_name LIKE '%homolog%' THEN 'DESNECESSÁRIO'
								WHEN ([A].[type] IS NULL OR A.type = '') AND A.recovery_model <> 'SIMPLE' AND A.database_name NOT LIKE '%homolog%' THEN 'WARNING'
								ELSE 'Ok'
							END as varchar(max)), '')	as Status,																											
							--
							UPPER(cast(isnull([A].[database_name],'') as varchar(100))) AS Banco,
							--
							IsNull(Cast(CASE [A].[type]
								WHEN 'D' THEN 'Full'
								WHEN 'I' THEN 'Differential'
								WHEN 'L' THEN 'Log'
								WHEN 'F' THEN 'File or Filegroup'
								WHEN 'G' THEN 'File Differential'
								WHEN 'P' THEN 'Partial'
								WHEN 'Q' THEN 'Partial Differential'
								ELSE 'Sem Backup'
							END as varchar(max)), '')	as TipoBkp,																												
							--																																	
							IsNull(Cast(ISNULL(CONVERT( VARCHAR(50), [A].[backup_start_date]), '') as varchar(max)), '')	as dataInicio,	
							IsNull(Cast(ISNULL(CONVERT( VARCHAR(50), [A].[backup_finish_date]), '') as varchar(max)), '')	as dataFinal,
							isnull(A.type,'')  AS type,
							isnull(A.backup_finish_date,'') AS backup_finish_date,
							recovery_model
			   
					   FROM [cte_BackupFull] AS [A]
					   where A.database_name not in ('master', 'tempdb', 'model', 'msdb')

					  ORDER BY [A].[database_name],
							   [type];

					  SELECT @des_MensagemHTML = @des_MensagemHTML + 
							CASE
								WHEN b.status = 'WARNING'  THEN '<tr height=20 style=height:15.0pt;background: #FFFF00>'						 
								ELSE  CASE
									  WHEN CAST(ROW_NUMBER() OVER(ORDER BY b.banco, [type] ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
									  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
									 END 
							 END +	
						'<td height=20 style=height:15.0pt>' + b.status			+ '</td>' +

						'<td height=20 style=height:15.0pt>' + b.banco			+ '</td>' +

						'<td height=20 style=height:15.0pt>' + b.tipoBkp			+ '</td>' +

						'<td height=20 style=height:15.0pt>' + b.dataInicio		+ '</td>' +

						'<td height=20 style=height:15.0pt>' + b.dataFinal		+ '</td>' +

						'<td height=20 style=height:15.0pt>' + b.recovery_model	+ '</td>' +
						'<td width=0 style=height:15.0pt;></td>' 

			FROM @bkp AS b	

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr></table>'  			


			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Jobs 
			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Status dos Jobs
			  </td> </tr> </table> '

			set @des_MensagemHTML = @des_MensagemHTML + 
			'
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 align = left style=height:15.0pt; background: #37C1F8;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta Azul indica Job desabilitada sem identificação de falha na última execução.
			</td> </tr> 
			
			<tr height=20 align = left style=height:15.0pt; background: #FFFF00;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta Amarelo indica Job habilitada com status cancelada, tente novamente ou desconhecida (histórico ausente na Job).
			</td> </tr> 

			<tr height=20 align = left style=height:15.0pt; background: #FF0000;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta Vermelho indica falha na execução da Job.
			</td> </tr> 
			</table>
			'

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=350 style=height:20.0pt>Nome Job</td>
			<td width=150 style=height:20.0pt;>Status</td>
			<td width=150 style=height:20.0pt;>Última Execução</td>
			<td width=200 style=height:20.0pt;>Data Inicio</td>
			<td width=200 style=height:20.0pt;>Data Final</td>
			<td width=150 style=height:20.0pt;>Duração [dd hh:mm:ss]</td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			DECLARE @job TABLE
			(
			nome varchar(200),
			status varchar(100),
			ultimaExec varchar(100),
			datainicio varchar(50),
			datafim varchar(50),
			run_status int,
			run_time int,
			run_date int
			)

			;WITH cteJob
				 AS (SELECT MAX(isnull([sjh].[instance_id],'')) AS [instance_id],
							[sj].[job_id],
							[sj].[name],
							[sj].[enabled]
					   FROM [msdb]..[sysjobs] AS [sj]
							LEFT JOIN [msdb]..[sysjobhistory] AS [sjh] ON [sjh].[job_id] = [sj].[job_id]
																		  AND [sjh].[step_id] = 0
					  GROUP BY [sj].[job_id],
							   [sj].[name],
							   [sj].[enabled])

				INSERT INTO @job
						SELECT             
						 Cast(isnull([j].[name],'') as varchar(200))	as nome,
						 --
						 IsNull(Cast(CASE
							WHEN [j].[enabled] = 1
							THEN 'Enabled'
							ELSE 'Disabled'
						END as varchar(100)), '')						as status,
						--
						 IsNull(Cast(CASE
							WHEN [h].[run_status] = 0 THEN 'Falha'
							WHEN [h].[run_status] = 1 THEN 'Sucesso'
							WHEN [h].[run_status] = 2 THEN 'Tente Novamente'
							WHEN [h].[run_status] = 3 THEN 'Cancelado'
							ELSE 'Desconhecido'
						END as varchar(100)), '')						as UltimaExec,
						--
						IsNull(Cast(CASE
							WHEN isnull([h].[run_date],0) = 0
								THEN ''
							ELSE CONVERT( VARCHAR, [msdb].[dbo].[agent_datetime](case when isnull([h].[run_date],0) = 0 then 17530101 else [h].[run_date] end, isnull([h].[run_time],0)), 113)
						END as varchar(50)), '')						as dataInicio,
						-- 
						 IsNull(Cast(CASE
							WHEN [h].[run_duration] is null	-- duração pode ser zero
								THEN ''
							ELSE CONVERT( VARCHAR, DATEADD(second, Maintenance.[Management].[fn_JobIntToSeconds](isnull([h].[run_duration],'')), [msdb].[dbo].[agent_datetime](case when isnull([h].[run_date],0) = 0 then 17530101 else [h].[run_date] end, isnull([h].[run_time],0))), 113)
						END as varchar(50)), '')												as dataFim,		 
						--
						isnull(h.run_status,0)													as run_status,
						isnull(h.run_time,0)													as run_time,
						case when isnull(h.run_date,0) = 0 then 17530101 else h.run_date end	as run_date

				   FROM [cteJob] AS [j]
						LEFT JOIN [msdb].[dbo].[sysjobhistory] AS [h] ON [j].[instance_id] = [h].[instance_id]
																		 AND [h].[step_id] = 0
				  ORDER BY [j].[name],
						   [msdb].[dbo].[agent_datetime]([h].[run_date], [h].[run_time]) DESC;


			SELECT @des_MensagemHTML = @des_MensagemHTML + 

						CASE
							WHEN j.ultimaExec = 'Falha' THEN '<tr height=20 style=height:15.0pt;background: #FF0000>'
							WHEN j.status = 'Enabled' and j.ultimaExec in ('Tente Novamente', 'Cancelado', 'Desconhecido') THEN '<tr height=20 style=height:15.0pt;background: #FFFF00>'
							WHEN j.status = 'Disabled' and j.ultimaExec in ('Tente Novamente', 'Cancelado', 'Desconhecido', 'sucesso') THEN '<tr height=20 style=height:15.0pt;background: #37C1F8>'
							ELSE CASE
								  WHEN CAST(ROW_NUMBER() OVER(ORDER BY j.nome, [msdb].[dbo].[agent_datetime](j.run_date, j.run_time) DESC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
									ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
								 END 
						 END +			 
					'<td height=20 style=height:15.0pt>' + j.Nome			+ '</td>' +

					'<td height=20 style=height:15.0pt>' + j.status		+ '</td>'+

					'<td height=20 style=height:15.0pt>' + j.ultimaExec	+ '</td>'+

					'<td height=20 style=height:15.0pt>' + j.datainicio	+ '</td>'+

					'<td height=20 style=height:15.0pt>' + j.datafim		+ '</td>'+

					'<td height=20 style=height:15.0pt>' + (SELECT Management.fn_CalculateDifferenceTime(isnull(j.datainicio, ''), isnull(j.datafim,'')))	+ '</td>'+
					'<td width=0 style=height:15.0pt;></td>' 
			FROM @job AS j

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr></table>'

			
			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Jobs Messagens
			----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Messagens das Jobs</td>
			  </tr>
			</table> '

			set @des_MensagemHTML = @des_MensagemHTML + 
			'
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 align = left style=height:15.0pt; background: #FFFF00;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta amarelo apresenta maiores detalhes da Job com falha.
			</td> </tr> </table>
			'

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Nome Job</td>			
			<td width=100 style=height:20.0pt;>Última Execução</td>
			<td width=600 style=height:20.0pt;>Mensagem</td>
			<td width=20 style=height:20.0pt;></td>
			<td width=200 style=height:20.0pt;>Data</td>									
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			DECLARE @Jobs1 TABLE
			(
				Seq INT IDENTITY,
				name SYSNAME,
				status VARCHAR(50),
				message NVARCHAR(4000),		
				data_hora datetime, 
				step_Id int
			);		
		--*****
			DECLARE @Jobs2 TABLE
			(
				Seq INT IDENTITY,
				name SYSNAME,
				status VARCHAR(50),
				message NVARCHAR(4000),		
				data_hora datetime,
				step_Id int
			);
								
		    insert into @Jobs1											 
			SELECT
				j.name
				, (CASE h.run_status
					WHEN 0 THEN 'Falha'
					WHEN 1 THEN 'Sucesso'
					WHEN 2 THEN 'Repetir'
					WHEN 3 THEN 'Cancelado'
					WHEN 4 THEN 'Em Progresso'
				END) [status]
				, h.message			
				, Maintenance.Management.fn_ConverteDatetimeJobs(h.run_date, h.run_time) as Data_Hora
				, h.step_id
			FROM msdb.dbo.sysjobs j					
			CROSS APPLY
			(	SELECT TOP 1 h.run_date,
							 h.run_time,
							 h.run_status,
							 h.message,
							 h.step_id
				from msdb.dbo.sysjobhistory h
				WHERE h.step_id = 0
				 and h.job_id = j.job_id 
				ORDER BY h.instance_id DESC
			) h	
			order by J.name			
			-------------------------------------------------------------------------------------------------
			insert into @Jobs2
			SELECT
				j.name
				, (CASE h.run_status
					WHEN 0 THEN 'Falha'
					WHEN 1 THEN 'Sucesso'
					WHEN 2 THEN 'Repetir'
					WHEN 3 THEN 'Cancelado'
					WHEN 4 THEN 'Em Progresso'
				END) [status]
				, h.message			
				, Maintenance.Management.fn_ConverteDatetimeJobs(h.run_date, h.run_time) as Data_Hora
				, h.step_id
			FROM msdb.dbo.sysjobs j					
			CROSS APPLY
			(	SELECT TOP 1 h.run_date,
							 h.run_time,
							 h.run_status,
							 h.message,
							 h.step_id
				from msdb.dbo.sysjobhistory h
				WHERE h.step_id <> 0
				 and h.job_id = j.job_id 
				ORDER BY h.instance_id DESC
			) h	
			order by J.name
			-------------------------------------------------------------------------------------------------------------------------------------------
			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			CASE WHEN t1.status <> 'Sucesso' then '<tr height=20 style=height:15.0pt;background: #FFFF00>'	
					ELSE CASE
							WHEN CAST(ROW_NUMBER() OVER(ORDER BY t1.name ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
								ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
						 END 
			END +			 
							'<td height=20 style=height:15.0pt>' + t1.name								 + '</td>' +
							'<td height=20 style=height:15.0pt>' + t1.status								 + '</td>' +
							'<td height=20 style=height:15.0pt>' + t1.message + ' EXECUÇÃO DA ETAPA [ '+ cast(t2.step_Id as varchar(2)) +' ] -> ' + t2.message + '</td>' +
							'<td width=0 style=height:15.0pt;></td>' +
							'<td height=20 style=height:15.0pt>' + convert(varchar(30), t1.data_hora, 113) + '</td>' +							
							'<td width=0 style=height:15.0pt;></td>' +
							'<td width=0 style=height:15.0pt;></td>' 
																	
			from @Jobs1 as t1 inner join @Jobs2 as t2 on t1.Seq = t2.Seq

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			'</tr></table>'


			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Senhas expiradas
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			 Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt></td>
			 </tr>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Informações de Logins/Users<b></td>
			 </tr>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt></td>
			 </tr>
			</table> '
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Logins com senhas expiradas</td>
			  </tr>
			</table> '

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=200 style=height:20.0pt>Login</td>
			<td width=200 style=height:20.0pt;>Última Alteração</td>
			<td width=200 style=height:20.0pt;>Data Expiração</td>
			<td width=100 style=height:20.0pt;>Policy</td>
			<td width=100 style=height:20.0pt;>Espirada</td>
			<td width=100 style=height:20.0pt;>Must Change</td>
			<td width=100 style=height:20.0pt;>Locked</td>
			<td width=100 style=height:20.0pt;>Tentativas Erradas</td>
			</tr>'

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY IsNull(Cast(LOGINPROPERTY([SL].[name], 'IsExpired') as varchar(max)), '') DESC, DATEADD([dd], CONVERT( INT, LOGINPROPERTY([SL].[name], 'DaysUntilExpiration')), CONVERT(DATETIME, LOGINPROPERTY([SL].[name], 'PasswordLastSetTime'))) ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
					  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
				   END +
				  '<td height=20 style=height:15.0pt>' + IsNull(Cast([SL].[name] as varchar(max)), '')											+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(LOGINPROPERTY([SL].[name], 'PasswordLastSetTime') as varchar(max)), '')		+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(DATEADD([dd], CONVERT( INT, LOGINPROPERTY([SL].[name], 'DaysUntilExpiration')), CONVERT(DATETIME, LOGINPROPERTY([SL].[name], 'PasswordLastSetTime'))) as varchar(max)), '')  + '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([SL].[is_policy_checked] as varchar(max)), '')								+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(LOGINPROPERTY([SL].[name], 'IsExpired') as varchar(max)), '')				+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(LOGINPROPERTY([SL].[name], 'IsMustChange') as varchar(max)), '')			+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(LOGINPROPERTY([SL].[name], 'IsLocked') as varchar(max)), '')				+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(LOGINPROPERTY([SL].[name], 'BadPasswordCount') as varchar(max)), '')		+ '</td><tr>' 
			  FROM [sys].[sql_logins] AS [SL]
			  Where LOGINPROPERTY([SL].[name], 'IsExpired') = 1
				Or LOGINPROPERTY([SL].[name], 'DaysUntilExpiration') <= 1
			 ORDER BY IsNull(Cast(LOGINPROPERTY([SL].[name], 'IsExpired') as varchar(max)), '') DESC, DATEADD([dd], CONVERT( INT, LOGINPROPERTY([SL].[name], 'DaysUntilExpiration')), CONVERT(DATETIME, LOGINPROPERTY([SL].[name], 'PasswordLastSetTime'))) ASC
 
			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'


			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- usuários órfãos
			------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br><br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Usuários Orfãos</td>
			  </tr>
			</table> '
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Banco de Dados</td>
			<td width=300 style=height:20.0pt;>Usuário</td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			CREATE TABLE [##tb_UsuariosOrfaos]
			([Database_Name] VARCHAR(255),
			 [Name]          VARCHAR(255)
			);

			exec [sp_MSforeachdb]
			 'Insert Into ##tb_UsuariosOrfaos  
			Select ''?'' as database_name, B.name 
			  From master.sys.syslogins A 
				   Right Join [?].sys.sysusers B On A.name collate Latin1_General_CI_AI = B.name collate Latin1_General_CI_AI
			 Where A.sid is null 
			   And B.issqlrole <> 1 
			   And B.isapprole <> 1   
			   And (B.name <> ''INFORMATION_SCHEMA''  And B.name not in (''guest'', ''sys'', ''dbo'')
			   And B.name <> ''system_function_schema'')';

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY [Database_Name], [Name]) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
					  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
				   END +
				  '<td height=20 style=height:15.0pt>'  + IsNull(Cast([Database_Name] as varchar(max)), '')	+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([Name] as varchar(max)), '')			+ '</td>' +
				   '<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td></tr>'
			  FROM [##tb_UsuariosOrfaos]
			 ORDER BY [Database_Name], [Name]

			DROP TABLE [##tb_UsuariosOrfaos];

			  SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'


			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			--12 - Usuarios SID diferentes.sql
			------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Usuários com SID diferentes do Login</td>
			  </tr>
			</table> '
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Banco de Dados</td>
			<td width=300 style=height:20.0pt;>Usuário</td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			CREATE TABLE [##tb_UsuariosSID]
			([Database_Name] VARCHAR(255),
			 [Name]          VARCHAR(255)
			);

			EXEC [sp_MSforeachdb]
				 'Insert Into ##tb_UsuariosSID
			Select ''?'' as database_name, B.name 
			  From master.sys.syslogins A 
				   Inner Join [?].sys.sysusers B On A.name collate Latin1_General_CI_AI = B.name collate Latin1_General_CI_AI
											   And A.SId <> B.SId                          
			 Where B.issqlrole <> 1 
			   And B.isapprole <> 1   
			   And (B.name <> ''INFORMATION_SCHEMA''  And B.name not in (''guest'', ''sys'', ''dbo'')
			   And B.name <> ''system_function_schema'')';

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY [Database_Name], [Name]) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
					  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
				   END +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([Database_Name] as varchar(max)), '')	+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([Name] as varchar(max)), '')			+ '</td>' +
				   '<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td></tr>'
			  FROM [##tb_UsuariosSID]
			 ORDER BY [Database_Name],
					  [Name];        

			DROP TABLE [##tb_UsuariosSID];

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>' 				
			/**************************************************************************************************************/
			/* Final do HTML                                                                                              */

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			'</div>
			</body>
			</html>'
	
			SET @subject = 'CheckList Diário - Task SQL Server: '+@@SERVERNAME;
			SET @recipients = 'agenteti@cravil.com.br';

			EXEC [msdb].[dbo].[sp_send_dbmail]
				@recipients = @recipients,
				@subject = @subject,
				@profile_name = 'CRAVIL',
				@body = @des_MensagemHTML,
				@body_format = 'HTML';
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		DECLARE @corpoFalha varchar(max)
		  			
		SET @subject = 'Falha na execução de Procedure: '+@@SERVERNAME;
		SET @recipients = 'agenteti@cravil.com.br';
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure sp_ReportCheckListTaskSQL:<b> <br>
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
	SET NOCOUNT OFF
END