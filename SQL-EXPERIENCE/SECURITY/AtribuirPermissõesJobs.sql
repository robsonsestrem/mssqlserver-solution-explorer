-- PASSO 1: Verificar/Criar o LOGIN 'YOUR_OBJECT' no servidor (se ainda não existir)
-- Execute no contexto do banco de dados master
USE [master];
GO

IF NOT EXISTS (SELECT name FROM sys.server_principals WHERE name = N'YOUR_OBJECT')
BEGIN
    CREATE LOGIN [YOUR_OBJECT] WITH PASSWORD = N'SuaSenhaForteAqui', DEFAULT_DATABASE = [master], CHECK_EXPIRATION = ON, CHECK_POLICY = ON;
    PRINT 'Login [YOUR_OBJECT] criado com sucesso.';
END
ELSE
BEGIN
    PRINT 'Login [YOUR_OBJECT] já existe.';
END
GO

-- PASSO 2: Criar o USER 'YOUR_OBJECT' no banco de dados msdb e mapeá-lo ao LOGIN (se ainda não existir)
-- Execute no contexto do banco de dados msdb
USE [msdb];
GO

IF NOT EXISTS (SELECT name FROM sys.database_principals WHERE name = N'YOUR_OBJECT' AND type = 'S') -- 'S' para SQL User
BEGIN
    CREATE USER [YOUR_OBJECT] FOR LOGIN [YOUR_OBJECT];
    PRINT 'Usuário [YOUR_OBJECT] criado no msdb.';
END
ELSE
BEGIN
    PRINT 'Usuário [YOUR_OBJECT] já existe no msdb.';
END
GO

-- PASSO 3: Atribuir a role apropriada ao usuário 'YOUR_OBJECT' no msdb
-- É crucial que o usuário seja membro de SQLAgentUserRole para gerenciar Jobs.
IF NOT EXISTS (SELECT 1 FROM sys.database_role_members r JOIN sys.database_principals p ON r.member_principal_id = p.principal_id WHERE p.name = N'YOUR_OBJECT' AND r.role_principal_id = DATABASE_PRINCIPAL_ID('SQLAgentUserRole'))
BEGIN
    PRINT 'Atribuindo SQLAgentUserRole ao YOUR_OBJECT...';
    EXEC msdb.dbo.sp_addrolemember @rolename = N'SQLAgentUserRole', @membername = N'YOUR_OBJECT';
    PRINT 'SQLAgentUserRole atribuída.';
END
ELSE
BEGIN
    PRINT 'SQLAgentUserRole já atribuída ao YOUR_OBJECT.';
END
GO

-- PASSO 4: Conceder a permissão EXECUTE específica para sp_help_targetserver
-- Isso é necessário para que o SSMS funcione corretamente ao criar ou gerenciar Jobs.
GRANT EXECUTE ON OBJECT::dbo.sp_help_targetserver TO [YOUR_OBJECT];
GO

PRINT 'Permissão EXECUTE em sp_help_targetserver concedida para o usuário [YOUR_OBJECT].';
GO


/******************************** UTILIZADO EM PRODUÇÃO ********************************/
------------------------------------------------------------------------------------------------------
-- Concedido permissão a nível de usuário
-- Acesso básico para gerenciar e executar APENAS SEUS PRÓPRIOS JOBS.
-- É a role mais comum para usuários que precisam de autonomia sobre seus Jobs.
------------------------------------------------------------------------------------------------------
USE [msdb];
GO

-- Concede a permissão EXECUTE na stored procedure sp_help_targetserver para o usuário 'YOUR_OBJECT'
GRANT EXECUTE ON OBJECT::dbo.sp_help_targetserver TO [YOUR_OBJECT];
GO

PRINT 'Permissão EXECUTE concedida na sp_help_targetserver para o usuário [YOUR_OBJECT].';
GO

PRINT 'Atribuindo SQLAgentUserRole ao YOUR_OBJECT...';
EXEC msdb.dbo.sp_addrolemember @rolename = N'SQLAgentUserRole', @membername = N'YOUR_OBJECT';
PRINT 'SQLAgentUserRole atribuída.';
GO

-- Para remover uma role (se necessário no futuro):
-- USE [msdb];
-- GO
-- EXEC msdb.dbo.sp_droprolemember @rolename = N'SQLAgentUserRole', @membername = N'YOUR_OBJECT';
-- GO










