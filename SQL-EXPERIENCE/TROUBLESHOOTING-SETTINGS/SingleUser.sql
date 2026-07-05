/*
    OBJETIVO: Alternar o banco de dados P_HEALTHMAP_CLINICADOC entre os modos
              SINGLE_USER (com rollback imediato das conexões ativas) e MULTI_USER,
              utilizado em operações de manutenção que exigem acesso exclusivo à instância.
    PROJETO: mssqlserver-solution-explorer
*/

USE master;
GO

-- ---------------------------------------------------------------------------
-- Coloca o banco em modo SINGLE_USER, encerrando conexões ativas imediatamente
-- ---------------------------------------------------------------------------
ALTER DATABASE P_HEALTHMAP_CLINICADOC SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
GO

-- ---------------------------------------------------------------------------
-- Restaura o banco para o modo padrão MULTI_USER
-- ---------------------------------------------------------------------------
ALTER DATABASE P_HEALTHMAP_CLINICADOC SET MULTI_USER;
GO




