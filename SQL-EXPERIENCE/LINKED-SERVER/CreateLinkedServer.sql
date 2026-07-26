/*
	OBJETIVO: Criar e configurar um Linked Server no SQL Server para permitir
			  consultas e operações entre servidores remotos, definindo opções
			  como provedor de autenticação, timeouts e compatibilidade de
			  collation.
	PROJETO: mssqlserver-solution-explorer
*/
USE master;
GO

-- ============================================================
-- Adicionar o Linked Server
-- ============================================================
EXEC master.dbo.sp_addlinkedserver
      @server     = N'LINK_SERVER_04'
    , @srvproduct = N''
    , @provider   = N'SQLNCLI'
    , @datasrc    = '159.138.118.3';
GO

-- ============================================================
-- Configurar as credenciais de login para o Linked Server
-- ============================================================
EXEC master.dbo.sp_addlinkedsrvlogin
      @rmtsrvname  = N'LINK_SERVER_04'
    , @useself     = N'True'
    , @locallogin  = NULL
    , @rmtuser     = NULL
    , @rmtpassword = NULL;
GO

-- ============================================================
-- Configurar opções do servidor (sp_serveroption)
-- ============================================================

-- Compatibilidade de collation
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'collation compatible'
    , @optvalue  = N'false';
GO

-- Habilitar acesso a dados
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'data access'
    , @optvalue  = N'true';
GO

-- Distribuidor (dist)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'dist'
    , @optvalue  = N'false';
GO

-- Publicador (pub)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'pub'
    , @optvalue  = N'false';
GO

-- Chamada remota (rpc)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'rpc'
    , @optvalue  = N'false';
GO

-- Chamada remota com retorno (rpc out)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'rpc out'
    , @optvalue  = N'false';
GO

-- Assinante (sub)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'sub'
    , @optvalue  = N'false';
GO

-- Timeout de conexão (0 = sem limite)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'connect timeout'
    , @optvalue  = N'0';
GO

-- Nome da collation (NULL = usar o padrão do servidor remoto)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'collation name'
    , @optvalue  = NULL;
GO

-- Validação lazy de esquema
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'lazy schema validation'
    , @optvalue  = N'false';
GO

-- Timeout de consulta (0 = sem limite)
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'query timeout'
    , @optvalue  = N'0';
GO

-- Usar collation remota
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'use remote collation'
    , @optvalue  = N'true';
GO

-- Promoção de transação remota
EXEC master.dbo.sp_serveroption
      @server    = N'LINK_SERVER_04'
    , @optname   = N'remote proc transaction promotion'
    , @optvalue  = N'false';
GO
