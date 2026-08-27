/*
 *
	OBJETIVO: Scripts de análise e verificação de permissões no SQL Server,
			  utilizando a stored procedure Management.sp_VerifyPermissions
			  para consultar permissões de usuários, databases e objetos,
			  bem como roles de servidor e permissões de sistema.
	PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/pt-br/sql/relational-databases/system-catalog-views/sys-database-permissions-transact-sql
 *  https://learn.microsoft.com/pt-br/sql/relational-databases/system-catalog-views/sys-server-permissions-transact-sql
 *	
 */
-- ============================================================
-- Verifica todas as permissões do usuário na instância
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel'

-- ============================================================
-- Verifica todas as permissões da tabela no database especificado
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Ds_Database = 'DBA_PerformanceHub',
    @Ds_Objeto = 'CadusuariosLogDML'

-- ============================================================
-- Verifica as roles de database do usuário em todos os bancos
-- @Nr_Tipo_Permissao = 1 (Database Roles)
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel',
    @Ds_Database = NULL,
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 1,
    @Fl_Permissoes_Servidor = 0

-- ============================================================
-- Verifica as permissões a nível de Database do usuário
-- @Nr_Tipo_Permissao = 2 (Database Permissions)
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel',
    @Ds_Database = NULL,
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0

-- ============================================================
-- Verifica as permissões do database para todos os usuários
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = NULL,
    @Ds_Database = 'YOUR_DATABASE',
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0

-- ============================================================
-- Verifica as permissões a nível de sistema da instância
-- @Nr_Tipo_Permissao = 4 (Server Permissions)
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Nr_Tipo_Permissao = 4

-- ============================================================
-- Verifica os membros de roles de sistema da instância
-- @Nr_Tipo_Permissao = 3 (Server Roles)
-- ============================================================
EXEC Management.[sp_VerifyPermissions]
    @Nr_Tipo_Permissao = 3


