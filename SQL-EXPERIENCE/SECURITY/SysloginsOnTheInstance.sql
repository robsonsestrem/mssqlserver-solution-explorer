---------------------------------------------------------------------------------------------------------------------------
-- Purpose: This query will show all sysadmins on the instance.  Is there anyone here that doesn't belong?
--
-- More Information: https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/
--

SELECT 
  [name]
FROM 
  sys.syslogins
WHERE 
  IS_SRVROLEMEMBER ('sysadmin',name) = 1;



