/*
    OBJETIVO: Exibir a utilização de disco de cada volume lógico que abriga pelo menos um arquivo de banco de dados.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://www.mssqltips.com/sqlservertip/6001/ssrs-reportserver-database-overview-and-queries/
*/

-- Consulta de utilização de disco por volume lógico
SELECT DISTINCT
    vs.volume_mount_point
    , vs.file_system_type
    , vs.logical_volume_name
    , vs.total_bytes / 1073741824.0 AS [Total Size (GB)]
    , vs.available_bytes / 1073741824.0 AS [Available Size (GB)]
    , CAST(vs.available_bytes * 100. / vs.total_bytes AS DECIMAL(5, 2)) AS [Space Free %]
FROM sys.master_files AS f
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs;
