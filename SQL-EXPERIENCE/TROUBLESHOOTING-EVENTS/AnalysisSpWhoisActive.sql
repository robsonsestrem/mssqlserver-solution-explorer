/*
    OBJETIVO: Demonstrar o uso da stored procedure sp_WhoIsActive
              para monitoramento de sessões ativas, bloqueios, consumo
              de recursos, planos de execução e outras métricas de
              desempenho, com exemplos de parâmetros e filtros.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://www.dirceuresende.com/blog/sql-server-utilizando-a-sp-whoisactive-para-identificar-locks-blocks-queries-lentas-queries-em-execucao-e-muito-mais/
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- EXECUÇÃO PADRÃO
-- ============================================================

EXECUTE Management.sp_WhoIsActive;


-- ============================================================
-- PARÂMETROS BÁSICOS
-- ============================================================

-- Mostrar minha própria sessão
EXECUTE Management.sp_WhoIsActive
    @show_own_spid = 1;

-- Mostrar sessões internas do SQL Server
EXECUTE Management.sp_WhoIsActive
    @show_system_spids = 1;

-- Mostrar todas as sessões inativas
EXECUTE Management.sp_WhoIsActive
    @show_sleeping_spids = 1;

-- Consultar ajuda da procedure
EXECUTE Management.sp_WhoIsActive
    @help = 1;


-- ============================================================
-- EXECUÇÕES FILTRADAS
-- ============================================================

-- Por session_id
EXECUTE Management.sp_WhoIsActive
    @filter = '57'
  , @filter_type = 'session';

-- Por login
EXECUTE Management.sp_WhoIsActive
    @filter = 'cravil\ti-02'
  , @filter_type = 'login';

-- Por programa
EXECUTE Management.sp_WhoIsActive
    @filter = 'net'
  , @filter_type = 'program';

-- Por banco de dados
EXECUTE Management.sp_WhoIsActive
    @filter = 'YOUR_DATABASE'
  , @filter_type = 'database';

-- Por hostname
EXECUTE Management.sp_WhoIsActive
    @filter = 'W-NFE'
  , @filter_type = 'host';


-- ============================================================
-- INFORMAÇÕES ADICIONAIS
-- ============================================================

-- Query completa do batch (substitui sql_text)
EXECUTE Management.sp_WhoIsActive
    @get_full_inner_text = 1;

-- Plano de execução (1 = plano atual, 2 = plano completo)
EXECUTE Management.sp_WhoIsActive
    @get_plans = 2;

-- Comando completo (nova coluna sql_command)
EXECUTE Management.sp_WhoIsActive
    @get_outer_command = 1;

-- Informações de transação (tran_log_writes)
EXECUTE Management.sp_WhoIsActive
    @get_transaction_info = 1;

-- Informações de task (1 = waits, 2 = completo com physical_io, context_switches, tasks)
EXECUTE Management.sp_WhoIsActive
    @get_task_info = 2;

-- Exibir bloqueios (coluna Locks)
EXECUTE Management.sp_WhoIsActive
    @get_locks = 1;

-- Tempo médio de execução (coluna dd hh:mm:ss.mss (avg))
EXECUTE Management.sp_WhoIsActive
    @get_avg_time = 1;

-- Informações adicionais (XML com SET options e block_info)
EXECUTE Management.sp_WhoIsActive
    @get_additional_info = 1;

-- Identificar líderes de bloqueio (coluna blocked_session_count)
EXECUTE Management.sp_WhoIsActive
    @find_block_leaders = 1;


-- ============================================================
-- PERSONALIZAÇÃO DA SAÍDA
-- ============================================================

-- Selecionar colunas específicas
EXECUTE Management.sp_WhoIsActive
    @output_column_list = '[session_id], [login_name], [program_name], [hostname], [sql_text]';

-- Ordenar resultados
EXECUTE Management.sp_WhoIsActive
    @sort_order = '[session_id] ASC';

-- Formatar saída (0 = XML como texto, 1 = variável, 2 = fixo)
EXECUTE Management.sp_WhoIsActive
    @format_output = 0;


-- ============================================================
-- GERAR SCRIPT DE CREATE TABLE
-- ============================================================

DECLARE @saida VARCHAR(MAX);

EXECUTE Management.sp_WhoIsActive
    @return_schema = 1
  , @get_plans = 2
  , @format_output = 0
  , @schema = @saida OUTPUT;

SELECT
    @saida;


-- ============================================================
-- INSERIR RESULTADO EM TABELA
-- ============================================================

IF (OBJECT_ID('tempdb.dbo.#whoisactive') IS NOT NULL)
    DROP TABLE #whoisactive;

CREATE TABLE tempdb.dbo.#whoisactive
(
    [dd hh:mm:ss.mss]       VARCHAR(8000)   NULL
  , [session_id]            SMALLINT        NOT NULL
  , [sql_text]              XML             NULL
  , [login_name]            NVARCHAR(128)   NOT NULL
  , [wait_info]             NVARCHAR(4000)  NULL
  , [CPU]                   VARCHAR(30)     NULL
  , [tempdb_allocations]    VARCHAR(30)     NULL
  , [tempdb_current]        VARCHAR(30)     NULL
  , [blocking_session_id]   SMALLINT        NULL
  , [reads]                 VARCHAR(30)     NULL
  , [writes]                VARCHAR(30)     NULL
  , [physical_reads]        VARCHAR(30)     NULL
  , [used_memory]           VARCHAR(30)     NULL
  , [status]                VARCHAR(30)     NOT NULL
  , [open_tran_count]       VARCHAR(30)     NULL
  , [percent_complete]      VARCHAR(30)     NULL
  , [host_name]             NVARCHAR(128)   NULL
  , [database_name]         NVARCHAR(128)   NULL
  , [program_name]          NVARCHAR(128)   NULL
  , [start_time]            DATETIME        NOT NULL
  , [login_time]            DATETIME        NULL
  , [request_id]            INT             NULL
  , [collection_time]       DATETIME        NOT NULL
);

EXECUTE Management.sp_WhoIsActive
    @destination_table = 'tempdb.dbo.#whoisactive';

SELECT
    *
FROM
    #whoisactive;
