-- Verifica todas as permissões do usuário 'healthmap' na instância
EXEC [sp_verify_permissions]
    @Ds_Usuario = 'healthmap'
    
    
-- Verifica todas as permissões da tabela 'xxxx' no database 'Protheus_Producao'
EXEC [sp_verify_permissions]
    @Ds_Database = 'P_HEALTHMAP_UNIMEDPA',
    @Ds_Objeto = 'ACSPA'
    

-- Verifica as roles de database do usuário 'healthmap' em todos os bancos
EXEC [sp_verify_permissions]
    @Ds_Usuario = 'healthmap', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 1,
    @Fl_Permissoes_Servidor = 0 -- Não
    
    
-- Verifica as permissões a nível de Database do usuário 'healthmap'
EXEC [sp_verify_permissions]
    @Ds_Usuario = 'healthmap', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- Não
    
    
-- Verifica as permissões do database 'P_HEALTHMAP_UNIMEDPA' para todos os usuários
EXEC [sp_verify_permissions]
    @Ds_Usuario = NULL, -- varchar(100)
    @Ds_Database = 'P_HEALTHMAP_UNIMEDPA', -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- Não
    
    
-- Verifica as permissões a nível de sistema da instância
EXEC [sp_verify_permissions]
    @Nr_Tipo_Permissao = 4
    
   
-- Verifica os membros de roles de sistema da instância
EXEC [sp_verify_permissions]
    @Nr_Tipo_Permissao = 3
