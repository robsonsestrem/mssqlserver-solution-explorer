/*
    OBJETIVO: Monitoramento de transações abertas no SQL Server com extração
              do texto T-SQL e plano de execução mais recentes, incluindo
              contagem de transações, bytes de log utilizados e reservados,
              e status da sessão.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://www.sqlskills.com/blogs/paul/script-open-transactions-with-text-and-plans/
*/

-- =======================================================================
-- Transações abertas: identifica transações ativas no banco de dados,
-- extrai o último comando T-SQL executado e seu plano de execução,
-- e filtra sessões que não estão dormindo ou que têm transações abertas
-- =======================================================================

SELECT
    [s_tst].[session_id]
    , [s_er].open_transaction_count
    , [s_es].status
    , [s_es].[login_name] AS [Login Name]
    , DB_NAME(s_tdt.database_id) AS [Database]
    -- Tempo de início da transação no banco de dados
    , [s_tdt].[database_transaction_begin_time] AS [Begin Time]
    -- Quantos registros de log foram gerados pela transação
    , [s_tdt].[database_transaction_log_bytes_used] AS [Log Bytes]
    -- Quanto espaço de log foi reservado caso a transação sofra rollback
    , [s_tdt].[database_transaction_log_bytes_reserved] AS [Log Rsvd]
    -- O último T-SQL executado no contexto da transação
    , [s_est].text AS [Last T-SQL Text]
    -- O último plano de execução executado (apenas para planos em execução)
    , [s_eqp].[query_plan] AS [Last Plan]
FROM sys.dm_tran_database_transactions AS [s_tdt]
INNER JOIN sys.dm_tran_session_transactions AS [s_tst]
    ON [s_tst].[transaction_id] = [s_tdt].[transaction_id]
INNER JOIN sys.[dm_exec_sessions] AS [s_es]
    ON [s_es].[session_id] = [s_tst].[session_id]
INNER JOIN sys.dm_exec_connections AS [s_ec]
    ON [s_ec].[session_id] = [s_tst].[session_id]
LEFT OUTER JOIN sys.dm_exec_requests AS [s_er]
    ON [s_er].[session_id] = [s_tst].[session_id]
CROSS APPLY sys.dm_exec_sql_text([s_ec].[most_recent_sql_handle]) AS [s_est]
OUTER APPLY sys.dm_exec_query_plan([s_er].[plan_handle]) AS [s_eqp]
WHERE [s_es].session_id <> @@SPID
    AND (
        [s_es].[status] <> 'sleeping'
        OR (
            [s_es].[status] = 'sleeping'
            AND [s_er].open_transaction_count > 0
        )
    )
-- Ordenado pelo tempo de início da transação
ORDER BY
    [Begin Time] DESC;
GO

-- =======================================================================
-- Referência: valores possíveis da coluna status
-- =======================================================================
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
