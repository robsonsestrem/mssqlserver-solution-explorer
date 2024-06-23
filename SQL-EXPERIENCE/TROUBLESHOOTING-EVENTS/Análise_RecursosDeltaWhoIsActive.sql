
/*******************************  INFORMAÇÕES ADICIONAIS	**************************************************************************************************/
-- Esse recurso interessante serve para que você consiga realizar duas coletas de dados em um determinado período de tempo (esse período é o valor do parâmetro, 
-- em segundos) e analisar a diferença de alocação de tempdb, leituras, escritas, etc.. entre as duas coletas realizadas. Ao final dos segundos, serão 
-- criadas colunas com o sufixo _delta, demonstrando a diferença entre a primeira e a segunda execução.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
--
declare @saida varchar(max)
--
execute Management.sp_WhoIsActive 
  @filter = 'cravil\cd-05'
, @filter_type = 'login'				--filtrar por: database, program, login, session e host

, @show_own_spid = 0					-- não mostrar minha sessão, 1 mostra
, @show_system_spids = 1				-- 1 = mostrar as sessões internas do sql server
, @show_sleeping_spids = 1				-- 1 = mostra todas as sessões inativas     
, @get_outer_command = 1				-- pra pegar query inteira sql_command
--, @get_transaction_info = 1			-- dados escritos no log de transação de cada sessão tran_log_writes (DEIXA A CONSULTA DEMORADA)
, @get_task_info = 2					-- métricas de CPU, ou 1 métricas de disco context_switches
, @get_locks = 1						-- mostra nº de locks na coluna Locks
--, @get_avg_time = 1						-- mostra o tempo médio de execução por cada sessão	dd hh:mm:ss.mss (avg)		
, @get_additional_info = 1				-- definições de comandos SET additional_info
, @find_block_leaders = 1				-- mostra sessão em espera por causa de bloqueio bloqued_session_count
, @sort_order = '[physical_reads] desc'	-- ordenação por qualquer campo
, @get_plans = 2						-- plano de execução, testar com 1 também
--, @format_output = 0					-- muda formatos, tipo texto pra xml e tira colunas também

, @delta_interval = 200				    -- EM SEGUNDOS

--, @return_schema = 1 -- bit		    -- criador de tabela
, @schema = @saida output				-- insert na variável @saida
--
, @output_column_list = 
'
[status]
, [dd hh:mm:ss.mss]
, [login_name]
, [host_name]
, [database_name]
, [CPU]
, [CPU_Delta]
, [context_switches]
, [context_switches_Delta]
, [physical_io]
, [physical_io_Delta]
, [physical_reads]
, [physical_reads_Delta]
, [reads]
, [reads_Delta]
, [writes]
, [writes_Delta]
, [used_memory]
, [used_memory_Delta]
, [tempdb_allocations]
, [tempdb_allocations_Delta]
, [tempdb_current]
, [tempdb_current_Delta]
, [tasks]
, [open_tran_count]
, [wait_info]
, [locks]
, [blocking_session_id]
, [blocked_session_count]
, [program_name]
, [session_id]
, [start_time]
, [login_time]
, [collection_time]
, [percent_complete]
, [request_id]
, [sql_text]
, [sql_command]
, [additional_info]
, [query_plan]
'
,@destination_table = 'Maintenance.Management.WhoIsActiveAnalysisDelta'	-- insert na tabela de análise

--SELECT @saida		-- CAPTURA DO SCRIPT DE CREATE












