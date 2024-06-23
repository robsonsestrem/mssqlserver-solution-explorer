use Maintenance
go

create or alter view Management.vw_MonioringLogRecords
with encryption
as

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

