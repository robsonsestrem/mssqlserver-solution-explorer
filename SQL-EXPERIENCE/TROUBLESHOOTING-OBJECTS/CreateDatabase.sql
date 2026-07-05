/*
    OBJETIVO: Provisionar o banco DBA_PerformanceHub com arquivos de dados e log dedicados,
              e configurar todas as opções de banco conforme o padrão do ambiente DBA.
    PROJETO:  mssqlserver-solution-explorer
*/

USE [master];
GO

-- ---------------------------------------------------------------------------
-- Criação do banco: arquivo de dados (G:\Data) e log (F:\Log)
-- ---------------------------------------------------------------------------
CREATE DATABASE DBA_PerformanceHub
ON PRIMARY
(
     NAME        = N'DBA_PerformanceHub'
    ,FILENAME    = N'G:\Data\DBA_PerformanceHub.mdf'
    ,SIZE        = 10240MB
    ,MAXSIZE     = UNLIMITED
    ,FILEGROWTH  = 0
)
LOG ON
(
     NAME        = N'DBA_PerformanceHub_log'
    ,FILENAME    = N'F:\Log\DBA_PerformanceHub_log.ldf'
    ,SIZE        = 1024MB
    ,MAXSIZE     = 2048GB
    ,FILEGROWTH  = 0
);
GO

-- ---------------------------------------------------------------------------
-- Nível de compatibilidade
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET COMPATIBILITY_LEVEL = 100;
GO

-- ---------------------------------------------------------------------------
-- Conformidade ANSI e comportamento aritmético
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET ANSI_NULL_DEFAULT ON;
GO

ALTER DATABASE DBA_PerformanceHub SET ANSI_NULLS ON;
GO

ALTER DATABASE DBA_PerformanceHub SET ANSI_PADDING ON;
GO

ALTER DATABASE DBA_PerformanceHub SET ANSI_WARNINGS ON;
GO

ALTER DATABASE DBA_PerformanceHub SET ARITHABORT ON;
GO

-- ---------------------------------------------------------------------------
-- Opções de estatísticas e comportamento de crescimento automático
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET AUTO_CLOSE OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET AUTO_CREATE_STATISTICS ON;
GO

ALTER DATABASE DBA_PerformanceHub SET AUTO_SHRINK OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET AUTO_UPDATE_STATISTICS ON;
GO

-- ---------------------------------------------------------------------------
-- Comportamento de cursores
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET CURSOR_CLOSE_ON_COMMIT OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET CURSOR_DEFAULT GLOBAL;
GO

-- ---------------------------------------------------------------------------
-- Comportamento de strings, identificadores e triggers
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET CONCAT_NULL_YIELDS_NULL ON;
GO

ALTER DATABASE DBA_PerformanceHub SET NUMERIC_ROUNDABORT OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET QUOTED_IDENTIFIER ON;
GO

ALTER DATABASE DBA_PerformanceHub SET RECURSIVE_TRIGGERS OFF;
GO

-- ---------------------------------------------------------------------------
-- Service Broker e estatísticas assíncronas                           
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET ENABLE_BROKER;                   -- DBA
GO

ALTER DATABASE DBA_PerformanceHub SET AUTO_UPDATE_STATISTICS_ASYNC OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET DATE_CORRELATION_OPTIMIZATION OFF;
GO

-- ---------------------------------------------------------------------------
-- Segurança, isolamento e snapshot                                     
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET TRUSTWORTHY ON;                   -- DBA
GO

ALTER DATABASE DBA_PerformanceHub SET ALLOW_SNAPSHOT_ISOLATION ON;      -- DBA
GO

-- ---------------------------------------------------------------------------
-- Parametrização e controle de leitura comprometida
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET PARAMETERIZATION SIMPLE;
GO

ALTER DATABASE DBA_PerformanceHub SET READ_COMMITTED_SNAPSHOT OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET HONOR_BROKER_PRIORITY OFF;
GO

-- ---------------------------------------------------------------------------
-- Recovery, acesso e integridade de páginas                          
-- ---------------------------------------------------------------------------
ALTER DATABASE DBA_PerformanceHub SET RECOVERY FULL;                  -- DBA
GO

ALTER DATABASE DBA_PerformanceHub SET MULTI_USER;
GO

ALTER DATABASE DBA_PerformanceHub SET PAGE_VERIFY CHECKSUM;
GO

ALTER DATABASE DBA_PerformanceHub SET DB_CHAINING OFF;
GO

ALTER DATABASE DBA_PerformanceHub SET READ_WRITE;
GO