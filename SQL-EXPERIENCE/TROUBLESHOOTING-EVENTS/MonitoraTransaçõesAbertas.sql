--Referências: https://www.dirceuresende.com/blog/como-identificar-sessoes-inativas-com-transacoes-abertas-no-sql-server/
---------------------------------------------------------------------------------------------------------------------------------------
--  A query abaixo mostra as transações (requisição) que estão abertas:
---------------------------------------------------------------------------------------------------------------------------------------
SELECT
    A.session_id,
    A.transaction_id,
    C.name AS database_name,
    B.database_transaction_begin_time,
    (CASE B.database_transaction_type
        WHEN 1 THEN 'Read/write transaction'
        WHEN 2 THEN 'Read-only transaction'
        WHEN 3 THEN 'System transaction'
    END) AS database_transaction_type,
    (CASE B.database_transaction_state
        WHEN 1 THEN 'A transação não foi inicializada.'								--The transaction has not been initialized.
        WHEN 3 THEN 'A transação foi inicializada, mas não gerou log de registro.'	--The transaction has been initialized but has not generated any log records.
        WHEN 4 THEN 'A transação gerou registros.'									--The transaction has generated log records.
        WHEN 5 THEN 'A transação foi preparada.'									--The transaction has been prepared.
        WHEN 10 THEN 'A transação foi cometida.'									--The transaction has been committed.
        WHEN 11 THEN 'A transação foi revertida.'									--The transaction has been rolled back.
        WHEN 12 THEN 'A transação está sendo cometida. Nesse estado, o registro está sendo gerado, mas não foi materializado ou persistiu.'
																					--The transaction is being committed. In this state the log 
																					--record is being generated, but it has not been materialized or persisted.
    END) AS database_transaction_state,
    B.database_transaction_log_record_count

FROM
    sys.dm_tran_session_transactions A
    JOIN sys.dm_tran_database_transactions B ON A.transaction_id = B.transaction_id
    JOIN sys.databases C ON B.database_id = C.database_id 
	

---------------------------------------------------------------------------------------------------------------------------------------
-- Todas as sessões(login) que possuem transações abertas
---------------------------------------------------------------------------------------------------------------------------------------

--SELECT 
--    A.session_id,
--    A.login_time,
--    A.host_name,
--    A.program_name,
--    A.login_name,
--    A.status,
--    A.cpu_time,
--    A.memory_usage,
--    A.last_request_start_time,
--    A.last_request_end_time,
--    A.transaction_isolation_level,
--    A.lock_timeout,
--    A.deadlock_priority,
--    A.row_count,
--    C.text
--FROM 
--    sys.dm_exec_sessions			A	WITH(NOLOCK)
--    JOIN sys.dm_exec_connections		B	WITH(NOLOCK)	ON	A.session_id = B.session_id
--    CROSS APPLY sys.dm_exec_sql_text(most_recent_sql_handle)	C
--WHERE 
--  EXISTS (SELECT * FROM sys.dm_tran_session_transactions AS t WITH(NOLOCK) WHERE t.session_id = A.session_id)
--  AND NOT EXISTS (SELECT * FROM sys.dm_exec_requests AS r WITH(NOLOCK) WHERE r.session_id = A.session_id)
--ORDER BY A.session_id

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- coluna status -> Status do ID do processo. Os valores possíveis são:
-----------------------------------------------------------------------------------------------------------------------------------------------------
 --dormant  (inativo) = SQL Server está redefinindo a sessão.

 --running (executando) = a sessão está executando um ou mais lotes. Quando são habilitados MARS (Vários Conjuntos de Resultados Ativos), uma sessão pode executar vários lotes. Para obter mais informações, consulte usando vários conjuntos de resultados ativos (. MARS &41;.

 --Background (plano de fundo) = a sessão está executando uma tarefa em segundo plano, como detecção de deadlock.

 --rollback (reversão) = a sessão tem uma reversão de transação em processo.

 --pending (pendente) = a sessão está aguardando um thread de trabalho se torne disponível.

 --runnable (executável) = a tarefa na sessão está na fila executável de um agendador enquanto aguarda para obter um quantum de tempo.

 --spinloop/sleeping = a tarefa na sessão está esperando um spinlock fique livre.

 --suspended (suspenso) = a sessão está aguardando um evento, como e/s, para concluir, em processo de retorno.