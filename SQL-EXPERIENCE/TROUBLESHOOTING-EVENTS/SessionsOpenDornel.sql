/*
	OBJETIVO: Listar transações ativas no SQL Server com informações detalhadas sobre
			  cada sessão, incluindo estado da transação, uso de log, consumo de recursos
			  (CPU, I/O, memória) e o texto da consulta em execução.
              Traz toda e qualquer sessão aberta.
	PROJETO: mssqlserver-solution-explorer
*/
SELECT
      SessionTrans.session_id                                                         AS [SPID]
    , SessionTrans.enlist_count                                                       AS [Active Requests]
    , ActiveTrans.transaction_id                                                      AS [ID]
    , ActiveTrans.name                                                                AS [Name]
    , ActiveTrans.transaction_begin_time                                              AS [Start Time]
    , CASE ActiveTrans.transaction_type
          WHEN 1
          THEN 'Read/Write'
          WHEN 2
          THEN 'Read-Only'
          WHEN 3
          THEN 'System'
          WHEN 4
          THEN 'Distributed'
          ELSE 'Unknown - ' + CONVERT(VARCHAR(20), ActiveTrans.transaction_type)
      END                                                                             AS [Transaction Type]
    , CASE ActiveTrans.transaction_state
          WHEN 0
          THEN 'Uninitialized'
          WHEN 1
          THEN 'Not Yet Started'
          WHEN 2
          THEN 'Active'
          WHEN 3
          THEN 'Ended (Read-Only)'
          WHEN 4
          THEN 'Committing'
          WHEN 5
          THEN 'Prepared'
          WHEN 6
          THEN 'Committed'
          WHEN 7
          THEN 'Rolling Back'
          WHEN 8
          THEN 'Rolled Back'
          ELSE 'Unknown - ' + CONVERT(VARCHAR(20), ActiveTrans.transaction_state)
      END                                                                             AS [State]
    , CASE ActiveTrans.dtc_state
          WHEN 0
          THEN NULL
          WHEN 1
          THEN 'Active'
          WHEN 2
          THEN 'Prepared'
          WHEN 3
          THEN 'Committed'
          WHEN 4
          THEN 'Aborted'
          WHEN 5
          THEN 'Recovered'
          ELSE 'Unknown - ' + CONVERT(VARCHAR(20), ActiveTrans.dtc_state)
      END                                                                             AS [Distributed State]
    , DB.Name                                                                         AS [Database]
    , DBTrans.database_transaction_begin_time                                         AS [DB Begin Time]
    , CASE DBTrans.database_transaction_type
          WHEN 1
          THEN 'Read/Write'
          WHEN 2
          THEN 'Read-Only'
          WHEN 3
          THEN 'System'
          ELSE 'Unknown - ' + CONVERT(VARCHAR(20), DBTrans.database_transaction_type)
      END                                                                             AS [DB Type]
    , CASE DBTrans.database_transaction_state
          WHEN 1
          THEN 'Uninitialized'
          WHEN 3
          THEN 'No Log Records'
          WHEN 4
          THEN 'Log Records'
          WHEN 5
          THEN 'Prepared'
          WHEN 10
          THEN 'Committed'
          WHEN 11
          THEN 'Rolled Back'
          WHEN 12
          THEN 'Committing'
          ELSE 'Unknown - ' + CONVERT(VARCHAR(20), DBTrans.database_transaction_state)
      END                                                                             AS [DB State]
    , DBTrans.database_transaction_log_record_count                                   AS [Log Records]
    , DBTrans.database_transaction_log_bytes_used / 1024                              AS [Log KB Used]
    , DBTrans.database_transaction_log_bytes_reserved / 1024                          AS [Log KB Reserved]
    , DBTrans.database_transaction_log_bytes_used_system / 1024                       AS [Log KB Used (System)]
    , DBTrans.database_transaction_log_bytes_reserved_system / 1024                   AS [Log KB Reserved (System)]
    , DBTrans.database_transaction_replicate_record_count                             AS [Replication Records]
    , ExecReqs.command                                                                AS [Command Type]
    , ExecReqs.total_elapsed_time                                                     AS [Elapsed Time]
    , ExecReqs.cpu_time                                                               AS [CPU Time]
    , ExecReqs.wait_type                                                              AS [Wait Type]
    , ExecReqs.wait_time                                                              AS [Wait Time]
    , ExecReqs.wait_resource                                                          AS [Wait Resource]
    , ExecReqs.reads                                                                  AS [Reads]
    , ExecReqs.logical_reads                                                          AS [Logical Reads]
    , ExecReqs.writes                                                                 AS [Writes]
    , SessionTrans.open_transaction_count                                             AS [Open Transactions]
    , open_resultset_count                                                            AS [Open Result Sets]
    , ExecReqs.row_count                                                              AS [Rows Returned]
    , ExecReqs.nest_level                                                             AS [Nest Level]
    , ExecReqs.granted_query_memory                                                   AS [Query Memory]
    , SUBSTRING
      (
          SQLText.text
        , ExecReqs.statement_start_offset / 2
        , (
              CASE ExecReqs.statement_end_offset
                  WHEN -1
                  THEN LEN(CONVERT(NVARCHAR(MAX), SQLText.text)) * 2
                  ELSE ExecReqs.statement_end_offset
              END - ExecReqs.statement_start_offset
          ) / 2
      )                                                                               AS query_text
FROM sys.dm_tran_active_transactions                                                  AS ActiveTrans
INNER JOIN sys.dm_tran_database_transactions                                          AS DBTrans
        ON DBTrans.transaction_id = ActiveTrans.transaction_id
INNER JOIN sys.databases                                                              AS DB
        ON DB.database_id = DBTrans.database_id
LEFT JOIN sys.dm_tran_session_transactions                                            AS SessionTrans
        ON SessionTrans.transaction_id = ActiveTrans.transaction_id
LEFT JOIN sys.dm_exec_requests                                                        AS ExecReqs
        ON ExecReqs.session_id = SessionTrans.session_id
        AND ExecReqs.transaction_id = SessionTrans.transaction_id
OUTER APPLY sys.dm_exec_sql_text(ExecReqs.sql_handle)                                 AS SQLText
-- WHERE SessionTrans.session_id IS NOT NULL                                          -- Descomente para ver apenas processos de usuário (exclui internos do SQL)
-- AND DBTrans.database_transaction_state = 4                                        -- Filtro opcional para transações com log records
