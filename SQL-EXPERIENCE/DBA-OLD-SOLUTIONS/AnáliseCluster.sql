-------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.sqlserverblogforum.com/2016/11/alwayson-database-not-synchronizing-mode-sql-service-account-change/
-- https://blogs.msdn.microsoft.com/sqlmeditation/2017/05/24/dbmgrpartnercommitpolicysetsyncstate-may-seem-more-mysterious-than-it-actually-is/
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT ep.name, sp2.name AS Grantee, sp.name AS Grantor, p.permission_name, ep.state_desc
FROM sys.server_permissions p 
    INNER JOIN sys.endpoints ep ON p.major_id = ep.endpoint_id
    INNER JOIN sys.server_principals sp ON p.grantor_principal_id = sp.principal_id
    INNER JOIN sys.server_principals sp2 ON p.grantee_principal_id = sp2.principal_id
WHERE p.class_desc = 'ENDPOINT' AND ep.type_desc = 'DATABASE_MIRRORING'
