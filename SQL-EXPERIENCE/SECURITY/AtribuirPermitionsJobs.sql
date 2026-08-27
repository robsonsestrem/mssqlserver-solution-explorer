/*
 *
	OBJETIVO: Script de atribuição de permissões para gerenciamento de SQL Server Agent Jobs,
			  incluindo criação de LOGIN, USER e atribuição de roles específicas (SQLAgentUserRole)
			  para permitir que usuários gerenciem seus próprios jobs de forma autônoma.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/ssms/agent/sql-server-agent-fixed-database-roles
 */
-- ============================================================
-- Atribuição de Permissões para Jobs do SQL Server Agent
-- ============================================================

-- ============================================================
-- PASSO 1: Verificar/Criar o LOGIN no servidor
-- ============================================================
USE [master]
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.server_principals
    WHERE name = N'YOUR_OBJECT'
)
BEGIN
    CREATE LOGIN [YOUR_OBJECT]
    WITH
        PASSWORD = N'SuaSenhaForteAqui'
        ,DEFAULT_DATABASE = [master]
        ,CHECK_EXPIRATION = ON
        ,CHECK_POLICY = ON;
    PRINT 'Login [YOUR_OBJECT] criado com sucesso.';
END
ELSE
BEGIN
    PRINT 'Login [YOUR_OBJECT] já existe.';
END
GO

-- ============================================================
-- PASSO 2: Criar o USER no banco msdb e mapear ao LOGIN
-- ============================================================
USE [msdb]
GO

IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_principals
    WHERE name = N'YOUR_OBJECT'
    AND type = 'S'
)
BEGIN
    CREATE USER [YOUR_OBJECT] FOR LOGIN [YOUR_OBJECT];
    PRINT 'Usuário [YOUR_OBJECT] criado no msdb.';
END
ELSE
BEGIN
    PRINT 'Usuário [YOUR_OBJECT] já existe no msdb.';
END
GO

-- ============================================================
-- PASSO 3: Atribuir a role SQLAgentUserRole ao usuário
-- ============================================================
IF NOT EXISTS
(
    SELECT 1
    FROM sys.database_role_members AS r
    INNER JOIN sys.database_principals AS p
        ON r.member_principal_id = p.principal_id
    WHERE p.name = N'YOUR_OBJECT'
    AND r.role_principal_id = DATABASE_PRINCIPAL_ID('SQLAgentUserRole')
)
BEGIN
    PRINT 'Atribuindo SQLAgentUserRole ao YOUR_OBJECT...';
    EXEC msdb.dbo.sp_addrolemember
        @rolename = N'SQLAgentUserRole'
        ,@membername = N'YOUR_OBJECT';
    PRINT 'SQLAgentUserRole atribuída.';
END
ELSE
BEGIN
    PRINT 'SQLAgentUserRole já atribuída ao YOUR_OBJECT.';
END
GO

-- ============================================================
-- PASSO 4: Conceder permissão EXECUTE para sp_help_targetserver
-- ============================================================
GRANT EXECUTE
    ON OBJECT::dbo.sp_help_targetserver
    TO [YOUR_OBJECT];
GO

PRINT 'Permissão EXECUTE em sp_help_targetserver concedida para o usuário [YOUR_OBJECT].';
GO

-- ============================================================
-- CONFIGURAÇÃO DE PRODUÇÃO
-- ============================================================
/*
    Concedido permissão a nível de usuário:
    Acesso básico para gerenciar e executar APENAS SEUS PRÓPRIOS JOBS.
    É a role mais comum para usuários que precisam de autonomia sobre seus Jobs.
*/

USE [msdb]
GO

-- Concede permissão EXECUTE na stored procedure sp_help_targetserver
GRANT EXECUTE
    ON OBJECT::dbo.sp_help_targetserver
    TO [YOUR_OBJECT];
GO

PRINT 'Permissão EXECUTE concedida na sp_help_targetserver para o usuário [YOUR_OBJECT].';
GO

-- Atribui a role SQLAgentUserRole
PRINT 'Atribuindo SQLAgentUserRole ao YOUR_OBJECT...';
EXEC msdb.dbo.sp_addrolemember
    @rolename = N'SQLAgentUserRole'
    ,@membername = N'YOUR_OBJECT';
PRINT 'SQLAgentUserRole atribuída.';
GO

-- ============================================================
-- SCRIPT DE REMOÇÃO (para uso futuro, se necessário)
-- ============================================================
/*
USE [msdb]
GO

EXEC msdb.dbo.sp_droprolemember
    @rolename = N'SQLAgentUserRole'
    ,@membername = N'YOUR_OBJECT';
GO
*/
