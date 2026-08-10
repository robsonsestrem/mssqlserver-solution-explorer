/*
 *
	OBJETIVO: Rotina de manutenção de índices e estatísticas utilizando a solução
	          IndexOptimize de Ola Hallengren, com backup de log e shrink otimizado
	          para bancos de dados com Recovery Model FULL.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://ola.hallengren.com/sql-server-index-and-statistics-DBA_PerformanceHub.html
 */
-- ============================================================
-- Plano de Manutenção FULL (Ola Hallengren - IndexOptimize)
-- ============================================================

-- Bloco 1: Reindex do índice principal da base (maior fragmentação conhecida)
-- Agendamento sugerido: 21:00 toda quarta e domingo
-- Selecionar database YOUR_DATABASE onde se encontra a procedure IndexOptimize
EXECUTE dbo.IndexOptimize
    @Databases = 'YOUR_DATABASE'
  , @FragmentationLow = NULL
  , @FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
  , @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
  , @FragmentationLevel1 = 5
  , @FragmentationLevel2 = 30
  , @UpdateStatistics = 'ALL'
  , @OnlyModifiedStatistics = 'Y'
  , @LogToTable = 'Y'
  , @Indexes = 'YOUR_DATABASE.dbo.MOVESTOQUELEVEL1.PK__MOVESTOQUELEVEL1__2D52A092';
GO

-- Bloco 2: Reindex dos índices restantes da base (excluindo o índice principal já tratado)
-- Agendamento sugerido: 21:05 toda quarta e domingo (após a job de reindex principal,
-- dando tempo para backup e shrink)
EXECUTE dbo.IndexOptimize
    @Databases = 'YOUR_DATABASE'
  , @FragmentationLow = NULL
  --, @FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
  , @FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'
  --, @FragmentationLevel1 = 30
  , @FragmentationLevel2 = 30
  --, @UpdateStatistics = 'ALL'
  , @OnlyModifiedStatistics = 'Y'
  , @LogToTable = 'Y'
  , @PageCountLevel = 10000
  , @Indexes = 'ALL_INDEXES, -YOUR_DATABASE.dbo.MOVESTOQUELEVEL1.PK__MOVESTOQUELEVEL1__2D52A092';
GO

-- Bloco 3: Backup de log e shrink do arquivo de log
-- Agendamento sugerido: 21:00 executando a cada 5 minutos até as 04:00, toda quarta e domingo
-- Observação: o SHRINKFILE foi removido da rotina automatizada pois o SQL Server
-- alertava que o arquivo estava em uso; mantido aqui apenas para execução manual quando necessário
USE [master];
GO

BACKUP LOG [YOUR_DATABASE]
    TO DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\BackupLog\ReindexYOUR_DATABASE.trn'
    WITH
        NOFORMAT
      , NOINIT
      , NAME = N'YOUR_DATABASE-Full Database Backup'
      , SKIP
      , NOREWIND
      , NOUNLOAD
      , COMPRESSION
      , STATS = 10;
GO

USE [YOUR_DATABASE];
GO

DBCC SHRINKFILE (N'YOUR_DATABASE_log', 0, TRUNCATEONLY);
GO
