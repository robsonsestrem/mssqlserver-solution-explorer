DECLARE @DB_USers TABLE
(DBName sysname, 
[Schema] varchar(max),
[Object] varchar(max),
[permissions_type] varchar(max),
[permission_name] varchar(max),
[permission_state] varchar(max),
state_desc varchar(max),
permissionsql varchar(max),
UserName sysname, LoginType sysname, AssociatedRole varchar(max),create_date datetime,modify_date datetime)

INSERT @DB_USers
EXEC sp_MSforeachdb 
'use [?]
SELECT Distinct ''?'' AS DB_Name,
sys.schemas.name as [Schema]
, sys.objects.name as [Object]
, sys.database_permissions.type as permissions_type
, sys.database_permissions.permission_name as permission_name 
, sys.database_permissions.state as permission_state 
, sys.database_permissions.state_desc as state_desc 
, state_desc + '' '' + permission_name 
+ '' on [''+ sys.schemas.name + ''].['' + sys.objects.name 
+ ''] to ['' + prin.name + '']'' 
COLLATE LATIN1_General_CI_AS AS permissionsql
, case prin.name when ''dbo'' then prin.name + '' (''+ (select distinct SUSER_SNAME(owner_sid) from master.sys.databases where name =''?'') + '')'' else prin.name end AS UserName,
prin.type_desc AS LoginType,
isnull(USER_NAME(mem.role_principal_id),'''') AS AssociatedRole ,prin.create_date,prin.modify_date
FROM sys.database_permissions 
LEFT JOIN sys.objects ON sys.database_permissions.major_id = sys.objects.object_id 
LEFT JOIN sys.schemas ON sys.objects.schema_id = sys.schemas.schema_id 
LEFT JOIN sys.database_principals prin ON sys.database_permissions.grantee_principal_id = prin.principal_id 
LEFT OUTER JOIN sys.database_role_members mem ON prin.principal_id=mem.member_principal_id
WHERE prin.sid IS NOT NULL and prin.sid NOT IN (0x00) and
prin.is_fixed_role <> 1 AND prin.name NOT LIKE ''##%'' ORDER BY 1, 2, 3, 5'

SELECT dbname,
username ,
logintype ,
create_date ,
modify_date, 
[Schema], 
[Object], 
[permissions_type], 
[permission_name], 
[permission_state], 
state_desc, permissionsql, 
STUFF((SELECT distinct ',' + CONVERT(VARCHAR(500),associatedrole) 
FROM @DB_USers user2
WHERE user1.DBName=user2.DBName AND user1.UserName=user2.UserName 

FOR XML PATH('')),1,1,'') AS Permissions_user 
FROM @DB_USers user1 
GROUP BY dbname,username,logintype ,create_date,modify_date,[Schema],
[Object],[permissions_type],[permission_name],[permission_state],state_desc, permissionsql 
ORDER BY modify_date

 