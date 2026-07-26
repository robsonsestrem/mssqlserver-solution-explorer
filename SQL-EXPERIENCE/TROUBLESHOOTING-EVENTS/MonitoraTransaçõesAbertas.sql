/*
    OBJETIVO: Monitoramento de transações abertas no SQL Server, identificando
              transações ativas por sessão com tipo, estado, contagem de
              registros de log, e sessões inativas (sem requisição ativa)
              que mantêm transações abertas.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://www.dirceuresende.com/blog/como-identificar-sessoes-inativas-com-transacoes-abertas-no-sql-server/
*/

-- ============================================================
-- Bloco 1: Transações abertas (requisições) por sessão e banco
-- ============================================================

-- A query abaixo mostra as transações (requisição) que estão abertas
SELECT
    A.session_id
    , A.transaction_id
    , C.name AS database_name
    , B.database_transaction_begin_time
    -- Tipo da transação no banco de dados
    , (
        CASE B.database_transaction_type
            WHEN 1 THEN 'Read/write transaction'
            WHEN 2 THEN 'Read-only transaction'
            WHEN 3 THEN 'System transaction'
        END
    ) AS database_transaction_type
    -- Estado da transação no banco de dados
    , (
        CASE B.database_transaction_state
            WHEN 1 THEN 'A transação não foi inicializada.'
            WHEN 3 THEN 'A transação foi inicializada, mas não gerou log de registro.'
            WHEN 4 THEN 'A transação gerou registros.'
            WHEN 5 THEN 'A transação foi preparada.'
            WHEN 10 THEN 'A transação foi cometida.'
            WHEN 11 THEN 'A transação foi revertida.'
            WHEN 12 THEN 'A transação está sendo cometida. Nesse estado, o registro está sendo gerado, mas não foi materializado ou persistiu.'
        END
    ) AS database_transaction_state
    , B.database_transaction_log_record_count
FROM sys.dm_tran_session_transactions AS A
INNER JOIN sys.dm_tran_database_transactions AS B
    ON A.transaction_id = B.transaction_id
INNER JOIN sys.databases AS C
    ON B.database_id = C.database_id;

-- ============================================================
-- Bloco 2: Sessões (login) inativas com transações abertas
-- ============================================================

-- Todas as sessões (login) que possuem transações abertas,
-- mas não possuem requisição ativa em sys.dm_exec_requests
SELECT
    A.session_id
    , A.login_time
    , A.host_name
    , A.program_name
    , A.login_name
    , A.status
    , A.cpu_time
    , A.memory_usage
    , A.last_request_start_time
    , A.last_request_end_time
    , A.transaction_isolation_level
    , A.lock_timeout
    , A.deadlock_priority
    , A.row_count
    , C.text
FROM sys.dm_exec_sessions AS A WITH(NOLOCK)
INNER JOIN sys.dm_exec_connections AS B WITH(NOLOCK)
    ON A.session_id = B.session_id
CROSS APPLY sys.dm_exec_sql_text(B.most_recent_sql_handle) AS C
WHERE EXISTS (
    SELECT *
    FROM sys.dm_tran_session_transactions AS t WITH(NOLOCK)
    WHERE t.session_id = A.session_id
)
AND NOT EXISTS (
    SELECT *
    FROM sys.dm_exec_requests AS r WITH(NOLOCK)
    WHERE r.session_id = A.session_id
);

-- ============================================================
-- Referência: valores possíveis da coluna status
-- ============================================================
-- dormant  (inativo)          = SQL Server está redefinindo a sessão.
-- running  (executando)       = a sessão está executando um ou mais lotes.
--                               Quando são habilitados MARS (Vários Conjuntos
--                               de Resultados Ativos), uma sessão pode executar
--                               vários lotes.
-- background (plano de fundo) = a sessão está executando uma tarefa em segundo
--                               plano, como detecção de deadlock.
-- rollback (reversão)         = a sessão tem uma reversão de transação em processo.
-- pending  (pendente)         = a sessão está aguardando um thread de trabalho
--                               se torne disponível.
-- runnable (executável)       = a tarefa na sessão está na fila executável de
--                               um agendador enquanto aguarda para obter um
--                               quantum de tempo.
-- spinloop/sleeping           = a tarefa na sessão está esperando um spinlock
--                               fique livre.
-- suspended (suspenso)        = a sessão está aguardando um evento, como e/s,
--                               para concluir, em processo de retorno.
