/*
 *
	OBJETIVO: Análise de permissões em endpoints de Database Mirroring/Always On,
			  identificando grantors, grantees e tipos de permissão configurados
			  para diagnóstico de problemas de sincronização entre réplicas.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.sqlserverblogforum.com/2016/11/alwayson-database-not-synchronizing-mode-sql-service-account-change/
 *	https://blogs.msdn.microsoft.com/sqlmeditation/2017/05/24/dbmgrpartnercommitpolicysetsyncstate-may-seem-more-mysterious-than-it-actually-is/
 */
-- ============================================================
-- Análise de Permissões em Endpoints de Database Mirroring
-- ============================================================
-- Consulta as permissões configuradas em endpoints do tipo DATABASE_MIRRORING
-- para identificar quem concedeu, quem recebeu e qual o estado da permissão
SELECT
    ep.name AS EndpointName
    ,sp2.name AS Grantee
    ,sp.name AS Grantor
    ,p.permission_name AS PermissionName
    ,ep.state_desc AS StateDesc
FROM sys.server_permissions AS p
INNER JOIN sys.endpoints AS ep
    ON p.major_id = ep.endpoint_id
INNER JOIN sys.server_principals AS sp
    ON p.grantor_principal_id = sp.principal_id
INNER JOIN sys.server_principals AS sp2
    ON p.grantee_principal_id = sp2.principal_id
WHERE p.class_desc = 'ENDPOINT'
    AND ep.type_desc = 'DATABASE_MIRRORING'
