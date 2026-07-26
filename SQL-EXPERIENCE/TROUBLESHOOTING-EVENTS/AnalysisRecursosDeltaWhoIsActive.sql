/*
    OBJETIVO: Executar a procedure sp_WhoIsActive com coleta delta de métricas
              (CPU, leituras, escritas, tempdb, etc.) em um intervalo definido,
              armazenando os resultados na tabela de análise para monitoramento
              de desempenho e consumo de recursos.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- INFORMAÇÕES ADICIONAIS
-- ============================================================
-- Este recurso permite realizar duas coletas de dados em um determinado
-- período de tempo (valor do parâmetro em segundos) e analisar a diferença
-- de alocação de tempdb, leituras, escritas, etc., entre as duas coletas.
-- Ao final dos segundos, são criadas colunas com o sufixo _delta,
-- demonstrando a diferença entre a primeira e a segunda execução.
-- ============================================================

USE YOUR_DATABASE;
GO

DECLARE @saida VARCHAR(MAX);

EXECUTE Management.sp_WhoIsActive
    @filter = 'cravil\cd-05'
  , @filter_type = 'login'                -- Filtrar por: database, program, login, session e host
  , @show_own_spid = 0                    -- Não mostrar minha sessão (1 mostra)
  , @show_system_spids = 1                -- 1 = mostrar sessões internas do SQL Server
  , @show_sleeping_spids = 1              -- 1 = mostra todas as sessões inativas
  , @get_outer_command = 1                -- Para pegar query inteira sql_command
  --, @get_transaction_info = 1           -- Dados escritos no log de transação de cada sessão (DEIXA A CONSULTA DEMORADA)
  , @get_task_info = 2                    -- Métricas de CPU (2) ou disco (1) context_switches
  , @get_locks = 1                        -- Mostra número de locks na coluna Locks
  --, @get_avg_time = 1                   -- Mostra tempo médio de execução por sessão (dd hh:mm:ss.mss) - avg
  , @get_additional_info = 1              -- Definições de comandos SET additional_info
  , @find_block_leaders = 1               -- Mostra sessão em espera por bloqueio (blocked_session_count)
  , @sort_order = '[physical_reads] DESC' -- Ordenação por qualquer campo
  , @get_plans = 2                        -- Plano de execução (testar com 1 também)
  --, @format_output = 0                  -- Altera formatos (texto para XML) e remove colunas
  , @delta_interval = 200                 -- Em segundos
  --, @return_schema = 1                  -- Criador de tabela (bit)
  , @schema = @saida OUTPUT               -- INSERT na variável @saida
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
  , @destination_table = 'YOUR_DATABASE.Management.WhoIsActiveAnalysisDelta' -- INSERT na tabela de análise

-- SELECT @saida;  -- CAPTURA DO SCRIPT DE CREATE
