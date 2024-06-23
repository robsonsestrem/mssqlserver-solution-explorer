-- Escolha a base de dados para criar o Script
USE BancoDados

/*
Instrução de utilização:

	-- Alterar para o profile do seu servidor:
	@profile_name = 'MSSQLServer', 

	--Alterar para o e-mail que você quer enviar o alerta
	@recipients =	'seue-mail@seudominio.com',

*/

GO

/*******************************************************************************************************************************
--	Tabela de controle que será utilizada para armazenar o Historico dos Alertas.
*******************************************************************************************************************************/

CREATE TABLE [dbo].[Alerta] (
	[Id_Alerta]		INT IDENTITY PRIMARY KEY,
	[Nm_Alerta]		VARCHAR(200),
	[Ds_Mensagem]	VARCHAR(2000),
	[Fl_Tipo]		TINYINT,						-- 0: CLEAR / 1: ALERTA
	[Dt_Alerta]		DATETIME DEFAULT(GETDATE())
)

GO

/*******************************************************************************************************************************
--	ALERTA: PROCESSO BLOQUEADO
*******************************************************************************************************************************/

CREATE PROCEDURE [dbo].[stpAlerta_Processo_Bloqueado]
AS
BEGIN
	SET NOCOUNT ON

	-- Declara as variaveis
	DECLARE	@Subject VARCHAR(500), @Fl_Tipo TINYINT, @Qtd_Segundos INT, @Consulta VARCHAR(8000), @Importance AS VARCHAR(6), @Dt_Atual DATETIME,
			@EmailBody VARCHAR(MAX), @AlertaLockHeader VARCHAR(MAX), @AlertaLockTable VARCHAR(MAX), @EmptyBodyEmail VARCHAR(MAX),
			@AlertaLockRaizHeader VARCHAR(MAX), @AlertaLockRaizTable VARCHAR(MAX), @Qt_Tempo_Lock INT, @Qt_Tempo_Raiz_Lock INT

	-- Quantidade em Minutos
	SELECT	@Qt_Tempo_Lock		= 2,	-- Query que esta sendo bloqueada (rodando a mais de 2 minutos)
			@Qt_Tempo_Raiz_Lock	= 1		-- Query que esta gerando o lock (rodando a mais de 1 minuto)

	--------------------------------------------------------------------------------------------------------------------------------
	--	Cria Tabela para armazenar os Dados da SP_WHOISACTIVE
	--------------------------------------------------------------------------------------------------------------------------------
	-- Cria a tabela que ira armazenar os dados dos processos
	IF ( OBJECT_ID('tempdb..#Resultado_WhoisActive') IS NOT NULL )
		DROP TABLE #Resultado_WhoisActive
		
	CREATE TABLE #Resultado_WhoisActive (		
		[dd hh:mm:ss.mss]		VARCHAR(20),
		[database_name]			NVARCHAR(128),		
		[login_name]			NVARCHAR(128),
		[host_name]				NVARCHAR(128),
		[start_time]			DATETIME,
		[status]				VARCHAR(30),
		[session_id]			INT,
		[blocking_session_id]	INT,
		[wait_info]				VARCHAR(MAX),
		[open_tran_count]		INT,
		[CPU]					VARCHAR(MAX),
		[reads]					VARCHAR(MAX),
		[writes]				VARCHAR(MAX),		
		[sql_command]			XML		
	)   
      
	-- Seta a hora atual
	SELECT @Dt_Atual = GETDATE()

	--------------------------------------------------------------------------------------------------------------------------------
	--	Carrega os Dados da SP_WHOISACTIVE
	--------------------------------------------------------------------------------------------------------------------------------
	-- Retorna todos os processos que estão sendo executados no momento
	EXEC [dbo].[sp_WhoIsActive]
			@get_outer_command =	1,
			@output_column_list =	'[dd hh:mm:ss.mss][database_name][login_name][host_name][start_time][status][session_id][blocking_session_id][wait_info][open_tran_count][CPU][reads][writes][sql_command]',
			@destination_table =	'#Resultado_WhoisActive'
				    
	-- Altera a coluna que possui o comando SQL
	ALTER TABLE #Resultado_WhoisActive
	ALTER COLUMN [sql_command] VARCHAR(MAX)
	
	UPDATE #Resultado_WhoisActive
	SET [sql_command] = REPLACE( REPLACE( REPLACE( REPLACE( CAST([sql_command] AS VARCHAR(1000)), '<?query --', ''), '--?>', ''), '&gt;', '>'), '&lt;', '')
	
	-- select * from #Resultado_WhoisActive
	
	-- Verifica se não existe nenhum processo em Execução
	IF NOT EXISTS ( SELECT TOP 1 * FROM #Resultado_WhoisActive )
	BEGIN
		INSERT INTO #Resultado_WhoisActive
		SELECT NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL,NULL
	END

	-- Verifica o último Tipo do Alerta registrado -> 0: CLEAR / 1: ALERTA
	SELECT @Fl_Tipo = [Fl_Tipo]
	FROM [dbo].[Alerta]
	WHERE [Id_Alerta] = (SELECT MAX(Id_Alerta) FROM [dbo].[Alerta] WHERE [Nm_Alerta] = 'Processo Bloqueado' )
	
	/*******************************************************************************************************************************
	--	Verifica se existe algum Processo Bloqueado
	*******************************************************************************************************************************/	
	IF EXISTS	(
					SELECT NULL 
					FROM #Resultado_WhoisActive A
					JOIN #Resultado_WhoisActive B ON A.[blocking_session_id] = B.[session_id]
					WHERE	DATEDIFF(SECOND,A.[start_time], @Dt_Atual) > @Qt_Tempo_Lock * 60			-- A query que está sendo bloqueada está rodando a mais 2 minutos
							AND DATEDIFF(SECOND,B.[start_time], @Dt_Atual) > @Qt_Tempo_Raiz_Lock * 60	-- A query que está bloqueando está rodando a mais de 1 minuto
				)
	BEGIN	-- INICIO - ALERTA
		IF ISNULL(@Fl_Tipo, 0) = 0	-- Envia o Alerta apenas uma vez
		BEGIN
			--------------------------------------------------------------------------------------------------------------------------------
			--	Verifica a quantidade de processos bloqueados
			--------------------------------------------------------------------------------------------------------------------------------
			-- Declara a variavel e retorna a quantidade de Queries Lentas
			DECLARE @QtdProcessosBloqueados INT = (
										SELECT COUNT(*)
										FROM #Resultado_WhoisActive A
										JOIN #Resultado_WhoisActive B ON A.[blocking_session_id] = B.[session_id]
										WHERE	DATEDIFF(SECOND,A.[start_time], @Dt_Atual) > @Qt_Tempo_Lock	* 60
												AND DATEDIFF(SECOND,B.[start_time], @Dt_Atual) > @Qt_Tempo_Raiz_Lock * 60
									)

			DECLARE @QtdProcessosBloqueadosLocks INT = (
										SELECT COUNT(*)
										FROM #Resultado_WhoisActive A
										WHERE [blocking_session_id] IS NOT NULL
									)

			--------------------------------------------------------------------------------------------------------------------------------
			--	Verifica o Nivel dos Locks
			--------------------------------------------------------------------------------------------------------------------------------
			ALTER TABLE #Resultado_WhoisActive
			ADD Nr_Nivel_Lock TINYINT 

			-- Nivel 0
			UPDATE A
			SET Nr_Nivel_Lock = 0
			FROM #Resultado_WhoisActive A
			WHERE blocking_session_id IS NULL AND session_id IN ( SELECT DISTINCT blocking_session_id 
						FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)

			UPDATE A
			SET Nr_Nivel_Lock = 1
			FROM #Resultado_WhoisActive A
			WHERE	Nr_Nivel_Lock IS NULL
					AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 0)

			UPDATE A
			SET Nr_Nivel_Lock = 2
			FROM #Resultado_WhoisActive A
			WHERE	Nr_Nivel_Lock IS NULL
					AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 1)

			UPDATE A
			SET Nr_Nivel_Lock = 3
			FROM #Resultado_WhoisActive A
			WHERE	Nr_Nivel_Lock IS NULL
					AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 2)

			-- Tratamento quando não tem um Lock Raiz
			IF NOT EXISTS(select * from #Resultado_WhoisActive where Nr_Nivel_Lock IS NOT NULL)
			BEGIN
				UPDATE A
				SET Nr_Nivel_Lock = 0
				FROM #Resultado_WhoisActive A
				WHERE session_id IN ( SELECT DISTINCT blocking_session_id 
					FROM #Resultado_WhoisActive WHERE blocking_session_id IS NOT NULL)
          
				UPDATE A
				SET Nr_Nivel_Lock = 1
				FROM #Resultado_WhoisActive A
				WHERE	Nr_Nivel_Lock IS NULL
						AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 0)

				UPDATE A
				SET Nr_Nivel_Lock = 2
				FROM #Resultado_WhoisActive A
				WHERE	Nr_Nivel_Lock IS NULL
						AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 1)

				UPDATE A
				SET Nr_Nivel_Lock = 3
				FROM #Resultado_WhoisActive A
				WHERE	Nr_Nivel_Lock IS NULL
						AND blocking_session_id IN ( SELECT DISTINCT session_id FROM #Resultado_WhoisActive WHERE Nr_Nivel_Lock = 2)
			END

			/*******************************************************************************************************************************
			--	CRIA O EMAIL - ALERTA
			*******************************************************************************************************************************/							
			
			--------------------------------------------------------------------------------------------------------------------------------
			--	ALERTA - HEADER - RAIZ LOCK
			--------------------------------------------------------------------------------------------------------------------------------
			SET @AlertaLockRaizHeader = '<font color=black bold=true size=5>'			            
			SET @AlertaLockRaizHeader = @AlertaLockRaizHeader + '<BR /> TOP 50 - Processos Raiz Lock <BR />'
			SET @AlertaLockRaizHeader = @AlertaLockRaizHeader + '</font>'

			--------------------------------------------------------------------------------------------------------------------------------
			--	ALERTA - BODY - RAIZ LOCK
			--------------------------------------------------------------------------------------------------------------------------------
			SET @AlertaLockRaizTable = CAST( (
				SELECT td =				[Nr_Nivel_Lock]			+ '</td>'
							+ '<td>' +	[Duração]				+ '</td>'
							+ '<td>' +  [database_name]			+ '</td>'
							+ '<td>' +  [login_name]			+ '</td>'
							+ '<td>' +  [host_name]				+ '</td>'
							+ '<td>' +  [start_time]			+ '</td>'
							+ '<td>' +  [status]				+ '</td>'
							+ '<td>' +  [session_id]			+ '</td>'
							+ '<td>' +  [blocking_session_id]	+ '</td>'
							+ '<td>' +  [Wait]					+ '</td>'
							+ '<td>' +  [open_tran_count]		+ '</td>'
							+ '<td>' +  [CPU]					+ '</td>'
							+ '<td>' +  [reads]					+ '</td>'
							+ '<td>' +  [writes]				+ '</td>'
							+ '<td>' +  [sql_command]			+ '</td>'

				FROM (  
						-- Dados da Tabela do EMAIL
						SELECT	TOP 50
								CAST(Nr_Nivel_Lock AS VARCHAR)							AS [Nr_Nivel_Lock],
								ISNULL([dd hh:mm:ss.mss], '-')							AS [Duração], 
								ISNULL([database_name], '-')							AS [database_name],
								ISNULL([login_name], '-')								AS [login_name],
								ISNULL([host_name], '-')								AS [host_name],
								ISNULL(CONVERT(VARCHAR(20), [start_time], 120), '-')	AS [start_time],
								ISNULL([status], '-')									AS [status],
								ISNULL(CAST([session_id] AS VARCHAR), '-')				AS [session_id],
								ISNULL(CAST([blocking_session_id] AS VARCHAR), '-')		AS [blocking_session_id],
								ISNULL([wait_info], '-')								AS [Wait],
								ISNULL(CAST([open_tran_count] AS VARCHAR), '-')			AS [open_tran_count],
								ISNULL([CPU], '-')										AS [CPU],
								ISNULL([reads], '-')									AS [reads],
								ISNULL([writes], '-')									AS [writes],
								ISNULL(SUBSTRING([sql_command], 1, 300), '-')			AS [sql_command]
						FROM #Resultado_WhoisActive
						WHERE Nr_Nivel_Lock IS NOT NULL
						ORDER BY [Nr_Nivel_Lock], [start_time] 
				
					  ) AS D ORDER BY [Nr_Nivel_Lock], [start_time] 
				FOR XML PATH( 'tr' ), TYPE) AS VARCHAR(MAX)
			)   
			      
			-- Corrige a Formatação da Tabela
			SET @AlertaLockRaizTable = REPLACE( REPLACE( REPLACE( @AlertaLockRaizTable, '&lt;', '<'), '&gt;', '>'), '<td>', '<td align = center>')
			
			-- Títulos da Tabela do EMAIL
			SET @AlertaLockRaizTable = 
					'<table cellspacing=2 cellpadding=5 border=3>'    
					+	'<tr>
							<th bgcolor=#0B0B61 width=80><font color=white>Nivel Lock</font></th>
							<th bgcolor=#0B0B61 width=140><font color=white>[dd hh:mm:ss.mss]</font></th>
							<th bgcolor=#0B0B61 width=100><font color=white>Database</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Login</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Host Name</font></th>
							<th bgcolor=#0B0B61 width=200><font color=white>Hora Início</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Status</font></th>
							<th bgcolor=#0B0B61 width=30><font color=white>ID Sessão</font></th>
							<th bgcolor=#0B0B61 width=60><font color=white>ID Sessão Bloqueando</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Wait</font></th>
							<th bgcolor=#0B0B61 width=60><font color=white>Transações Abertas</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>CPU</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Reads</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Writes</font></th>
							<th bgcolor=#0B0B61 width=300><font color=white>Query</font></th>
						</tr>'    
					+ REPLACE( REPLACE( @AlertaLockRaizTable, '&lt;', '<'), '&gt;', '>')   
					+ '</table>'
			
						
			--------------------------------------------------------------------------------------------------------------------------------
			--	ALERTA - HEADER
			--------------------------------------------------------------------------------------------------------------------------------
			SET @AlertaLockHeader = '<font color=black bold=true size=5>'			            
			SET @AlertaLockHeader = @AlertaLockHeader + '<BR /> TOP 50 - Processos executando no Banco de Dados <BR />'
			SET @AlertaLockHeader = @AlertaLockHeader + '</font>'

			--------------------------------------------------------------------------------------------------------------------------------
			--	ALERTA - BODY
			--------------------------------------------------------------------------------------------------------------------------------
			SET @AlertaLockTable = CAST( (
				SELECT td =				[Duração]				+ '</td>'
							+ '<td>' +  [database_name]			+ '</td>'
							+ '<td>' +  [login_name]			+ '</td>'
							+ '<td>' +  [host_name]				+ '</td>'
							+ '<td>' +  [start_time]			+ '</td>'
							+ '<td>' +  [status]				+ '</td>'
							+ '<td>' +  [session_id]			+ '</td>'
							+ '<td>' +  [blocking_session_id]	+ '</td>'
							+ '<td>' +  [Wait]					+ '</td>'
							+ '<td>' +  [open_tran_count]		+ '</td>'
							+ '<td>' +  [CPU]					+ '</td>'
							+ '<td>' +  [reads]					+ '</td>'
							+ '<td>' +  [writes]				+ '</td>'
							+ '<td>' +  [sql_command]			+ '</td>'

				FROM (  
						-- Dados da Tabela do EMAIL
						SELECT	TOP 50
								ISNULL([dd hh:mm:ss.mss], '-')							AS [Duração], 
								ISNULL([database_name], '-')							AS [database_name],
								ISNULL([login_name], '-')								AS [login_name],
								ISNULL([host_name], '-')								AS [host_name],
								ISNULL(CONVERT(VARCHAR(20), [start_time], 120), '-')	AS [start_time],
								ISNULL([status], '-')									AS [status],
								ISNULL(CAST([session_id] AS VARCHAR), '-')				AS [session_id],
								ISNULL(CAST([blocking_session_id] AS VARCHAR), '-')		AS [blocking_session_id],
								ISNULL([wait_info], '-')								AS [Wait],
								ISNULL(CAST([open_tran_count] AS VARCHAR), '-')			AS [open_tran_count],
								ISNULL([CPU], '-')										AS [CPU],
								ISNULL([reads], '-')									AS [reads],
								ISNULL([writes], '-')									AS [writes],
								ISNULL(SUBSTRING([sql_command], 1, 300), '-')			AS [sql_command]
						FROM #Resultado_WhoisActive
						ORDER BY [start_time]

					  ) AS D ORDER BY [start_time] 
				FOR XML PATH( 'tr' ), TYPE) AS VARCHAR(MAX)
			)   
			      
			-- Corrige a Formatação da Tabela
			SET @AlertaLockTable = REPLACE( REPLACE( REPLACE( @AlertaLockTable, '&lt;', '<'), '&gt;', '>'), '<td>', '<td align = center>')
			
			-- Títulos da Tabela do EMAIL
			SET @AlertaLockTable = 
					'<table cellspacing=2 cellpadding=5 border=3>'    
					+	'<tr>
							<th bgcolor=#0B0B61 width=140><font color=white>[dd hh:mm:ss.mss]</font></th>
							<th bgcolor=#0B0B61 width=100><font color=white>Database</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Login</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Host Name</font></th>
							<th bgcolor=#0B0B61 width=200><font color=white>Hora Início</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Status</font></th>
							<th bgcolor=#0B0B61 width=30><font color=white>ID Sessão</font></th>
							<th bgcolor=#0B0B61 width=60><font color=white>ID Sessão Bloqueando</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Wait</font></th>
							<th bgcolor=#0B0B61 width=60><font color=white>Transações Abertas</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>CPU</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Reads</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Writes</font></th>
							<th bgcolor=#0B0B61 width=300><font color=white>Query</font></th>
						</tr>'    
					+ REPLACE( REPLACE( @AlertaLockTable, '&lt;', '<'), '&gt;', '>')   
					+ '</table>'
			              
			--------------------------------------------------------------------------------------------------------------------------------
			-- Insere um Espaço em Branco no EMAIL
			--------------------------------------------------------------------------------------------------------------------------------
			SET @EmptyBodyEmail =	''
			SET @EmptyBodyEmail =
					'<table cellpadding=5 cellspacing=5 border=0>' +
						'<tr>
							<th width=500>               </th>
						</tr>'
						+ REPLACE( REPLACE( ISNULL(@EmptyBodyEmail,''), '&lt;', '<'), '&gt;', '>')
					+ '</table>'

			/*******************************************************************************************************************************
			--	Seta as Variáveis do EMAIL
			*******************************************************************************************************************************/			              
			SELECT	@Importance =	'High',
					@Subject =		'ALERTA: Existe(m) ' + CAST(@QtdProcessosBloqueados AS VARCHAR) + 
									' Processo(s) Bloqueado(s) a mais de ' +  CAST((@Qt_Tempo_Lock) AS VARCHAR) + ' minuto(s)' +
									' e um total de ' + CAST(@QtdProcessosBloqueadosLocks AS VARCHAR) +  ' Lock(s) no Servidor: ' + @@SERVERNAME,
					@EmailBody =	@AlertaLockRaizHeader + @EmptyBodyEmail + @AlertaLockRaizTable + @EmptyBodyEmail
									+ @AlertaLockHeader + @EmptyBodyEmail + @AlertaLockTable + @EmptyBodyEmail
							
			/*******************************************************************************************************************************
			--	ENVIA O EMAIL - ALERTA
			*******************************************************************************************************************************/	
			EXEC [msdb].[dbo].[sp_send_dbmail]
					@profile_name = 'MSSQLServer',
					@recipients =	'seue-mail@seudominio.com',
					@subject =		@Subject,
					@body =			@EmailBody,
					@body_format =	'HTML',
					@importance =	@Importance
					
			/*******************************************************************************************************************************
			-- Insere um Registro na Tabela de Controle dos Alertas -> Fl_Tipo = 1 : ALERTA
			*******************************************************************************************************************************/
			INSERT INTO [dbo].[Alerta] ( [Nm_Alerta], [Ds_Mensagem], [Fl_Tipo] )
			SELECT 'Processo Bloqueado', @Subject, 1			
		END
	END		-- FIM - ALERTA
	ELSE 
	BEGIN	-- INICIO - CLEAR				
		IF @Fl_Tipo = 1
		BEGIN
			/*******************************************************************************************************************************
			--	CRIA O EMAIL - CLEAR
			*******************************************************************************************************************************/

			--------------------------------------------------------------------------------------------------------------------------------
			--	CLEAR - HEADER
			--------------------------------------------------------------------------------------------------------------------------------
			SET @AlertaLockHeader = '<font color=black bold=true size=5>'			            
			SET @AlertaLockHeader = @AlertaLockHeader + '<BR /> Processos executando no Banco de Dados <BR />' 
			SET @AlertaLockHeader = @AlertaLockHeader + '</font>'

			--------------------------------------------------------------------------------------------------------------------------------
			--	CLEAR - BODY
			--------------------------------------------------------------------------------------------------------------------------------
			SET @AlertaLockTable = CAST( (
				SELECT td =				[Duração]				+ '</td>'
							+ '<td>' +  [database_name]			+ '</td>'
							+ '<td>' +  [login_name]			+ '</td>'
							+ '<td>' +  [start_time]			+ '</td>'
							+ '<td>' +  [status]				+ '</td>'
							+ '<td>' +  [session_id]			+ '</td>'
							+ '<td>' +  [blocking_session_id]	+ '</td>'
							+ '<td>' +  [Wait]					+ '</td>'
							+ '<td>' +  [open_tran_count]		+ '</td>'
							+ '<td>' +  [CPU]					+ '</td>'
							+ '<td>' +  [reads]					+ '</td>'
							+ '<td>' +  [writes]				+ '</td>'
							+ '<td>' +  [sql_command]			+ '</td>'

				FROM (  
						-- Dados da Tabela do EMAIL
						SELECT	ISNULL([dd hh:mm:ss.mss], '-')							AS [Duração], 
								ISNULL([database_name], '-')							AS [database_name],
								ISNULL([login_name], '-')								AS [login_name],
								ISNULL(CONVERT(VARCHAR(20), [start_time], 120), '-')	AS [start_time],
								ISNULL([status], '-')									AS [status],
								ISNULL(CAST([session_id] AS VARCHAR), '-')				AS [session_id],
								ISNULL(CAST([blocking_session_id] AS VARCHAR), '-')		AS [blocking_session_id],
								ISNULL([wait_info], '-')								AS [Wait],
								ISNULL(CAST([open_tran_count] AS VARCHAR), '-')			AS [open_tran_count],
								ISNULL([CPU], '-')										AS [CPU],
								ISNULL([reads], '-')									AS [reads],
								ISNULL([writes], '-')									AS [writes],
								ISNULL(SUBSTRING([sql_command], 1, 300), '-')			AS [sql_command]
						FROM #Resultado_WhoisActive
				
					  ) AS D ORDER BY [start_time] 
				FOR XML PATH( 'tr' ), TYPE) AS VARCHAR(MAX)
			)   
			      
			-- Corrige a Formatação da Tabela
			SET @AlertaLockTable = REPLACE( REPLACE( REPLACE( @AlertaLockTable, '&lt;', '<'), '&gt;', '>'), '<td>', '<td align = center>')
			
			-- Títulos da Tabela do EMAIL
			SET @AlertaLockTable = 
					'<table cellspacing=2 cellpadding=5 border=3>'    
					+	'<tr>
							<th bgcolor=#0B0B61 width=140><font color=white>[dd hh:mm:ss.mss]</font></th>
							<th bgcolor=#0B0B61 width=100><font color=white>Database</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Login</font></th>
							<th bgcolor=#0B0B61 width=200><font color=white>Hora Início</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Status</font></th>
							<th bgcolor=#0B0B61 width=30><font color=white>ID Sessão</font></th>
							<th bgcolor=#0B0B61 width=60><font color=white>ID Sessão Bloqueando</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Wait</font></th>
							<th bgcolor=#0B0B61 width=60><font color=white>Transações Abertas</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>CPU</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Reads</font></th>
							<th bgcolor=#0B0B61 width=120><font color=white>Writes</font></th>
							<th bgcolor=#0B0B61 width=300><font color=white>Query</font></th>
						</tr>'    
					+ REPLACE( REPLACE( @AlertaLockTable, '&lt;', '<'), '&gt;', '>')   
					+ '</table>'
			              			
			--------------------------------------------------------------------------------------------------------------------------------
			-- Insere um Espaço em Branco no EMAIL
			--------------------------------------------------------------------------------------------------------------------------------
			SET @EmptyBodyEmail =	''
			SET @EmptyBodyEmail =
					'<table cellpadding=5 cellspacing=5 border=0>' +
						'<tr>
							<th width=500>               </th>
						</tr>'
						+ REPLACE( REPLACE( ISNULL(@EmptyBodyEmail,''), '&lt;', '<'), '&gt;', '>')
					+ '</table>'

			/*******************************************************************************************************************************
			--	Seta as Variáveis do EMAIL
			*******************************************************************************************************************************/
			SELECT	@Importance =	'High',
					@Subject =		'CLEAR: Não existe mais algum Processo Bloqueado a mais de ' + 
									CAST((@Qt_Tempo_Lock) AS VARCHAR) + ' minuto(s) no Servidor: ' + @@SERVERNAME,
					@EmailBody =	@AlertaLockHeader + @EmptyBodyEmail + @AlertaLockTable + @EmptyBodyEmail
							
			/*******************************************************************************************************************************
			--	ENVIA O EMAIL - CLEAR
			*******************************************************************************************************************************/
			EXEC [msdb].[dbo].[sp_send_dbmail]
					@profile_name = 'MSSQLServer',
					@recipients =	'seue-mail@seudominio.com',
					@subject =		@Subject,
					@body =			@EmailBody,
					@body_format =	'HTML',
					@importance =	@Importance

			/*******************************************************************************************************************************
			-- Insere um Registro na Tabela de Controle dos Alertas -> Fl_Tipo = 0 : CLEAR
			*******************************************************************************************************************************/
			INSERT INTO [dbo].[Alerta] ( [Nm_Alerta], [Ds_Mensagem], [Fl_Tipo] )
			SELECT 'Processo Bloqueado', @Subject, 0		
		END		
	END		-- FIM - CLEAR
END