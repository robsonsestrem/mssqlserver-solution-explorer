
/*******************************  INFORMA��ES ADICIONAIS	**************************************************************************************************/
-- Esse recurso interessante serve para que voc� consiga realizar duas coletas de dados em um determinado per�odo de tempo (esse per�odo � o valor do par�metro, 
-- em segundos) e analisar a diferen�a de aloca��o de tempdb, leituras, escritas, etc.. entre as duas coletas realizadas. Ao final dos segundos, ser�o 
-- criadas colunas com o sufixo _delta, demonstrando a diferen�a entre a primeira e a segunda execu��o.
--------------------------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO
--
declare @saida varchar(max)
--
execute Management.sp_WhoIsActive 
  @filter = 'cravil\cd-05'
, @filter_type = 'login'				--filtrar por: database, program, login, session e host

, @show_own_spid = 0					-- n�o mostrar minha sess�o, 1 mostra
, @show_system_spids = 1				-- 1 = mostrar as sess�es internas do sql server
, @show_sleeping_spids = 1				-- 1 = mostra todas as sess�es inativas     
, @get_outer_command = 1				-- pra pegar query inteira sql_command
--, @get_transaction_info = 1			-- dados escritos no log de transa��o de cada sess�o tran_log_writes (DEIXA A CONSULTA DEMORADA)
, @get_task_info = 2					-- m�tricas de CPU, ou 1 m�tricas de disco context_switches
, @get_locks = 1						-- mostra n� de locks na coluna Locks
--, @get_avg_time = 1						-- mostra o tempo m�dio de execu��o por cada sess�o	dd hh:mm:ss.mss (avg)		
, @get_additional_info = 1				-- defini��es de comandos SET additional_info
, @find_block_leaders = 1				-- mostra sess�o em espera por causa de bloqueio bloqued_session_count
, @sort_order = '[physical_reads] desc'	-- ordena��o por qualquer campo
, @get_plans = 2						-- plano de execu��o, testar com 1 tamb�m
--, @format_output = 0					-- muda formatos, tipo texto pra xml e tira colunas tamb�m

, @delta_interval = 200				    -- EM SEGUNDOS

--, @return_schema = 1 -- bit		    -- criador de tabela
, @schema = @saida output				-- insert na vari�vel @saida
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
,@destination_table = 'YOUR_DATABASE.Management.WhoIsActiveAnalysisDelta'	-- insert na tabela de an�lise

--SELECT @saida		-- CAPTURA DO SCRIPT DE CREATE












