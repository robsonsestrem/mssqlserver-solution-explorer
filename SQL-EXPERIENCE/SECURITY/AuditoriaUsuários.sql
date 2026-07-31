/*
 *
	OBJETIVO: Auditoria de permissões de usuários em todos os databases do servidor,
			  coletando informações de schemas, objetos, tipos de permissão e roles
			  associadas, consolidando os dados em um result set único para análise.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/relational-databases/system-catalog-views/sys-database-permissions-transact-sql
 */
-- ============================================================
-- Auditoria de Permissões de Usuários
-- ============================================================

-- Declaração da table variable para armazenar os dados de auditoria
DECLARE @DB_USers TABLE
(
    DBName SYSNAME
    ,[Schema] VARCHAR(MAX)
    ,[Object] VARCHAR(MAX)
    ,permissions_type VARCHAR(MAX)
    ,permission_name VARCHAR(MAX)
    ,permission_state VARCHAR(MAX)
    ,state_desc VARCHAR(MAX)
    ,permissionsql VARCHAR(MAX)
    ,UserName SYSNAME
    ,LoginType SYSNAME
    ,AssociatedRole VARCHAR(MAX)
    ,create_date DATETIME
    ,modify_date DATETIME
);

-- Inserção dos dados coletados de todos os databases via sp_MSforeachdb
INSERT @DB_USers
EXEC sp_MSforeachdb '
USE [?]
SELECT DISTINCT
    ''?'' AS DB_Name
    ,sys.schemas.name AS [Schema]
    ,sys.objects.name AS [Object]
    ,sys.database_permissions.type AS permissions_type
    ,sys.database_permissions.permission_name AS permission_name
    ,sys.database_permissions.state AS permission_state
    ,sys.database_permissions.state_desc AS state_desc
    ,state_desc + '' '' + permission_name + '' on ['' + sys.schemas.name + ''].['' + sys.objects.name + ''] to ['' + prin.name + '']'' COLLATE LATIN1_General_CI_AS AS permissionsql
    ,CASE prin.name
        WHEN ''dbo'' THEN prin.name + '' ('' + (SELECT DISTINCT SUSER_SNAME(owner_sid) FROM master.sys.databases WHERE name = ''?'') + '')''
        ELSE prin.name
    END AS UserName
    ,prin.type_desc AS LoginType
    ,ISNULL(USER_NAME(mem.role_principal_id), '''') AS AssociatedRole
    ,prin.create_date
    ,prin.modify_date
FROM sys.database_permissions
LEFT JOIN sys.objects
    ON sys.database_permissions.major_id = sys.objects.object_id
LEFT JOIN sys.schemas
    ON sys.objects.schema_id = sys.schemas.schema_id
LEFT JOIN sys.database_principals AS prin
    ON sys.database_permissions.grantee_principal_id = prin.principal_id
LEFT OUTER JOIN sys.database_role_members AS mem
    ON prin.principal_id = mem.member_principal_id
WHERE prin.sid IS NOT NULL
    AND prin.sid NOT IN (0x00)
    AND prin.is_fixed_role <> 1
    AND prin.name NOT LIKE ''##%''
ORDER BY 1, 2, 3, 5';

-- Consulta final consolidando as permissões por usuário com STUFF e FOR XML PATH
SELECT
    dbname
    ,username
    ,logintype
    ,create_date
    ,modify_date
    ,[Schema]
    ,[Object]
    ,permissions_type
    ,permission_name
    ,permission_state
    ,state_desc
    ,permissionsql
    ,STUFF(
        (
            SELECT DISTINCT ',' + CONVERT(VARCHAR(500), associatedrole)
            FROM @DB_USers AS user2
            WHERE user1.DBName = user2.DBName
                AND user1.UserName = user2.UserName
            FOR XML PATH('')
        )
        ,1
        ,1
        ,''
    ) AS Permissions_user
FROM @DB_USers AS user1
GROUP BY
    dbname
    ,username
    ,logintype
    ,create_date
    ,modify_date
    ,[Schema]
    ,[Object]
    ,permissions_type
    ,permission_name
    ,permission_state
    ,state_desc
    ,permissionsql
ORDER BY modify_date;
