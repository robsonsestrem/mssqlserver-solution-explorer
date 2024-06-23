-- Reseta as estatísticas
-- DBCC SQLPERF(sys.dm_os_wait_stats,CLEAR); 

-- http://www.davewentzel.com/content/useful-queries
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-dynamic-management-views/sys-dm-exec-query-stats-transact-sql
-- Como os planos estão fora do cache, as estatísticas ficam obsoletas. Isso é realmente apenas para planos ativos.
/****************** MEDIA DE CONSUMO POR OBJETO *****************************/
USE master
GO
SELECT DB_NAME(st.dbid)																																				AS DBName

      , OBJECT_SCHEMA_NAME(objectid,st.dbid)																														AS SchemaName

	  , st.objectid																																					AS [Object_Id]

      , OBJECT_NAME(objectid,st.dbid)																																AS [Object_Name]	

	  , (select Maintenance.Management.fn_FormatIntToThousands( sum(qs.total_worker_time),2))																		AS Total_worker_time

	  , (select Maintenance.Management.fn_FormatIntToMoney( sum(qs.total_worker_time) / sum(qs.execution_count)	))													AS Avg_worker_time

      , (select Maintenance.Management.fn_FormatIntToThousands( max(cp.usecounts),2))																				AS UseCounts

      , (select Maintenance.Management.fn_FormatIntToThousands( sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes),2))					AS Total_IO

      , (select Maintenance.Management.fn_FormatIntToMoney( sum(qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) / (max(cp.usecounts))))	AS Avg_total_IO

      , (select Maintenance.Management.fn_FormatIntToThousands( sum(qs.total_physical_reads),2))																	AS Total_physical_reads

      , (select Maintenance.Management.fn_FormatIntToMoney( sum(qs.total_physical_reads) / (max(cp.usecounts) * 1.0))) 											    AS Avg_physical_read   

      , (select Maintenance.Management.fn_FormatIntToThousands( sum(qs.total_logical_reads),2))																		AS Total_logical_reads

      , (select Maintenance.Management.fn_FormatIntToMoney(sum(qs.total_logical_reads) / (max(cp.usecounts) * 1.0)))												AS Avg_logical_read 

      , (select Maintenance.Management.fn_FormatIntToThousands( sum(qs.total_logical_writes),2))																	AS Total_logical_writes

      , (select Maintenance.Management.fn_FormatIntToMoney( sum(qs.total_logical_writes) / (max(cp.usecounts) * 1.0)))												AS Avg_logical_writes 

	  , (select Maintenance.Management.fn_FormatIntToThousands( sum(qs.total_elapsed_time),2))																		AS Total_elapsed_time

      , (select Maintenance.Management.fn_FormatIntToMoney( sum(qs.total_elapsed_time) / max(cp.usecounts)) )														AS Avg_elapsed_time	  
FROM sys.dm_exec_query_stats qs CROSS APPLY sys.dm_exec_sql_text(qs.plan_handle) st
	 join sys.dm_exec_cached_plans cp on qs.plan_handle = cp.plan_handle
where DB_NAME(st.dbid) is not null 
AND DB_NAME(st.dbid) in ('GesCooper90')--, 'IntegraTICravil', 'TICRAVIL', 'Guru5', 'Guru6', 'rhcravil', 'CooperSystem')
group by DB_NAME(st.dbid),OBJECT_SCHEMA_NAME(objectid,st.dbid), OBJECT_NAME(objectid,st.dbid), st.objectid

--order by 8 desc		-- 8 - VERIFICA MAIOR CONSUMO DE I/O

--OU

--order by 4 desc	-- 4 - VERIFICA MAIOR CONSUMO DE CPU


/*********************************************** TOP TEMPO DE CPU ACUMULADO ***************************************************************************************/
-- O exemplo a seguir retorna informações sobre as cinco principais consultas classificadas pelo tempo médio de CPU. Este exemplo agrega as consultas de acordo com 
-- seu hash de consulta para que as consultas logicamente equivalentes sejam agrupadas pelo consumo cumulativo de recursos.
USE MASTER
GO  
SELECT TOP 20 query_stats.query_hash AS Query Hash,   
    SUM(query_stats.total_worker_time) / SUM(query_stats.execution_count) AS Avg CPU Time,  
    MIN(query_stats.statement_text) AS Statement Text  
FROM   
    (SELECT QS.*,   
    SUBSTRING(ST.text, (QS.statement_start_offset/2) + 1,  
    ((CASE statement_end_offset   
        WHEN -1 THEN DATALENGTH(ST.text)  
        ELSE QS.statement_end_offset END   
            - QS.statement_start_offset)/2) + 1) AS statement_text  
     FROM sys.dm_exec_query_stats AS QS  
     CROSS APPLY sys.dm_exec_sql_text(QS.sql_handle) as ST) as query_stats  
GROUP BY query_stats.query_hash  
ORDER BY 2 DESC;


/*********************************************** Retornando agregados de contagem de linhas para uma consulta ******************************************************/
-- O exemplo a seguir retorna informações agregadas de contagem de linhas (linhas totais, linhas mínimas, linhas máximas e últimas linhas) para consultas.
SELECT qs.execution_count,  
    SUBSTRING(qt.text,qs.statement_start_offset/2 +1,   
                 (CASE WHEN qs.statement_end_offset = -1   
                       THEN LEN(CONVERT(nvarchar(max), qt.text)) * 2   
                       ELSE qs.statement_end_offset end -  
                            qs.statement_start_offset  
                 )/2  
             ) AS query_text, 
			 qt.text,  
     qt.dbid, 
	 DBname= DB_NAME (qt.dbid), 
	 qt.objectid,
	 ObjectName = OBJECT_NAME(qt.objectid),
     qs.total_rows, 
	 qs.last_rows, 
	 qs.min_rows, 
	 qs.max_rows  
FROM sys.dm_exec_query_stats AS qs   
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt   
WHERE qt.text like '%SELECT%'   
AND qt.dbid = 6 -- GESCOOPER90
ORDER BY qs.execution_count DESC; 