/*
 *
    OBJETIVO: Criar e configurar um Linked Server no SQL Server para permitir
              consultas e operações entre servidores remotos, definindo opções
              como provedor de autenticação, timeouts e compatibilidade de
              collation.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addlinkedserver-transact-sql
 *  https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-addlinkedsrvlogin-transact-sql
 *  https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-serveroption-transact-sql
 */
-- ============================================================
-- Criação e Configuração de Linked Server
-- ============================================================

-- Define o contexto de execução no banco de dados master
USE master;
GO

-- ============================================================
-- Adicionar o Linked Server
-- ============================================================

-- Cria o Linked Server utilizando o provedor SQLNCLI (SQL Server Native Client)
EXEC master.dbo.sp_addlinkedserver
      @server     = N'LINK_SERVER_04'
    , @srvproduct = N''
    , @provider   = N'SQLNCLI'
    , @datasrc    = '159.138.118.3';
GO

-- ============================================================
-- Configurar as credenciais de login para o Linked Server
-- ============================================================

-- Define que as conexões usarão a identidade do login local atual (Windows Authentication)
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

-- Define se a collation do servidor remoto é compatível com o local
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'collation compatible'
    , @optvalue = N'false';
GO

-- Habilita o acesso a dados via Linked Server (consultas distribuídas)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'data access'
    , @optvalue = N'true';
GO

-- Define o servidor como Distribuidor de replicação (dist)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'dist'
    , @optvalue = N'false';
GO

-- Define o servidor como Publicador de replicação (pub)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'pub'
    , @optvalue = N'false';
GO

-- Habilita chamada de procedimento remoto (rpc)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'rpc'
    , @optvalue = N'false';
GO

-- Habilita chamada de procedimento remoto com retorno de dados (rpc out)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'rpc out'
    , @optvalue = N'false';
GO

-- Define o servidor como Assinante de replicação (sub)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'sub'
    , @optvalue = N'false';
GO

-- Define o timeout de conexão em segundos (0 = sem limite)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'connect timeout'
    , @optvalue = N'0';
GO

-- Define o nome da collation a ser usada (NULL = padrão do servidor remoto)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'collation name'
    , @optvalue = NULL;
GO

-- Habilita validação lazy de esquema (só valida metadados no momento da consulta)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'lazy schema validation'
    , @optvalue = N'false';
GO

-- Define o timeout de consulta em segundos (0 = sem limite)
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'query timeout'
    , @optvalue = N'0';
GO

-- Define se as consultas usarão a collation do servidor remoto
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'use remote collation'
    , @optvalue = N'true';
GO

-- Define se transações distribuídas (MSDTC) serão promovidas para procedimentos remotos
EXEC master.dbo.sp_serveroption
      @server   = N'LINK_SERVER_04'
    , @optname  = N'remote proc transaction promotion'
    , @optvalue = N'false';
GO
