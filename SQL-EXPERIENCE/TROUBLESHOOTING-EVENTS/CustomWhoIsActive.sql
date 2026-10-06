/*
    OBJETIVO: Execução customizada da stored procedure sp_WhoIsActive
              para monitoramento de atividade em tempo real no SQL Server,
              com coleta de planos de execução, comandos externos,
              informações adicionais e lista customizada de colunas de saída.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    http://whoisactive.com/docs/
    https://github.com/amachanic/sp_whoisactive
*/

-- ============================================================
-- Monitoramento de atividade em tempo real via sp_WhoIsActive
-- ============================================================

-- Parâmetros ativos: configuração da coleta de dados de sessões
EXECUTE sp_WhoIsActive
    @show_own_spid = 0
    , @show_system_spids = 0
    , @show_sleeping_spids = 1
    , @get_outer_command = 1
    -- Parâmetros opcionais (comentados): descomentar conforme necessidade
    --, @filter = 'P_YOUR_DATABASE'
    --, @filter_type = 'database'
    --, @get_task_info = 2
    --, @get_locks = 1
    , @get_additional_info = 1
    --, @find_block_leaders = 1
    --, @sort_order = '[cpu] desc'
    , @get_plans = 1
    , @output_column_list = '[additional_info], [status], [dd hh:mm:ss.mss], [session_id], [login_name], [host_name], [database_name], [CPU], [context_switches], [physical_io], [physical_reads], [reads], [writes], [used_memory], [tempdb_allocations], [tempdb_current], [tasks], [open_tran_count], [wait_info], [locks], [blocking_session_id], [blocked_session_count] [program_name], [start_time], [login_time], [collection_time], [percent_complete], [request_id], [sql_text], [sql_command], [additional_info], [query_plan]'
;

-- Comando auxiliar: encerrar sessão específica com status de progresso
-- KILL 399 WITH STATUSONLY