-- ===========================================================================
-- Procedure Management.sp_VerifyPermissions
-- Consulta de permissões de usuários e logins em níveis de banco e servidor,
-- incluindo associação usuário x login, roles de banco, permissões de banco,
-- roles de servidor e permissões de servidor.
-- ===========================================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_VerifyPermissions]
(
    @Ds_Usuario VARCHAR(100) = NULL
  , @Ds_Database VARCHAR(100) = NULL
  , @Ds_Objeto VARCHAR(100) = NULL
  , @Nr_Tipo_Permissao SMALLINT = NULL
  , @Fl_Permissoes_Servidor BIT = 1
)
WITH ENCRYPTION
AS
BEGIN
    -- Normalização dos parâmetros de filtro
    SELECT
        @Ds_Usuario = ISNULL(@Ds_Usuario, '')
      , @Ds_Database = ISNULL(@Ds_Database, '')
      , @Ds_Objeto = ISNULL(@Ds_Objeto, '')

    DECLARE @Query VARCHAR(MAX)

    -- ============================================================
    -- Bloco 01: Associação usuário x login
    -- ============================================================
    IF (OBJECT_ID('tempdb..#Users_Logins') IS NOT NULL)
    BEGIN
        DROP TABLE #Users_Logins
    END

    CREATE TABLE #Users_Logins
    (
        Ds_Database VARCHAR(100)
      , Ds_Login VARCHAR(100)
      , Ds_Usuario VARCHAR(100)
    )

    IF (@Nr_Tipo_Permissao = 0 OR @Nr_Tipo_Permissao IS NULL)
    BEGIN
        SET @Query = '
    IF (''?'' = ''' + @Ds_Database + ''' OR ''' + @Ds_Database + ''' = '''')
    BEGIN
        USE [?]
        SELECT
            ''?'' AS Ds_Database
          , C.name AS Ds_Login
          , B.name AS Ds_Usuario
        FROM sys.database_principals AS A WITH(NOLOCK)
        INNER JOIN sys.sysusers AS B WITH(NOLOCK)
            ON A.principal_id = B.uid
        LEFT JOIN sys.syslogins AS C WITH(NOLOCK)
            ON B.sid = C.sid
        WHERE A.type_desc != ''DATABASE_ROLE''
        AND (C.name = ''' + @Ds_Usuario + ''' OR B.name = ''' + @Ds_Usuario + ''' OR ''' + @Ds_Usuario + ''' = '''')
        AND (C.name = ''' + @Ds_Objeto + ''' OR B.name = ''' + @Ds_Objeto + ''' OR ''' + @Ds_Objeto + ''' = '''')
    END'

        INSERT INTO #Users_Logins
        EXEC master.dbo.sp_MSforeachdb @Query
    END

    -- ============================================================
    -- Bloco 02: Permissões em roles de banco de dados
    -- ============================================================
    IF (OBJECT_ID('tempdb..#Database_Roles') IS NOT NULL)
    BEGIN
        DROP TABLE #Database_Roles
    END

    CREATE TABLE #Database_Roles
    (
        Ds_Database VARCHAR(100)
      , Ds_Login VARCHAR(100)
      , Ds_Usuario VARCHAR(100)
      , Ds_Database_Role VARCHAR(100)
    )

    IF (@Nr_Tipo_Permissao = 1 OR @Nr_Tipo_Permissao IS NULL)
    BEGIN
        SET @Query = '
    IF (''?'' = ''' + @Ds_Database + ''' OR ''' + @Ds_Database + ''' = '''')
    BEGIN
        USE [?]
        SELECT
            ''?'' AS Ds_Database
          , D.name AS Ds_Login
          , C.name AS Ds_Usuario
          , B.name AS Ds_Role
        FROM sys.database_role_members AS A WITH(NOLOCK)
        INNER JOIN sys.database_principals AS B WITH(NOLOCK)
            ON A.role_principal_id = B.principal_id
        INNER JOIN sys.sysusers AS C WITH(NOLOCK)
            ON A.member_principal_id = C.uid
        LEFT JOIN sys.syslogins AS D WITH(NOLOCK)
            ON C.sid = D.sid
        WHERE (C.name = ''' + @Ds_Usuario + ''' OR D.name = ''' + @Ds_Usuario + ''' OR ''' + @Ds_Usuario + ''' = '''')
        AND (B.name = ''' + @Ds_Objeto + ''' OR ''' + @Ds_Objeto + ''' = '''')
    END'

        INSERT INTO #Database_Roles
        EXEC master.dbo.sp_MSforeachdb @Query
    END

    -- ============================================================
    -- Bloco 03: Permissões a nível de banco de dados
    -- ============================================================
    IF (OBJECT_ID('tempdb..#Database_Permissions') IS NOT NULL)
    BEGIN
        DROP TABLE #Database_Permissions
    END

    CREATE TABLE #Database_Permissions
    (
        Ds_Database VARCHAR(100)
      , Ds_Tipo_Permissao VARCHAR(60)
      , Ds_Permissao VARCHAR(128)
      , Ds_Operacao VARCHAR(60)
      , Ds_Login_Permissao VARCHAR(100)
      , Ds_Usuario_Permissao VARCHAR(100)
      , Ds_Objeto VARCHAR(100)
    )

    IF (@Nr_Tipo_Permissao = 2 OR @Nr_Tipo_Permissao IS NULL)
    BEGIN
        SET @Query = '
        IF (''?'' = ''' + @Ds_Database + ''' OR ''' + @Ds_Database + ''' = '''')
        BEGIN
            USE [?]
            SELECT
                ''?'' AS Ds_Database
              , A.class_desc AS Ds_Tipo_Permissao
              , A.permission_name AS Ds_Permissao
              , A.state_desc AS Ds_Operacao
              , C.name AS Ds_Login_Permissao
              , B.name AS Ds_Usuario_Permissao
              , D.name AS Ds_Objeto
            FROM sys.database_permissions AS A WITH(NOLOCK)
            INNER JOIN sys.sysusers AS B WITH(NOLOCK)
                ON A.grantee_principal_id = B.uid
            LEFT JOIN sys.syslogins AS C WITH(NOLOCK)
                ON B.sid = C.sid
            LEFT JOIN sys.objects AS D WITH(NOLOCK)
                ON A.major_id = D.object_id
            WHERE A.major_id >= 0
            AND (B.name = ''' + @Ds_Usuario + ''' OR C.name = ''' + @Ds_Usuario + ''' OR ''' + @Ds_Usuario + ''' = '''')
            AND (D.name = ''' + @Ds_Objeto + ''' OR ''' + @Ds_Objeto + ''' = '''')
        END'

        INSERT INTO #Database_Permissions
        EXEC master.dbo.sp_MSforeachdb @Query
    END

    -- ============================================================
    -- Bloco 04: Permissões em roles de sistema
    -- ============================================================
    IF (OBJECT_ID('tempdb..#Server_Roles') IS NOT NULL)
    BEGIN
        DROP TABLE #Server_Roles
    END

    CREATE TABLE #Server_Roles
    (
        Ds_Usuario VARCHAR(100)
      , Ds_Server_Role VARCHAR(100)
    )

    IF ((@Fl_Permissoes_Servidor = 1 AND @Nr_Tipo_Permissao IS NULL) OR @Nr_Tipo_Permissao = 3)
    BEGIN
        SET @Query = '
    SELECT
        B.name AS Ds_Usuario
      , C.name AS Ds_Role
    FROM sys.server_role_members AS A WITH(NOLOCK)
    INNER JOIN sys.server_principals AS B WITH(NOLOCK)
        ON A.member_principal_id = B.principal_id
    INNER JOIN sys.server_principals AS C WITH(NOLOCK)
        ON A.role_principal_id = C.principal_id
    WHERE (B.name = ''' + @Ds_Usuario + ''' OR ''' + @Ds_Usuario + ''' = '''')
    AND (B.name = ''' + @Ds_Objeto + ''' OR ''' + @Ds_Objeto + ''' = '''')'

        INSERT INTO #Server_Roles
        EXEC(@Query)
    END

    -- ============================================================
    -- Bloco 05: Permissões a nível de servidor
    -- ============================================================
    IF (OBJECT_ID('tempdb..#Server_Permissions') IS NOT NULL)
    BEGIN
        DROP TABLE #Server_Permissions
    END

    CREATE TABLE #Server_Permissions
    (
        Ds_Tipo_Permissao VARCHAR(60)
      , Ds_Tipo_Operacao VARCHAR(60)
      , Ds_Permissao VARCHAR(128)
      , Ds_Login VARCHAR(100)
      , Ds_Tipo_Login VARCHAR(100)
    )

    IF ((@Fl_Permissoes_Servidor = 1 AND @Nr_Tipo_Permissao IS NULL) OR @Nr_Tipo_Permissao = 4)
    BEGIN
        SET @Query = '
    SELECT
        A.class_desc AS Ds_Tipo_Permissao
      , A.state_desc AS Ds_Tipo_Operacao
      , A.permission_name AS Ds_Permissao
      , C.name AS Ds_Login
      , B.type_desc AS Ds_Tipo_Login
    FROM sys.server_permissions AS A WITH(NOLOCK)
    INNER JOIN sys.server_principals AS B WITH(NOLOCK)
        ON A.grantee_principal_id = B.principal_id
    LEFT JOIN sys.syslogins AS C WITH(NOLOCK)
        ON B.sid = C.sid
    WHERE (C.name = ''' + @Ds_Usuario + ''' OR ''' + @Ds_Usuario + ''' = '''')
    AND (C.name = ''' + @Ds_Objeto + ''' OR ''' + @Ds_Objeto + ''' = '''')'

        INSERT INTO #Server_Permissions
        EXEC(@Query)
    END

    -- ============================================================
    -- Bloco 06: Definição das saídas
    -- ============================================================
    SELECT
        0 AS Id_Nivel_Permissao
      , 'User_Login' AS Ds_Nivel_Permissao
      , Ds_Database
      , NULL AS Ds_Tipo_Permissao
      , 'LOGIN' AS Ds_Permissao
      , 'GRANT' AS Ds_Operacao
      , Ds_Login
      , Ds_Usuario
      , NULL AS Ds_Objeto
    FROM #Users_Logins

    UNION ALL

    SELECT
        1 AS Id_Nivel_Permissao
      , 'Database_Role' AS Ds_Nivel_Permissao
      , Ds_Database
      , NULL AS Ds_Tipo_Permissao
      , Ds_Database_Role AS Ds_Permissao
      , 'GRANT' AS Ds_Operacao
      , Ds_Login
      , Ds_Usuario
      , NULL AS Ds_Objeto
    FROM #Database_Roles

    UNION ALL

    SELECT
        2 AS Id_Nivel_Permissao
      , 'Database_Permission' AS Ds_Nivel_Permissao
      , Ds_Database
      , Ds_Tipo_Permissao
      , Ds_Permissao
      , Ds_Operacao
      , Ds_Login_Permissao
      , Ds_Usuario_Permissao
      , Ds_Objeto
    FROM #Database_Permissions

    UNION ALL

    SELECT
        3 AS Id_Nivel_Permissao
      , 'Server_Role' AS Ds_Nivel_Permissao
      , NULL AS Ds_Database
      , NULL AS Ds_Tipo_Permissao
      , Ds_Server_Role AS Ds_Permissao
      , 'GRANT' AS Ds_Operacao
      , Ds_Usuario AS Ds_Login
      , NULL AS Ds_Usuario
      , @@SERVERNAME AS Ds_Objeto
    FROM #Server_Roles

    UNION ALL

    SELECT
        4 AS Id_Nivel_Permissao
      , 'Server_Permission' AS Ds_Nivel_Permissao
      , NULL AS Ds_Database
      , Ds_Tipo_Permissao
      , Ds_Permissao
      , Ds_Tipo_Operacao AS Ds_Operacao
      , Ds_Login
      , NULL AS Ds_Usuario
      , @@SERVERNAME AS Ds_Objeto
    FROM #Server_Permissions
    ORDER BY
        1
      , 3
      , 7
      , 8
      , 9
END
GO
