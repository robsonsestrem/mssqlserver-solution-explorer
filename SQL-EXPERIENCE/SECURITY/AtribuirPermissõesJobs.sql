-- PASSO 1: Verificar/Criar o LOGIN 'healthmap' no servidor (se ainda não existir)
-- Execute no contexto do banco de dados master
USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'healthmap')
BEGIN
    CREATE LOGIN [healthmap] WITH PASSWORD = N'SuaSenhaForteAqui', DEFAULT_DATABASE = [master], CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
    PRINT 'Login [healthmap] criado com sucesso.';
END
ELSE
BEGIN
    PRINT 'Login [healthmap] já existe.';
END
GO

-- PASSO 2: Criar o USER 'healthmap' no banco de dados msdb e mapeá-lo ao LOGIN (se ainda não existir)
-- Execute no contexto do banco de dados msdb
USE [msdb];
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'healthmap' AND type = 'S') -- 'S' para SQL User
BEGIN
    CREATE USER [healthmap] FOR LOGIN [healthmap];
    PRINT 'Usuário [healthmap] criado no msdb.';
END
ELSE
BEGIN
    PRINT 'Usuário [healthmap] já existe no msdb.';
END
GO

-- PASSO 3: Atribuir a role apropriada ao usuário 'healthmap' no msdb
-- É crucial que o usuário seja membro de SQLAgentUserRole para gerenciar Jobs.
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members r JOIN sys.database_principals p ON r.member_principal_id = p.principal_id WHERE p.name = N'healthmap' AND r.role_principal_id = DATABASE_PRINCIPAL_ID('SQLAgentUserRole'))
BEGIN
    PRINT 'Atribuindo SQLAgentUserRole ao healthmap...';
    EXEC msdb.dbo.sp_addrolemember @rolename = N'SQLAgentUserRole', @membername = N'healthmap';
    PRINT 'SQLAgentUserRole atribuída.';
END
ELSE
BEGIN
    PRINT 'SQLAgentUserRole já atribuída ao healthmap.';
END
GO

-- PASSO 4: Conceder a permissão EXECUTE específica para sp_help_targetserver
-- Isso é necessário para que o SSMS funcione corretamente ao criar ou gerenciar Jobs.
GRANT EXECUTE ON OBJECT::dbo.sp_help_targetserver TO [healthmap];
GO

PRINT 'Permissão EXECUTE em sp_help_targetserver concedida para o usuário [healthmap].';
GO


/******************************** UTILIZADO EM PRODUÇÃO ********************************/
------------------------------------------------------------------------------------------------------
-- Concedido permissão a nível de usuário
-- Acesso básico para gerenciar e executar APENAS SEUS PRÓPRIOS JOBS.
-- É a role mais comum para usuários que precisam de autonomia sobre seus Jobs.
------------------------------------------------------------------------------------------------------
USE [msdb];
GO

-- Concede a permissão EXECUTE na stored procedure sp_help_targetserver para o usuário 'healthmap'
GRANT EXECUTE ON OBJECT::dbo.sp_help_targetserver TO [healthmap];
GO

PRINT 'Permissão EXECUTE concedida na sp_help_targetserver para o usuário [healthmap].';
GO

PRINT 'Atribuindo SQLAgentUserRole ao healthmap...';
EXEC msdb.dbo.sp_addrolemember @rolename = N'SQLAgentUserRole', @membername = N'healthmap';
PRINT 'SQLAgentUserRole atribuída.';
GO

-- Para remover uma role (se necessário no futuro):
-- USE [msdb];
-- GO
-- EXEC msdb.dbo.sp_droprolemember @rolename = N'SQLAgentUserRole', @membername = N'healthmap';
-- GO










