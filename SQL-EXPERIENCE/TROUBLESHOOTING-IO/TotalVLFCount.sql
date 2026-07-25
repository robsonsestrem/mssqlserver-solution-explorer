/*
    OBJETIVO: Listar o número de arquivos de log virtuais (VLFs) em cada banco de dados do SQL Server.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/

    NOTA: Esta consulta funciona apenas no SQL Server 2016 SP2 ou superior.
*/

-- Consulta de contagem de VLFs por banco de dados com informações do modelo de recuperação
SELECT 
    dbs.[name] AS DBName
    , logStats.recovery_model
    , logStats.total_vlf_count
    -- , logStats.* -- Há muitas outras informações disponíveis que podem ser úteis
FROM sys.databases AS dbs
OUTER APPLY sys.dm_db_log_stats(dbs.database_id) AS logStats;
