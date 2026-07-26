/*
    OBJETIVO: Executar procedimento sp_WhoIsActive para análise de sessões ativas no SQL Server,
              com configuração detalhada de parâmetros para coleta de métricas de desempenho,
              bloqueios, uso de recursos e planos de execução.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- Observação importante sobre conexões fantasmas
-- ============================================================
-- Obs.: sp_WhoIsActive não traz conexões fantasmas -> ###open_tran = 0 E status = sleeping###

-- ============================================================
-- Execução da sp_WhoIsActive com parâmetros configurados
-- ============================================================

-- DECLARE @saida VARCHAR(MAX);

EXECUTE Management.sp_WhoIsActive
    @filter = '35'
    , @filter_type = 'session'                -- filtrar apenas por: database, program, login, session e host.
    , @show_own_spid = 0                      -- 0 = não mostrar minha sessão, 1 mostra
    , @show_system_spids = 1                  -- 0 = não mostrar as sessões internas do sql server, 1 mostra
    , @show_sleeping_spids = 1                -- 0 = não mostrar todas as sessões inativas, 1 mostra
    , @get_outer_command = 1                  -- 1 = pra pegar query inteira sql_command, 0 desativa
    -- , @get_transaction_info = 1            -- 1 = dados escritos no log de transação de cada sessão tran_log_writes (DEIXA A CONSULTA DEMORADA)
    , @get_task_info = 2                      -- 1 = métricas de CPU, ou 2 = métricas de disco context_switches
    , @get_locks = 1                          -- 0 = não mostra nº de locks na coluna Locks, 1 mostra
    -- , @get_avg_time = 1                    -- 0 = não mostra o tempo médio de execução por cada sessão dd hh:mm:ss.mss (avg), 1 mostra
    , @get_additional_info = 1                -- 1 = ativa definições de comandos SET additional_info, 0 desativa
    , @find_block_leaders = 1                 -- 0 = não mostra sessão em espera por causa de bloqueio bloqued_session_count, 1 mostra
    , @sort_order = '[cpu] desc'              -- ordenação por qualquer campo
    , @get_plans = 1                          -- plano de execução, existe opções 1 ou 2, mais garantido com 1
    -- , @format_output = 0                   -- muda formatos, tipo texto pra xml e tira colunas também
    -- , @return_schema = 1                   -- criador de tabela
    -- , @schema = @saida OUTPUT              -- insert na variável @saida
    , @output_column_list = '
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
';
-- , @destination_table = 'YOUR_DATABASE.Management.WhoIsActiveAnalysis'    -- insert na tabela de análise

-- SELECT @saida;        -- CAPTURA DO SCRIPT DE CREATE

-- ============================================================
-- Documentação dos valores possíveis para a coluna status
-- ============================================================
-- coluna status -> Status do ID do processo. Os valores possíveis são:
-- dormant (inativo) = SQL Server está redefinindo a sessão.
-- running (executando) = a sessão está executando um ou mais lotes. Quando são habilitados MARS (Vários Conjuntos de Resultados Ativos), uma sessão pode executar vários lotes. Para obter mais informações, consulte usando vários conjuntos de resultados ativos (. MARS &41;.
-- Background (plano de fundo) = a sessão está executando uma tarefa em segundo plano, como detecção de deadlock.
-- rollback (reversão) = a sessão tem uma reversão de transação em processo.
-- pending (pendente) = a sessão está aguardando um thread de trabalho se torne disponível.
-- runnable (executável) = a tarefa na sessão está na fila executável de um agendador enquanto aguarda para obter um quantum de tempo.
-- spinloop/sleeping = a tarefa na sessão está esperando um spinlock fique livre.
-- suspended (suspenso) = a sessão está aguardando um evento, como e/s, para concluir, em processo de retorno.
