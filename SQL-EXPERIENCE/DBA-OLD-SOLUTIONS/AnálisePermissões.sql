-- Verifica todas as permissões do usuário 'Usuario_Teste' na instância
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel'
    
    
-- Verifica todas as permissões da tabela 'xxxx' no database 'Protheus_Producao'
EXEC Management.[sp_VerifyPermissions]
    @Ds_Database = 'INTEGRATICRAVIL',
    @Ds_Objeto = 'CadusuariosLogDML'
    

-- Verifica as roles de database do usuário 'Usuario_Teste' em todos os bancos
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 1,
    @Fl_Permissoes_Servidor = 0 -- Não
    
    
-- Verifica as permissões a nível de Database do usuário 'Usuario_Teste'
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- Não
    
    
-- Verifica as permissões do database 'Protheus_Producao' para todos os usuários
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = NULL, -- varchar(100)
    @Ds_Database = 'gescooper90', -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- Não
    
    
-- Verifica as permissões a nível de sistema da instância
EXEC Management.[sp_VerifyPermissions]
    @Nr_Tipo_Permissao = 4
    
   
-- Verifica os membros de roles de sistema da instância
EXEC Management.[sp_VerifyPermissions]
    @Nr_Tipo_Permissao = 3