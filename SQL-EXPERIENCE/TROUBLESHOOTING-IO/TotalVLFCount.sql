---------------------------------------------------------------------------------------------------------------------------
-- Purpose: This query will list the number of virtual log files (VLFs) in each database.
--
-- More Information: https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/
--
-- Note: This query only works on SQL Server 2016 SP2 or newer.

SELECT
  dbs.[name] DBName
, logStats.recovery_model
, logStats.total_vlf_count
--, logStats.* --There is a lot more information here that may be useful.
FROM
  sys.databases dbs
    OUTER APPLY
  sys.dm_db_log_stats (dbs.database_id) logStats;


