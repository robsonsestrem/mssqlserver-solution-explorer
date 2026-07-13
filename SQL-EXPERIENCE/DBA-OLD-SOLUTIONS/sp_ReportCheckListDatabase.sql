use YOUR_DATABASE
go

CREATE OR ALTER PROCEDURE Management.sp_ReportCheckListDatabase
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
		BEGIN TRY
		BEGIN TRANSACTION
			/**************************************************************************************************************/
			/* In�cio do HTML                                                                                             */

			DECLARE @des_MensagemHTML VARCHAR(MAX);

			Set @des_MensagemHTML = '	
			<html>
			<head>
			<meta http-equiv=Content-Type content=text/html; charset=windows-1252>
			</head>

			<body>
			<div align=center>'

			-- T�TULO
                                                                                  
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>CheckList Di�rio SQL Server - ' + CONVERT(VARCHAR(50), GETDATE(), 103) + '<b></td>
			 </tr>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Informa��es do servidor: ' + @@SERVERNAME + '<b></td>
			 </tr>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt></td>
			 </tr>
			</table> '


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Vers�o, edi��o, etc... do SQL Server
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			<td width=100 style=height:20.0pt>@@VERSION</td>	
			</tr>	
			 <tr height=20 align = center style=height:15.0pt; background: #E4E4E4;>
			'
			SELECT @des_MensagemHTML = @des_MensagemHTML + 
		   	
				   '<td height=20 style=height:15.0pt>' + @@VERSION + '</td>' 

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr>	</table>'


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			<td width=100 style=height:20.0pt>Servidor</td>
			<td width=100 style=height:20.0pt>Cluster</td>
			<td width=100 style=height:20.0pt>Vers�o</td>
			<td width=150 style=height:20.0pt>Edi��o</td>
			<td width=150 style=height:20.0pt>ProductVersion</td>
			<td width=150 style=height:20.0pt>SP</td>
			<td width=150 style=height:20.0pt>Collation</td>	
			</tr>	
			 <tr height=20 align = center style=height:15.0pt; background: #E4E4E4;>
			'

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   '<td height=20 style=height:15.0pt>' + ISNULL(CAST(SERVERPROPERTY('ComputerNamePhysicalNetBIOS') as varchar(MAX)), '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CASE SERVERPROPERTY('IsClustered')
					   WHEN 1 THEN 'Sim'
					   ELSE 'N�o'
				   END, '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CASE PARSENAME(CAST(SERVERPROPERTY('ProductVersion') AS VARCHAR(max)), 4)
					   WHEN 13 THEN '2016'
					   WHEN 12 THEN '2014'
					   WHEN 11 THEN '2012'
					   WHEN 10 THEN '2008'
					   WHEN 9 THEN '2005'
				   END, '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CAST(SERVERPROPERTY('Edition') as varchar(MAX)), '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CAST(SERVERPROPERTY('ProductVersion') as varchar(MAX)), '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CAST(SERVERPROPERTY('ProductLevel') as varchar(MAX)), '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CAST(SERVERPROPERTY('Collation') as varchar(MAX)), '') + '</td>' 

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr>
			</table>'


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Recursos do Server
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Online desde</td>
			<td width=250 style=height:20.0pt>Total de Dias Online</td>
			<td width=250 style=height:20.0pt>Cores/CPU</td>
			<td width=200 style=height:20.0pt>Mem�ria Gb</td>
			<td width=0 style=height:20.0pt></td>
			<td width=0 style=height:20.0pt></td>
			<td width=0 style=height:20.0pt></td>

			</tr>
			 <tr height=20 align = center style=height:15.0pt; background: #E4E4E4;>'

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			'<td height=20 style=height:15.0pt>' + 'Uptime: '+CONVERT(VARCHAR, [login_time], 113) + '</td>' 
			  FROM [master]..[sysprocesses]
			 WHERE [spid] = 1;

			--
			DECLARE @vUptime_Days AS INT = 0;			
			set @vUptime_Days = (SELECT DATEDIFF(DAY,DB.sqlserver_start_time,GETDATE())	FROM sys.dm_os_sys_info DB)
			SELECT @des_MensagemHTML = @des_MensagemHTML + '<td height=20 style=height:15.0pt>' + cast(@vUptime_Days as char(4)) + '</td>' 
			--

			SELECT @des_MensagemHTML = @des_MensagemHTML + '
					<td height=20 style=height:15.0pt>' + CAST([cpu_count] as varchar)  + '</td>' + 
				   '<td height=20 style=height:15.0pt>' + CAST(CAST(CAST(([physical_memory_kb] / 1024) AS DECIMAL(18,2)) /1024 AS DECIMAL(18,2)) AS VARCHAR(30)) + '</td>'

				   FROM [sys].[dm_os_sys_info]

			SET  @des_MensagemHTML = @des_MensagemHTML + 
					'<td width=0 style=height:15.0pt></td>		
					<td width=0 style=height:15.0pt></td>
					<td width=0 style=height:15.0pt></td>'
		 
			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr></table>'


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Inform���es da inst�ncia
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Servi�o</td>
			<td width=250 style=height:20.0pt>Startup</td>
			<td width=250 style=height:20.0pt>Status</td>
			<td width=200 style=height:20.0pt>Log On As</td>
			<td width=0 style=height:20.0pt></td>
			<td width=0 style=height:20.0pt></td>
			<td width=0 style=height:20.0pt></td>
			</tr>'
 
			SELECT  @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY [servicename] ASC) % 2 AS BIT) = 1 THEN '<tr height=20 align = center style=height:15.0pt>'
					  ELSE '<tr height=20 align = center style=height:15.0pt; background: #E4E4E4;>'
				   END +
				   '<td height=20 style=height:15.0pt>' + [servicename] + '</td>' +
				   '<td height=20 style=height:15.0pt>' + [startup_type_desc] + '</td>' +
				   '<td height=20 style=height:15.0pt>' + [status_desc] + '</td>' +
				   '<td height=20 style=height:15.0pt>' + [service_account] + '</td>' + 
				   '<td width=0 style=height:15.0pt></td>
				   <td width=0 style=height:15.0pt></td>
				   <td width=0 style=height:15.0pt></td></tr>'
			  FROM [sys].[dm_server_services]
			  Order by [servicename]

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Espa�o no disco dos datafiles
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			 Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Discos Databases</td>
			<td width=250 style=height:20.0pt;>Espa�o Total Gb </td>
			<td width=250 style=height:20.0pt;>Dispon�vel Gb</td>
			<td width=200 style=height:20.0pt;>Dispon�vel %</td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'
 
			declare @discos table
			(
			volume_mount_point varchar(10),
			Espa�oTotal_Gb decimal(19,2),
			TotalDisponivel_Gb decimal(19,2),
			DisponivelPercentual decimal(19,2)
			)
			insert into @discos
			SELECT DISTINCT
							VS.volume_mount_point [Montagem] ,
				
							CAST(CAST(VS.total_bytes AS DECIMAL(19, 2)) / 1024 / 1024 / 1024 AS DECIMAL(10, 2)) AS [Espa�oTotal_Gb] ,
							CAST(CAST(VS.available_bytes AS DECIMAL(19, 2)) / 1024 / 1024 / 1024 AS DECIMAL(10, 2)) AS [TotalDisponivel_Gb],
			
							CAST(( CAST(VS.available_bytes AS DECIMAL(19, 2)) / CAST(VS.total_bytes AS DECIMAL(19, 2)) * 100 ) AS DECIMAL(10, 2)) AS [Disponivel_%]
				 
						FROM
							sys.master_files AS MF
							CROSS APPLY [sys].[dm_os_volume_stats](MF.database_id, MF.file_id) AS VS
						WHERE
							CAST(VS.available_bytes AS DECIMAL(19, 2)) / CAST(VS.total_bytes AS DECIMAL(19, 2)) * 100 < 100

			SELECT @des_MensagemHTML = @des_MensagemHTML + 	  
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY d.volume_mount_point ASC) % 2 AS BIT) = 1 THEN '<tr height=20 align = center style=height:15.0pt>'
					  ELSE '<tr height=20 align = center style=height:15.0pt; background: #E4E4E4;>'
				   END +

				   '<td height=20 style=height:15.0pt>' + d.volume_mount_point						+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + CAST(d.Espa�oTotal_Gb AS VARCHAR(20))		+ '</td>' + 
				   '<td height=20 style=height:15.0pt>' + CAST(d.TotalDisponivel_Gb AS VARCHAR(20))	+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + CAST(d.DisponivelPercentual AS VARCHAR(20))	+ '</td>' +
				   '<td width=50 style=height:15.0pt;></td>
				   <td width=20 style=height:15.0pt;></td>
				   <td width=20 style=height:15.0pt;></td>' 
				FROM @discos as d

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr></table>'


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- �ltimas reinicializa��es do servidor                                                                               
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			 Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			  <tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>�ltimas reinicializa��es do servidor.</td>
			  </tr>
			</table> '

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  align = center style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Data Shutdown</td>
			<td width=300 style=height:20.0pt;>Data Start</td>
			<td width=100 style=height:20.0pt;>Minutos Downtime</td>
			<td width=50 style=height:20.0pt;></td>
			<td width=50 style=height:20.0pt;></td>
			<td width=50 style=height:20.0pt;></td>
			<td width=50 style=height:20.0pt;></td>
			</tr>'			

			SELECT  @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY t1.DateShutdown DESC) % 2 AS BIT) = 1 THEN '<tr height=20 align = center style=height:15.0pt>'
					  ELSE '<tr height=20 align = center style=height:15.0pt; background: #E4E4E4;>'
				   END +
				  '<td height=20 style=height:15.0pt>' + CONVERT(varchar(30), t1.DateShutdown, 113)		+ '</td>' +
				  '<td height=20 style=height:15.0pt>' + CONVERT(varchar(30), t1.DateStart, 113)			+ '</td>' +
				  '<td height=20 style=height:15.0pt>' + IsNull(Cast(t1.[Minutes] as varchar(max)), '')	+ '</td>' +
					'<td width=70 style=height:15.0pt;></td>
					<td width=70 style=height:15.0pt;></td>
					<td width=70 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td></tr>'
			 FROM YOUR_DATABASE.Management.HistoryRestartServer as t1
			 Order by t1.DateShutdown DESC

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'


			/**************************************************************************************************************/
			/* Informa��es dos Databases                                                                                ***/
			/**************************************************************************************************************/
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt>	</td>
			 </tr>
			 <tr height=20 align = center style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt><b>Informa��es dos Databases<b></td>
			 </tr>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt>	</td>
			 </tr>
			</table> '


			/**************************************************************************************************************/
			/************* Vis�o sintetizada de espa�o em disco dos databases ***************/
			/**************************************************************************************************************/
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Status dos Bancos de Dados
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Status dos Bancos de Dados</td>
			  </tr>
			</table> '

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=200 style=height:20.0pt>Nome Banco</td>
			<td width=100 style=height:20.0pt;>Data Cria��o</td>
			<td width=100 style=height:20.0pt;>Tamanho Total Gb</td>
			<td width=100 style=height:20.0pt;>Status</td>
			<td width=100 style=height:20.0pt;>Acesso</td>
			<td width=100 style=height:20.0pt;>Recovery Model</td>
			<td width=100 style=height:20.0pt;></td>
			</tr>'

			SELECT  @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY [MST].[name] ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
					  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
				   END +
				   '<td height=20 style=height:15.0pt>' + ISNULL(mst.[name], '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + CONVERT( VARCHAR(2), DATEPART(dd, mst.[create_date]))+'-'+CONVERT(VARCHAR(3), DATENAME([mm], mst.[create_date]))+'-'+CONVERT(VARCHAR(4), DATEPART([yy], mst.[create_date])) + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(CONVERT(  VARCHAR(20), [AA].[Total Size GB]), '') + '</td>' +
				   '<td height=20 style=height:15.0pt>' + ISNULL(mst.[state_desc], '') + '</td>' +
				  '<td height=20 style=height:15.0pt>' + ISNULL(mst.[user_access_desc], '') + '</td>' +
				  '<td height=20 style=height:15.0pt>' + ISNULL(mst.[recovery_model_desc], '') + '</td>' +
				   '<td height=20 style=height:15.0pt></td></tr>' 
			  FROM [sys].[databases] AS [MST]
				   INNER JOIN (SELECT [B].[name] AS [LOG_DBNAME],
									  CONVERT( DECIMAL(20, 2), SUM(CONVERT(DECIMAL(20, 2), ([A].[size] * 8)) / 1024) / 1024) AS [Total Size GB]
								 FROM [sys].[sysaltfiles] AS [A]
									  INNER JOIN [sys].[databases] AS [B] ON [A].[dbid] = [B].[database_id]
								GROUP BY [B].[name]) AS [AA] ON [AA].[LOG_DBNAME] = [MST].[name]
			 ORDER BY [MST].[name];

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'


		-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20 style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Totais em Arquivos (mfd, nfd) por Database</td>
			  </tr>
			</table> '

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 style=color: #FFFFFF; background: #44546A;>
			<td width=300 style=height:20.0pt>Database</td>
			<td width=300 style=height:20.0pt;>Total Reservado em Disco Gb</td>
			<td width=300 style=height:20.0pt;>Total Usado Gb</td>
			<td width=100 style=height:20.0pt;>Total Livre Gb</td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			CREATE TABLE #Tamanhos
					(			
						Banco VARCHAR(50),
						EspacoReservadoEmDisco_MB DECIMAL(15,2), 
						EspacoUsado_MB DECIMAL(15,2), 
						EspacoLivre_MB DECIMAL(15,2)
					);
																										 -- inser��o de dados em tabela tempor�ria
					EXEC sp_MSforeachdb 'USE ?
					INSERT INTO #Tamanhos
					(	
						Banco
						, EspacoReservadoEmDisco_MB
						, EspacoUsado_MB										 
						, EspacoLivre_MB
					)
					SELECT
						DB_NAME() Banco
						, CAST(a.EspacoReservadoEmDisco AS DECIMAL(15,2)) EspacoReservadoEmDisco_MB
						, CAST(a.EspacoUsado AS DECIMAL(15,2)) EspacoUsado_MB
						, CAST(a.EspacoReservadoEmDisco - a.EspacoUsado AS DECIMAL(15,2)) EspacoLivre_MB
					FROM
					(
						select
							  (select SUM(ps.reserved_page_count)/128.0 from sys.dm_db_partition_stats ps) EspacoUsado
							, (select SUM(size/128.0) from sys.database_files where type IN (0,2,4)) EspacoReservadoEmDisco 
					) a';

					DECLARE @Tamanhos TABLE
					(				
						Banco VARCHAR(50),
						ArquivoDeDados_EspacoReservadoEmDisco_MB DECIMAL(15,2), 
						ArquivoDeDados_EspacoUsado_MB DECIMAL(15,2), 
						ArquivoDeDados_EspacoLivre_MB DECIMAL(15,2),
						ArquivoDeLog_EspacoReservadoEmDisco_MB DECIMAL(15,2), 
						ArquivoDeLog_EspacoUsado_MB DECIMAL(15,2),
						ArquivoDeLog_EspacoLivre_MB DECIMAL(15,2)
					);
					INSERT INTO @Tamanhos
					SELECT
						t.Banco
						, t.EspacoReservadoEmDisco_MB									 -- inser��o de dados na vari�vel do tipo table
						, t.EspacoUsado_MB
						, t.EspacoLivre_MB
						, l.EspacoReservadoEmDisco_MB AS ArquivoDeLog_EspacoReservadoEmDisco_MB
						, l.EspacoUsado_MB AS ArquivoDeLog_EspacoUsado_MB
						, CAST(l.EspacoReservadoEmDisco_MB-l.EspacoUsado_MB AS DECIMAL(10,2)) AS ArquivoDeLog_EspacoLivre_MB
					FROM #Tamanhos AS t INNER JOIN (SELECT a.Banco, a.EspacoReservadoEmDisco_MB, b.EspacoUsado_MB
													FROM(select
															RTRIM(p.instance_name) AS Banco
															,CAST(p.cntr_value/1024.0 AS DECIMAL(15,2)) AS EspacoReservadoEmDisco_MB 
														 from sys.dm_os_performance_counters p
														 WHERE p.counter_name LIKE 'Log File(s) Size (KB)%'
														) AS a INNER JOIN (select
																			RTRIM(p.instance_name) AS Banco
																			,CAST(p.cntr_value/1024.0 AS DECIMAL(15,2)) AS EspacoUsado_MB 
																		   from sys.dm_os_performance_counters p
																			where p.counter_name LIKE 'Log File(s) Used Size (KB)%'
															) AS b ON a.Banco = b.Banco
													WHERE a.Banco NOT IN ('_Total', 'mssqlsystemresource', 'tempdb', 'master', 'model', 'msdb')
													) AS l ON t.Banco = l.Banco
					ORDER BY Banco;


			SELECT @des_MensagemHTML = @des_MensagemHTML + 	  
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY t.Banco ASC) % 2 AS BIT) = 1 THEN '<tr height=20 align = left style=height:15.0pt>'
					  ELSE '<tr height=20 align = left style=height:15.0pt; background: #E4E4E4;>'
				   END +

				   '<td height=20 style=height:15.0pt>' + t.Banco																			+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + cast(cast(t.EspacoReservadoEmDisco_MB / 1024 as decimal(15,2)) as varchar(20))	+ '</td>' + 
				   '<td height=20 style=height:15.0pt>' + cast(cast(t.EspacoUsado_MB / 1024 as decimal(15,2)) as varchar(20))				+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + cast(cast(t.EspacoLivre_MB / 1024 as decimal(15,2))	as varchar(20))				+ '</td>' +
				   '<td width=50 style=height:15.0pt;></td>
				   <td width=20 style=height:15.0pt;></td>
				   <td width=20 style=height:15.0pt;></td>' 
				FROM #Tamanhos as t

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</tr></table>'

			drop table #Tamanhos


			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Tamanho dos Arquivos dos Bancos de Dados e Percentual Livre dos Mesmos         
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Tamanho dos Arquivos dos Bancos de Dados e Percentual Livre dos Mesmos
			  </td>  </tr> </table>'
			
			set @des_MensagemHTML = @des_MensagemHTML + 
			'
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 align = left style=height:15.0pt; background: #FFFF00;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta amarelo indica percentual livre dos datafiles menor ou igual a 5%.
			</td> </tr> </table>
			'

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>						

		    <tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=200 style=height:20.0pt>Nome Banco</td>
			<td width=200 style=height:20.0pt;>Nome Arquivo</td>
			<td width=650 style=height:20.0pt;>Arquivo</td>
			<td width=100 style=height:20.0pt;>Tamanho Gb</td>
			<td width=70 style=height:20.0pt;>Espa�o Livre Gb</td>
			<td width=70 style=height:20.0pt;>% Livre</td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			if(OBJECT_ID('tempdb..##tempFilesReport') is not null)
				drop table ##tempFilesReport

			CREATE TABLE ##tempFilesReport(DatabaseName sysname , 
								Name sysname , 
								physical_name nvarchar(500) , 
								size decimal(18 , 2) , 
								FreeSpace decimal(18 , 2) , 
								PercFree decimal(18 , 2));   


			EXEC sp_msforeachdb '
			Use [?];
			INSERT INTO ##tempFilesReport(DatabaseName , 
							   Name , 
							   physical_name , 
							   Size , 
							   FreeSpace , 
							   PercFree)
			SELECT DB_NAME()AS DatabaseName , 
				   Name , 
				   physical_name , 
				   CAST(CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2))AS nvarchar) as SizeMB , 
				   CAST(CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2)) - CAST(FILEPROPERTY(name , ''SpaceUsed'') * 8.0 / 1024.0 AS decimal(18 , 2))AS nvarchar) AS FreeSpaceMB , 
				   (CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2)) - CAST(FILEPROPERTY(name , ''SpaceUsed'') * 8.0 / 1024.0 AS decimal(18 , 2))) * 100 / CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2)) AS PercFree
			  FROM sys.database_files;'

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   case
					  when t1.PercFree <= 5.00 then '<tr height=20 style=height:15.0pt;background: #FFFF00>'
					  else
						  case when CAST(ROW_NUMBER() OVER(ORDER BY t1.DatabaseName, Name ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
						  else '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'	
						  end				  
				   end +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(t1.DatabaseName as varchar(max)), '')								+ '</td>' + 
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(t1.Name as varchar(max)), '')										+ '</td>' + 
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(t1.physical_name as varchar(max)), '')								+ '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(cast(t1.Size /1024 as decimal(18,2)) as varchar(max)), '')			+ '</td>' + 
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(cast(t1.FreeSpace /1024 as decimal(18,2)) as varchar(max)), '')		+ '</td>' + 
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(t1.PercFree as varchar(max)), '')									+ '</td>' +
				   '<td height=20 style=height:15.0pt></td></tr>' 
			  FROM ##tempFilesReport as t1
			Order by DatabaseName, Name			

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'
		    

			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Configura��es de crescimento
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------	
			DECLARE @Monitor_Datafile_Size TABLE
				(
				database_id int,
				[database_name] sysname,
				state_desc varchar(50),
				[type_desc] varchar(10),
				[file_id] int,
				[name] sysname,
				physical_name varchar(100),
				disk_total_size_GB numeric(18,2),
				disk_free_size_GB numeric(18,2),
				size_GB numeric(18,2),
				max_size_GB numeric(18,2),
				max_real_size_GB numeric(18,2),
				free_space_GB numeric(18,2),
				growth_MB numeric(18,2),
				is_percent_growth bit,
				is_autogrowth_enabled int,
				percent_used numeric(18,2),
				growth_times int
				)

			INSERT INTO @Monitor_Datafile_Size
			SELECT
				B.database_id AS database_id,
				B.[name] AS [database_name],
				A.state_desc,
				A.[type_desc],
				A.[file_id],
				A.[name],
				A.physical_name,
				CAST(C.total_bytes / 1073741824.0 AS NUMERIC(18, 2)) AS disk_total_size_GB,
				CAST(C.available_bytes / 1073741824.0 AS NUMERIC(18, 2)) AS disk_free_size_GB,
				CAST(A.size / 128 / 1024.0 AS NUMERIC(18, 2)) AS size_GB,
				CAST(A.max_size / 128 / 1024.0 AS NUMERIC(18, 2)) AS max_size_GB,
				CAST(
					(CASE
						WHEN A.growth <= 0 THEN A.size / 128 / 1024.0
						WHEN A.max_size <= 0 THEN C.total_bytes / 1073741824.0
						WHEN A.max_size / 128 / 1024.0 > C.total_bytes / 1073741824.0 THEN C.total_bytes / 1073741824.0
						ELSE A.max_size / 128 / 1024.0 
					END) AS NUMERIC(18, 2)) AS max_real_size_GB,
				CAST(NULL AS NUMERIC(18, 2)) AS free_space_GB,
				(CASE WHEN A.is_percent_growth = 1 THEN A.growth ELSE CAST(A.growth / 128 AS NUMERIC(18, 2)) END) AS growth_MB,
				A.is_percent_growth,
				(CASE WHEN A.growth <= 0 THEN 0 ELSE 1 END) AS is_autogrowth_enabled,
				CAST(NULL AS NUMERIC(18, 2)) AS percent_used,
				CAST(NULL AS INT) AS growth_times  
			FROM
				sys.master_files        A   WITH(NOLOCK)
				JOIN sys.databases      B   WITH(NOLOCK)    ON  A.database_id = B.database_id
				CROSS APPLY sys.dm_os_volume_stats(A.database_id, A.[file_id]) C
			------------------------------------------------------------------------------------------------------------------------------------------    
			UPDATE A
			SET
				A.free_space_GB = (
				(CASE 
					WHEN max_size_GB <= 0 THEN A.disk_free_size_GB
					WHEN max_real_size_GB > disk_free_size_GB THEN A.disk_free_size_GB 
					ELSE max_real_size_GB - size_GB
				END)),
				A.percent_used = (size_GB / (CASE WHEN max_real_size_GB > disk_total_size_GB THEN A.disk_total_size_GB ELSE max_real_size_GB END)) * 100
			FROM 
				@Monitor_Datafile_Size A    
			--
			UPDATE A
			SET
				A.growth_times = 
				(CASE 
					WHEN A.growth_MB <= 0 THEN 0 
					WHEN A.is_percent_growth = 0 THEN (A.max_real_size_GB - A.size_GB) / (A.growth_MB / 1024.0) 
					ELSE NULL 
				END)
			FROM 
				@Monitor_Datafile_Size A
			------------------------------------------------------------------------------------------------------------------------------------------
			DECLARE  @Monitoramento_Datafile_Size TABLE
			(
			IdEfeitoZebrado int identity(1,1),
			Databases nvarchar(40),
			Nome_Logico nvarchar(80),
			Tipo varchar(10),
			Tamanho_Arquivo_Gb numeric(18,2),
			Tamanho_Limite_Gb numeric(18,2),
			Qt_Livre_Limite_Gb numeric(18,2),
			Autogrowth_Mb numeric(18,2),
			Qt_Vezes_Autogrowth int,
			Limite_Usado_% numeric(18,2)
			)   

			INSERT INTO @Monitoramento_Datafile_Size 
			(  Databases, Nome_Logico, Tipo, Tamanho_Arquivo_Gb, Tamanho_Limite_Gb, Qt_Livre_Limite_Gb
			 , Autogrowth_Mb, Qt_Vezes_Autogrowth, Limite_Usado_% )

			SELECT m.[database_name], m.[name], m.[type_desc], m.size_GB, m.max_real_size_GB
			, m.free_space_GB, m.growth_MB, isnull(m.growth_times, ''), m.percent_used
			from @Monitor_Datafile_Size AS m  
	
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Configura��es de Crescimentos/Limites em Cada Datafile
			  </td> </tr> </table> '

			set @des_MensagemHTML = @des_MensagemHTML + 
			'
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 align = left style=height:15.0pt; background: #FFFF00;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta amarelo indica que o espa�o usado do limite proposto no Datafile est� maior ou igual a 90%.
			</td> </tr> </table>
			'

			Set @des_MensagemHTML = @des_MensagemHTML + '	
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
				<tr height=20 style=color: #FFFFFF; background: #44546A;>
														<td width=120 style=height:20.0pt>Databases			</td>
														<td width=100 style=height:20.0pt>Nome L�gico			</td>
														<td width=40 style=height:20.0pt>Tipo					</td>
														<td width=90 style=height:20.0pt>Tamanho Arquivo Gb	</td>
														<td width=90 style=height:20.0pt>Tamanho Limitado Gb	</td>
														<td width=90 style=height:20.0pt>Livre do Limitado Gb	</td>
														<td width=70 style=height:20.0pt>Autogrowth Mb		</td>										
														<td width=90 style=height:20.0pt>Qtdade Autogrowth	</td>
														<td width=70 style=height:20.0pt>% Usado Limite		</td>
													</tr>
												  '			
							SELECT  @des_MensagemHTML = @des_MensagemHTML + 
								   case
									when m.[Limite_Usado_%] >= 90.00 then '<tr height=20 style=height:15.0pt;background: #FFFF00>'
									else
										case when CAST(ROW_NUMBER() OVER(ORDER BY m.Databases ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
											 else '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
									    end
								   end +
								   '<td height=20 style=height:15.0pt>' + CAST(m.Databases				AS NVARCHAR(80))+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + m.Nome_Logico									+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + m.Tipo											+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + CAST(m.Tamanho_Arquivo_Gb		AS VARCHAR(20))	+ '</td>' + 
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Tamanho_Limite_Gb		AS VARCHAR(20))	+ '</td>' +			
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Qt_Livre_Limite_Gb		AS VARCHAR(20))	+ '</td>' +			
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Autogrowth_Mb			AS VARCHAR(20))	+ '</td>' +		   
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Qt_Vezes_Autogrowth		AS VARCHAR(20))	+ '</td>' +	
								   '<td height=20 style=height:15.0pt>' +	CAST(m.[Limite_Usado_%]			AS VARCHAR(20))	+ '</td>' +	
								   '</tr>'
							  FROM @Monitoramento_Datafile_Size as m			 					 

							SELECT @des_MensagemHTML = @des_MensagemHTML + 
							 '</table>'			
	
	    
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			-- Total de Arquivos VLF (virtual log files) em Cada Arquivo de Log dos Banco de Dados
			-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			Set @des_MensagemHTML = @des_MensagemHTML + '<br>
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Total de Arquivos VLF (virtual log files) em Cada Arquivo de Log dos Banco de Dados
			  </td> </tr> </table> '

			set @des_MensagemHTML = @des_MensagemHTML + 
			'
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20 align = left style=height:15.0pt; background: #FFFF00;>
			<td height=20 colspan=7 style=height:15.0pt; text-align:left>
				Alerta amarelo indica fragmenta��o interna dos arquivos de Log maior ou igual a 50, indicador para lentid�es no ambiente.
			</td> </tr> </table>
			'

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=200 style=height:20.0pt>Nome Banco</td>
			<td width=400 style=height:20.0pt;>Qtd de Arquivos VLF</td>
			<td width=250 style=height:20.0pt;></td>
			<td width=100 style=height:20.0pt;></td>
			<td width=70 style=height:20.0pt;></td>
			<td width=70 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			DECLARE @query VARCHAR(max), @dbname VARCHAR(max), @count INT;

			SET NOCOUNT ON;

			DECLARE csr CURSOR LOCAL FAST_FORWARD READ_ONLY
			FOR SELECT [name]
				  FROM [sys].[databases];

			CREATE TABLE [##loginfo]
			([dbname]      VARCHAR(max),
			 [num_of_rows] INT
			);

			OPEN csr;

			FETCH NEXT FROM csr INTO @dbname;

			WHILE(@@fetch_status <> -1)
				BEGIN
					SET NOCOUNT ON;
					CREATE TABLE [#log_info]
					([RecoveryUnitId] TINYINT,	-- esta coluna n�o existe no DBCC loginfo do sql server 2008 R2
					 [fileid]         TINYINT,
					 [file_size]      BIGINT,
					 [start_offset]   BIGINT,
					 [FSeqNo]         INT,
					 [status]         TINYINT,
					 [parity]         TINYINT,
					 [create_lsn]     NUMERIC(25, 0)
					);

					SET @query = 'DBCC loginfo ('+''''+@dbname+''') ';

					INSERT INTO [#log_info] EXEC (@query);

					SET @count = @@rowcount;

					DROP TABLE [#log_info];

					INSERT INTO [##loginfo] VALUES (@dbname, @count);

					FETCH NEXT FROM csr INTO @dbname
				END

			CLOSE csr
			DEALLOCATE csr;

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   case
					   when [num_of_rows] >= 50 then '<tr height=20 style=height:15.0pt;background: #FFFF00>'
					   else
						case when CAST(ROW_NUMBER() OVER(ORDER BY [num_of_rows] desc) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
							else '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
						end
				   end +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([dbname] as varchar(max)), '') + '</td>' + 
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([num_of_rows] as varchar(max)), '') + '</td>' +
				   '<td width=250 style=height:15.0pt;></td>
					<td width=100 style=height:15.0pt;></td>
					<td width=70 style=height:15.0pt;></td>
					<td width=70 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td></tr>'
			  FROM [##loginfo]
			 ORDER BY [num_of_rows] desc;

			DROP TABLE [##loginfo];

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'

			/**************************************************************************************************************/
			/* Final do HTML                                                                                              */

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
			'</div>
			</body>
			</html>'

			DECLARE @subject VARCHAR(100), @recipients VARCHAR(100);

			SET @subject = 'CheckList Di�rio - Databases: '+@@SERVERNAME;
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
		SET @subject = 'Falha na execu��o de Procedure: '+@@SERVERNAME;
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportCheckListDatabase]:<b> <br>
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
	SET NOCOUNT OFF;
END


				  