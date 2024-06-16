USE Maintenance
GO

/****** Object:  StoredProcedure [dbo].[sp_ReportEventsSGBD]    Script Date: 19/04/2017 10:32:24 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
CREATE OR ALTER PROCEDURE Management.[sp_ReportEventsSGBD] @ExibirApenasHtml BIT = 0
WITH ENCRYPTION
AS
	BEGIN
		--SET LANGUAGE US_ENGLISH;

		SET NOCOUNT ON;

		-- *** Variáveis
		DECLARE @vSubject NVARCHAR(255) = 'Relatório Diário do SQL Server: '+@@SERVERNAME;
		DECLARE @vBody AS NVARCHAR(MAX) = '';

		-- *** Parte 1: Informações de configuração da instância
		IF OBJECT_ID('tempdb.dbo.#Tabela') IS NOT NULL
			DROP TABLE #Tabela;

		DECLARE @vOnline_Since AS NVARCHAR (10) = '';
		DECLARE @vUptime_Days AS INT = 0;

		SELECT
			@vOnline_Since = CONVERT(NVARCHAR(10), DB.sqlserver_start_time,103)
			, @vUptime_Days = DATEDIFF(DAY,DB.sqlserver_start_time,GETDATE())
		FROM
			sys.dm_os_sys_info DB;

		SELECT
			 SERVERPROPERTY ('ComputerNamePhysicalNetBIOS') AS netbios_name
			,@@SERVERNAME AS server_name
			,SERVERPROPERTY('EDITION') AS edition
			,SERVERPROPERTY ('ProductVersion') AS version
			,SERVERPROPERTY ('ProductLevel') AS [level]
			,@vOnline_Since AS online_since
			,@vUptime_Days AS uptime_days
			INTO #Tabela;																	-- inserção de dados em tabela temporária
																							-- Abre 1ª tabela (HTML)
																							-- colunas da primeira linha - títulos (HTML)
		SET @vBody =
		'	<h3>Informações da Instância</h3>
					<table border=1 cellpadding=2>										
						<tr>
							<th>Nome NetBIOS</th>
							<th>Nome da Instância</th>
							<th>Edição</th>
							<th>Versão</th>													
							<th>Level</th>
							<th>Online desde</th>
							<th>Qtde de dias online</th>
						</tr>';
																						
		SET @vBody = @vBody +																 -- segunda linha com os dados (HTML)
		(								
			select
				'<tr>'+
				'<td>'+CONVERT(NVARCHAR,t.netbios_name)+'</td>'+
				'<td>'+CONVERT(NVARCHAR,server_name)+'</td>'+
				'<td>'+CONVERT(NVARCHAR,edition)+'</td>'+									
				'<td>'+CONVERT(NVARCHAR,version)+'</td>'+
				'<td>'+CONVERT(NVARCHAR,level)+'</td>'+
				'<td>'+CONVERT(NVARCHAR,online_since)+'</td>'+
				'<td>'+CONVERT(NVARCHAR,uptime_days)+'</td>'+
				'</tr>'
			from dbo.#Tabela t
		)
		SET @vBody = @vBody + '</table>';													-- Fecha 1ª tabela (HTML)

		-- *** Parte 2: Log de error do SQL
		DECLARE
			@Qt INT = 0,
			@Loop INT = 1;

		DECLARE @LogSQL1 TABLE
		(	Seq INT IDENTITY(1,1),
			LogDate DATETIME,
			ProcessInfo VARCHAR(50),
			Text VARCHAR(4000)
		);
		INSERT INTO @LogSql1 exec sp_readerrorlog;											 -- inserção de dados na variável tipo table

		-- Tabela para somente erros
		DECLARE @LogSQL2 TABLE
		(	Seq INT IDENTITY(1,1),
			LogDate DATETIME,
			ProcessInfo VARCHAR(50),
			Text VARCHAR(4000)
		);
		INSERT INTO @LogSQL2
			SELECT TOP 30
				LogDate, ProcessInfo, Text													 -- inserção de dados em outra variável do tipo table
			FROM @LogSQL1 l
			WHERE l.Text LIKE '%erro%'										
			ORDER BY 1 DESC;

		SET @Qt = @@ROWCOUNT;
		SET @vBody = @vBody +																 -- Abre 2ª tabela - títulos (HTML)
			'<br><br>
				<h3>Últimos 30 registros contendo a palavra erro no Log de Erros do SQL Server</h3>
					<table border=1 cellpadding=2>
						<tr>
							<th>Data do Log</th>										     
							<th>Processo</th>
							<th>Texto</th>
						</tr>';

		WHILE @Loop <= @Qt
			BEGIN
				SET @vBody = @vBody +
				(
					SELECT
						'<tr>'+
						'<td>'+CONVERT(VARCHAR,LogDate)+'</td>'+
						'<td>'+CONVERT(VARCHAR,ProcessInfo)+'</td>'+						 -- inserção de dados a partir da 2ª linha (HTML)
						'<td>'+CONVERT(NVARCHAR(4000),Text)+'</td>'+
						'</tr>'
					FROM @LogSQL2 t
					WHERE t.Seq = @Loop
				);
				SET @Loop = @Loop +1;	
			END;

		SET @vBody = @vBody + '</table>';													 -- Fecha 2ª tabela (HTML)

		-- últimos 30 registros
		DECLARE @LogSQL3 TABLE
		(	Seq INT IDENTITY(1,1),
			LogDate DATETIME,
			ProcessInfo VARCHAR(50),
			Text VARCHAR(4000)
		);
		INSERT INTO @LogSQL3
			SELECT TOP 30
				LogDate, ProcessInfo, Text
			FROM @LogSQL1 l																	 -- inserção de dados em variável do tipo table
			ORDER BY 1 DESC;

		SET @Qt = @@ROWCOUNT;
		SET @Loop = 1;	
		SET @vBody = @vBody +																 -- Abre 3ª tabela - títulos (HTML)
			'<br><br>
				<h3>Últimos 30 registros do Log de Erros do SQL Server</h3>
					<table border=1 cellpadding=2>
						<tr>																 
							<th>Data do Log</th>
							<th>Processo</th>
							<th>Texto</th>
						</tr>';

		WHILE @Loop <= @Qt
			BEGIN
				SET @vBody = @vBody +
				(
					SELECT
						'<tr>'+
						'<td>'+CONVERT(VARCHAR,LogDate)+'</td>'+
						'<td>'+CONVERT(VARCHAR,ProcessInfo)+'</td>'+						 -- inserção de dados a partir da 2ª linha (HTML)
						'<td>'+CONVERT(VARCHAR(4000),Text)+'</td>'+
						'</tr>'
					FROM @LogSQL3 t
					WHERE t.Seq = @Loop
				);
				SET @Loop = @Loop + 1;	
			END;

		SET @vBody = @vBody + '</table>';													 -- Fecha 3ª tabela (HTML)

		-- *** Parte 3: Tamanho dos discos
		DECLARE @vFixed_Drives_Free_Space_Table AS TABLE 
		(	drive_letter VARCHAR (5), 
			free_space_mb BIGINT, 
			Seq INT IDENTITY(1,1));
		INSERT INTO @vFixed_Drives_Free_Space_Table
		(
			drive_letter
			,free_space_mb
		)
		EXEC master.dbo.xp_fixeddrives;														 -- inserção de dados em varável table

		SET @Qt = @@ROWCOUNT;
		SET @Loop = 1;

		SET @vBody = @vBody +																 -- Abre 4ª tabela - títulos (HTML)
			'<br><br>
				<h3>Espaço livre nas unidades de disco</h3>									 
					<table border=1 cellpadding=2>
						<tr>
							<th>Unidade</th>
							<th>Espaço Livre</th>
						</tr>';

		WHILE @Loop <= @Qt
			BEGIN
				SET @vBody = @vBody +
				(
					SELECT
						'<tr>'+
						'<td>'+CONVERT(VARCHAR,t.drive_letter)+'</td>'+						-- inserção de dados a partir da 2ª linha (HTML)
						'<td>'+	CONVERT(VARCHAR, t.free_space_mb) + ' Mb' + ' -> '
					 + CONVERT(VARCHAR, cast(t.free_space_mb /1024 as decimal(15,2))) + ' Gb'	 
					 +'</td>'+
						'</tr>'
					FROM @vFixed_Drives_Free_Space_Table t
					WHERE t.Seq = @Loop
				);
				SET @Loop = @Loop + 1;	
			END;

		SET @vBody = @vBody + '</table>';													 -- Fecha 4ª tabela (HTML)


		-- *** Parte 4: tamanho das databases
		CREATE TABLE #Tamanhos
		(
			Seq INT IDENTITY,
			Banco VARCHAR(50),
			ArquivoDeDados_EspacoReservadoEmDisco_MB DECIMAL(15,2), 
			ArquivoDeDados_EspacoUsado_MB DECIMAL(15,2), 
			ArquivoDeDados_EspacoLivre_MB DECIMAL(15,2)
		);
																							 -- inserção de dados em tabela temporária
		EXEC sp_MSforeachdb 'USE ?
		INSERT INTO #Tamanhos
		(	
			Banco
			, ArquivoDeDados_EspacoReservadoEmDisco_MB
			, ArquivoDeDados_EspacoUsado_MB										 
			, ArquivoDeDados_EspacoLivre_MB
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
			Seq INT IDENTITY,
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
			, t.ArquivoDeDados_EspacoReservadoEmDisco_MB									 -- inserção de dados na variável do tipo table
			, t.ArquivoDeDados_EspacoUsado_MB
			, t.ArquivoDeDados_EspacoLivre_MB
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

		DROP TABLE #Tamanhos;

		SET @vBody = @vBody +																  -- Abre 5ª tabela - títulos (HTML)
			'<br><br>
				<h3>Tamanho dos Bancos de Dados de Usuário</h3>
					<table border=1 cellpadding=2>											
						<tr>
							<th>Banco</th>
							<th>Arquivo de Dados - Espaço Reservado em Disco</th>
							<th>Espaço Usado (dados)</th>
							<th>Espaço Livre (dados)</th>
							<th>Arquivo de Log - Espaço Reservado em Disco</th>
							<th>Espaço Usado (log)</th>
							<th>Espaço Livre (log)</th>
						</tr>';
		
		SELECT @Qt = COUNT(*) FROM @Tamanhos t;
		SET @Loop = 1;

		WHILE @Loop <= @Qt
			BEGIN
				SET @vBody = @vBody +
				(
					SELECT
						'<tr>'+																 -- inserção de dados a partir da 2ª linha (HTML)
						'<td>'+ Banco +'</td>'+
						'<td>'+CONVERT(VARCHAR(60),t.ArquivoDeDados_EspacoReservadoEmDisco_MB) + ' Mb' + ' -> '
								+ CONVERT( VARCHAR(60),cast((t.ArquivoDeDados_EspacoReservadoEmDisco_MB / 1024) as decimal(15,2)) ) 
								+ ' Gb'	+'</td>'+

						'<td>'+CONVERT(VARCHAR(60),t.ArquivoDeDados_EspacoUsado_MB) + ' Mb' + ' -> ' 
								+ CONVERT(VARCHAR(60),cast((t.ArquivoDeDados_EspacoUsado_MB /1024) as decimal(15,2)) ) 
								+ ' Gb'  +'</td>'+

						'<td>'+CONVERT(VARCHAR(60),t.ArquivoDeDados_EspacoLivre_MB) + ' Mb' + ' -> '
								+ CONVERT(VARCHAR(60),cast((t.ArquivoDeDados_EspacoLivre_MB /1024) as decimal(15,2)) ) 
								+ ' Gb' +'</td>'+

						'<td>'+CONVERT(VARCHAR(60),t.ArquivoDeLog_EspacoReservadoEmDisco_MB) + ' Mb' + ' -> '
								+ CONVERT(VARCHAR(60),cast((t.ArquivoDeLog_EspacoReservadoEmDisco_MB /1024) as decimal(15,2)) ) 
								+ ' Gb' +'</td>'+

						'<td>'+CONVERT(VARCHAR(60),t.ArquivoDeLog_EspacoUsado_MB) + ' Mb' + ' -> '
								+ CONVERT(VARCHAR(60),cast((t.ArquivoDeLog_EspacoUsado_MB /1024) as decimal(15,2)) )
								+ ' Gb' +'</td>'+

						'<td>'+CONVERT(VARCHAR(60),t.ArquivoDeLog_EspacoLivre_MB) + ' Mb' + ' -> '
								+ CONVERT(VARCHAR(60),cast((t.ArquivoDeLog_EspacoLivre_MB /1024) as decimal(15,2)) )
								+ ' Gb' +'</td>'+
						'</tr>'
					FROM @Tamanhos t
					WHERE t.Seq = @Loop
				);
				SET @Loop = @Loop + 1;	
			END;

		SET @vBody = @vBody + '</table>';													 -- Fecha 5ª tabela (HTML)

		-- *** Parte 5: TempDB Size
		SET @vBody = @vBody +																 -- Abre 6ª tabela (HTML)
			'<br><br>
				<h3>Espaço no banco de dados interno TempDB</h3>
					<table border=1 cellpadding=2>											 							
						<tr>
							<th>Páginas Livres (tamanho por página é 8Kb sendo 128 Pág./Mb)</th>
							<th>Espaço Livre</th>
						</tr>';

			SET @vBody = @vBody +
			(
				SELECT
					'<tr>'+																	 -- inserção de dados na segunda linha (HTML)
					'<td>'+CONVERT(VARCHAR(20),SUM(unallocated_extent_page_count))+'</td>'+
					'<td>'+CONVERT(VARCHAR(20),CAST(SUM(unallocated_extent_page_count)/128.0 AS decimal(15,2))) + ' Mb' + ' -> '
						  +CONVERT(VARCHAR(20),CAST(SUM((unallocated_extent_page_count)/128.0)/1024 AS decimal(15,2))) + ' Gb' + '</td>'+
					'</tr>'
				FROM sys.dm_db_file_space_usage			
			);
		SET @vBody = @vBody + '</table>';													 -- Fecha 6ª tabela (HTML)

		--- *** Parte 6: Last backup with success
		SET @vBody = @vBody +																 -- Abre 7ª tabela - títulos (HTML)
			'<br><br>
				<h3>Últimos Backups Realizados</h3>
					<table border=1 cellpadding=2>											 
						<tr>
							<th>Banco</th>
							<th>Descrição Opcional do Backup</th>
							<th>Modelo de Recovery</th>
							<th>Data e Hora de Início</th>
							<th>Idade em dias</th>
							<th>Tamanho do Backup em MB</th>
							<th>Tipo</th>
							<th>Arquivo</th>
						</tr>';
		DECLARE @Backups TABLE
		(
			seq INT identity(1,1),
			database_name NVARCHAR(128),
			server_name NVARCHAR(128),
			name  NVARCHAR(128),
			recovery_model  NVARCHAR(60),
			backup_start_date DATETIME,
			days_ago VARCHAR(15),
			backup_size_mb VARCHAR(15),
			type char(1),
			backup_type varchar(21),
			physical_device_name nvarchar(260)
		);

		INSERT INTO @Backups																 -- inserção de dados na variável do tipo table
			select
				s.database_name
				, s.server_name
				, ISNULL(s.name,'')
				, s.recovery_model
				, s.backup_start_date
				,REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (15), CONVERT (MONEY, DATEDIFF (DAY, s.backup_start_date, GETDATE ())), 1)), 4, 15)) AS days_ago
				,REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (15), CONVERT (MONEY, ROUND (s.backup_size/1048576.0, 0)), 1)), 4, 15)) AS backup_size_mb
				, s.type
				,(CASE
					WHEN s.type = 'D' THEN 'Database'
					WHEN s.type = 'F' THEN 'File Or Filegroup'
					WHEN s.type = 'G' THEN 'Differential File'
					WHEN s.type = 'I' THEN 'Differential Database'
					WHEN s.type = 'L' THEN 'Log'
					WHEN s.type = 'P' THEN 'Partial'
					WHEN s.type = 'Q' THEN 'Differential Partial'
					ELSE 'N/A'
					END) AS backup_type
				, f.physical_device_name
			from msdb.dbo.backupset s INNER JOIN msdb.dbo.backupmediafamily f 
					ON s.media_set_id = f.media_set_id
			WHERE s.backup_set_id =
									(	SELECT TOP 1 a.backup_set_id
										FROM msdb.dbo.backupset a 
										WHERE a.database_name = s.database_name
										ORDER BY a.backup_set_id DESC	)
			ORDER BY s.database_name;

		SELECT @Qt = @@ROWCOUNT;
		SET @Loop = 1;

		WHILE @Loop <= @Qt
			BEGIN
				SET @vBody = @vBody +
				(
				select
					'<tr>'+																	-- inserção de dados a partir da 2ª linha (HTML)
					'<td>'+CONVERT(VARCHAR(128),database_name)+'</td>'+
					'<td>'+CONVERT(VARCHAR(128),name)+'</td>'+
					'<td>'+CONVERT(VARCHAR(60),recovery_model)+'</td>'+
					'<td>'+CONVERT(VARCHAR(20),backup_start_date, 13)+'</td>'+
					'<td>'+CONVERT(VARCHAR(10),days_ago)+'</td>'+
					'<td>'+CONVERT(VARCHAR(10),backup_size_mb)+'</td>'+
					'<td>'+CONVERT(VARCHAR(25),backup_type)+'</td>'+
					'<td>'+CONVERT(VARCHAR(260),physical_device_name)+'</td>'+
					'</tr>'
				from @Backups
				WHERE seq = @Loop
				);
				SET @Loop = @Loop +1;
			END;
		SET @vBody = @vBody + '</table>';													-- Fecha 7ª tabela (HTML)

		-- *** Parte 7: status execution jobs
		SET @vBody = @vBody +																-- Abre 8ª tabela (HTML)
			'<br><br>
				<h3>Status da Última Execução dos Jobs</h3>
					<table border=1 cellpadding=2>											
						<tr>
							<th>Nome</th>
							<th>Status</th>
							<th>Mensagem</th>						
							<th>Data e Hora da Execução</th>
						</tr>';
		DECLARE @Jobs TABLE
		(
			Seq INT IDENTITY,
			name SYSNAME,
			status VARCHAR(50),
			message NVARCHAR(4000),		
			data_hora datetime	
		);
		INSERT INTO @Jobs																    -- inserção de dados numa variável do tipo table
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
			, IntegraTICravil.Management.fn_ConverteDatetimeJobs(h.run_date, h.run_time)
		FROM msdb.dbo.sysjobs j
		CROSS APPLY
		(	SELECT TOP 1 h.run_date,
						 h.run_time,
						 h.run_status,
						 h.message
			from msdb.dbo.sysjobhistory h
			WHERE h.step_id = 0
			AND h.job_id = j.job_id 
			ORDER BY h.instance_id DESC
		) h
		ORDER BY name;

		SELECT @Qt = @@ROWCOUNT;
		SET @Loop = 1;

		WHILE @Loop <= @Qt
			BEGIN
				SET @vBody = @vBody +
				(
				select
					'<tr>'+
					'<td>'+CONVERT(VARCHAR(128),j.name)+'</td>'+
					'<td>'+CONVERT(VARCHAR(50),j.status)+'</td>'+							-- inserção de dados a partir da 2ª linha (HTML)
					'<td>'+CONVERT(NVARCHAR(4000),message)+'</td>'+				
					'<td>'+CONVERT(VARCHAR(30),j.data_hora,113)+'</td>'+
					'</tr>'
				from @Jobs j
				WHERE seq = @Loop
				);
				SET @Loop = @Loop + 1;
			END;
		SET @vBody = @vBody + '</table>';													-- Fecha 8ª tabela (HTML)


		-- *** Envia
		if @ExibirApenasHtml = 0
			exec msdb.dbo.sp_send_dbmail
				@profile_name =     'Cravil_ERP',
				@recipients =		'suporte@cravil.com.br', 
				@subject =			@vSubject,
				@body =				@vBody,
				@body_format =		'HTML';
		-- *** Exibe como HTML ao invés de enviar por e-mail
		else 
		SELECT @vBody;

		-- *** Final: elimina tabelas temporárias
		IF OBJECT_ID('tempdb.dbo.#Tamanhos') IS NOT NULL
			DROP TABLE #Tamanhos;
		IF OBJECT_ID('tempdb.dbo.#Tabela') IS NOT NULL
			DROP TABLE #Tabela;
	END
GO


