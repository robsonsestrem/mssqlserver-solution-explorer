---------------------------------------------------------------------------------------------------------------------------
-- Purpose: This query will build a list of database owners.  Use this query to find owners that do not meet best practices.
-- More Information: https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/

SELECT 
  d.[name] DBName
, sp.[name] OwnerOfDB
FROM 
  sys.databases d
    INNER JOIN 
  sys.server_principals sp ON d.owner_sid = sp.sid;


---------------------------------------------------------------------------------------------------------------------------
-- Purpose: This query will build a list of SQL Server Agent Jobs with their owners.
--          Use this query to find owners that do not meet best practices.
--
-- More Information: https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/
--
-- Note: If a job is owned by a Windows user that is no longer valid, the job will not start.

SELECT 
  sj.[name] DBName
, sp.[name] OwnerOfDB
FROM 
  msdb.dbo.sysjobs sj
    INNER JOIN 
  sys.server_principals sp ON sj.owner_sid = sp.sid;

