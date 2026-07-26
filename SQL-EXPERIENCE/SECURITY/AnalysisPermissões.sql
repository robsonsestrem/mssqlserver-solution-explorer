-- Verifica todas as permiss�es do usu�rio 'Usuario_Teste' na inst�ncia
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel'
    
    
-- Verifica todas as permiss�es da tabela 'xxxx' no database 'Protheus_Producao'
EXEC Management.[sp_VerifyPermissions]
    @Ds_Database = 'INTEGRATICRAVIL',
    @Ds_Objeto = 'CadusuariosLogDML'
    

-- Verifica as roles de database do usu�rio 'Usuario_Teste' em todos os bancos
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 1,
    @Fl_Permissoes_Servidor = 0 -- N�o
    
    
-- Verifica as permiss�es a n�vel de Database do usu�rio 'Usuario_Teste'
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = 'infjoabel', -- varchar(100)
    @Ds_Database = NULL, -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- N�o
    
    
-- Verifica as permiss�es do database 'Protheus_Producao' para todos os usu�rios
EXEC Management.[sp_VerifyPermissions]
    @Ds_Usuario = NULL, -- varchar(100)
    @Ds_Database = 'YOUR_DATABASE', -- varchar(100)
    @Ds_Objeto = NULL,
    @Nr_Tipo_Permissao = 2,
    @Fl_Permissoes_Servidor = 0 -- N�o
    
    
-- Verifica as permiss�es a n�vel de sistema da inst�ncia
EXEC Management.[sp_VerifyPermissions]
    @Nr_Tipo_Permissao = 4
    
   
-- Verifica os membros de roles de sistema da inst�ncia
EXEC Management.[sp_VerifyPermissions]
    @Nr_Tipo_Permissao = 3