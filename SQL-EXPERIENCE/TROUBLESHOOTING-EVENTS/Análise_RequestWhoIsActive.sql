USE YOUR_DATABASE
GO

/*
Obs.: sp_WhoIsActive n�o traz conex�es fantasmas -> ###open_tran = 0 E status = sleeping###
*/
--declare @saida varchar(max)

execute Management.sp_WhoIsActive 

--@filter = '35'
--, @filter_type = 'session'				-- filtrar apenas por: database, program, login, session e host.

 @show_own_spid = 0				    -- 0 = n�o mostrar minha sess�o, 1 mostra
, @show_system_spids = 1				-- 0 = n�o mostrar as sess�es internas do sql server, 1 mostra
, @show_sleeping_spids = 1	 			-- 0 = n�o mostrar todas as sess�es inativas, 1 mostra     
, @get_outer_command = 1				-- 1 = pra pegar query inteira sql_command, 0 desativa
--, @get_transaction_info = 1			-- 1 = dados escritos no log de transa��o de cada sess�o tran_log_writes (DEIXA A CONSULTA DEMORADA)
, @get_task_info = 2					-- 1 = m�tricas de CPU, ou 2 = m�tricas de disco context_switches
, @get_locks = 1						-- 0 = n�o mostra n� de locks na coluna Locks, 1 mostra
--, @get_avg_time = 1					-- 0 = n�o mostra o tempo m�dio de execu��o por cada sess�o	dd hh:mm:ss.mss (avg), 1 mostra		
, @get_additional_info = 1				-- 1 = ativa defini��es de comandos SET additional_info, 0 desativa
, @find_block_leaders = 1				-- 0 = n�o mostra sess�o em espera por causa de bloqueio bloqued_session_count, 1 mostra
, @sort_order = '[cpu] desc'		    -- ordena��o por qualquer campo
, @get_plans = 1						-- plano de execu��o, existe op��es 1 ou 2, mais garantido com 1
--, @format_output = 0					-- muda formatos, tipo texto pra xml e tira colunas tamb�m

--, @return_schema = 1 -- bit		    -- criador de tabela
--, @schema = @saida output				-- insert na vari�vel @saida
--
, @output_column_list = 
'
[status]
, [dd hh:mm:ss.mss]
, [session_id]
, [login_name]
, [host_name]
, [database_name]
, [CPU]
, [context_switches]
, [physical_io]
, [physical_reads]
, [reads]
, [writes]
, [used_memory]
, [tempdb_allocations]
, [tempdb_current]
, [tasks]
, [open_tran_count]
, [wait_info]
, [locks]
, [blocking_session_id]
, [blocked_session_count]
, [program_name]
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
--,@destination_table = 'YOUR_DATABASE.Management.WhoIsActiveAnalysis'	-- insert na tabela de an�lise

--SELECT @saida		-- CAPTURA DO SCRIPT DE CREATE

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- coluna status -> Status do ID do processo. Os valores poss�veis s�o:
-----------------------------------------------------------------------------------------------------------------------------------------------------
 --dormant  (inativo) = SQL Server est� redefinindo a sess�o.

 --running (executando) = a sess�o est� executando um ou mais lotes. Quando s�o habilitados MARS (V�rios Conjuntos de Resultados Ativos), uma sess�o pode executar v�rios lotes. Para obter mais informa��es, consulte usando v�rios conjuntos de resultados ativos (. MARS &41;.

 --Background (plano de fundo) = a sess�o est� executando uma tarefa em segundo plano, como detec��o de deadlock.

 --rollback (revers�o) = a sess�o tem uma revers�o de transa��o em processo.

 --pending (pendente) = a sess�o est� aguardando um thread de trabalho se torne dispon�vel.

 --runnable (execut�vel) = a tarefa na sess�o est� na fila execut�vel de um agendador enquanto aguarda para obter um quantum de tempo.

 --spinloop/sleeping = a tarefa na sess�o est� esperando um spinlock fique livre.

 --suspended (suspenso) = a sess�o est� aguardando um evento, como e/s, para concluir, em processo de retorno.
