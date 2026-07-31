/*
 *
	OBJETIVO: Scripts de análise e verificação de permissões no SQL Server,
			  utilizando a stored procedure Management.sp_VerifyPermissions
			  para consultar permissões de usuários, databases e objetos,
			  bem como roles de servidor e permissões de sistema.
	PROJETO: mssqlserver-solution-explorer
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
    @Ds_Database = 'INTEGRATICRAVIL',
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
