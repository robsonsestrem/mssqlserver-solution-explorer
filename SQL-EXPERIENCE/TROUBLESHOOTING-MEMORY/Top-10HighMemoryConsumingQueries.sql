                --Top 10 high memory consuming queries
                SELECT TOP 10 OBJECT_NAME(qt.objectid) AS 'SP Name', 
                              SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1, ((CASE qs.statement_end_offset
                                                                                            WHEN -1
                                                                                            THEN DATALENGTH(qt.text)
                                                                                            ELSE qs.statement_end_offset
                                                                                        END - qs.statement_start_offset) / 2) + 1) AS statement_text, 
                              total_logical_reads, 
                              qs.execution_count AS 'Execution Count', 
                              total_logical_reads / COALESCE(qs.execution_count, 1) AS 'AvgLogicalReads', 
                              qs.execution_count / COALESCE(DATEDIFF(minute, qs.creation_time, GETDATE()), 1) AS 'Calls/minute', 
                              qs.total_worker_time / COALESCE(qs.execution_count, 1) AS 'AvgWorkerTime', 
                              qs.total_worker_time AS 'TotalWorkerTime', 
                              qs.total_elapsed_time / COALESCE(qs.execution_count, 1) AS 'AvgElapsedTime', 
                              qs.total_logical_writes, 
                              qs.max_logical_reads, 
                              qs.max_logical_writes, 
                              qs.total_physical_reads, 
                              DB_NAME(qt.dbid) AS database_name, 
                              qp.query_plan
                FROM sys.dm_exec_query_stats AS qs
                     CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
                     OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
                WHERE qt.dbid IS NOT NULL
                ORDER BY total_logical_reads DESC --, DB_NAME(qt.dbid)


--SELECT * FROM sys.databases 