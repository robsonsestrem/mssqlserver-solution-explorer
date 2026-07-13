-- Verifica todas as permiss�es do usu�rio 'YOUR_OBJECT' na instância
EXEC [sp_verify_permissions]
    @Ds_Usuario = 'YOUR_OBJECT'
    
    
-- Verifica todas as permiss�es da tabela 'xxxx' no database 'Protheus_Producao'
EXEC [sp_verify_permissions]
    @Ds_Database = 'P_YOUR_DATABASE',
    @Ds_Objeto = 'ACSPA'
    

-- Verifica as roles de database do usu�rio 'YOUR_OBJECT' em todos os bancos
EXEC [sp_verify_permissions]
    @Ds_Usuario = 'YOUR_OBJECT', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 1,
    @Fl_Permissoes_Servidor = 0 -- N�o
    
    
-- Verifica as permiss�es a n�vel de Database do usu�rio 'YOUR_OBJECT'
EXEC [sp_verify_permissions]
    @Ds_Usuario = 'YOUR_OBJECT', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- N�o
    
    
-- Verifica as permissões do database 'P_YOUR_DATABASE' para todos os usuários
EXEC [sp_verify_permissions]
    @Ds_Usuario = NULL, -- varchar(100)
    @Ds_Database = 'P_YOUR_DATABASE', -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- N�o
    
    
-- Verifica as permiss�es a n�vel de sistema da inst�ncia
EXEC [sp_verify_permissions]
    @Nr_Tipo_Permissao = 4
    
   
-- Verifica os membros de roles de sistema da inst�ncia
EXEC [sp_verify_permissions]
    @Nr_Tipo_Permissao = 3
