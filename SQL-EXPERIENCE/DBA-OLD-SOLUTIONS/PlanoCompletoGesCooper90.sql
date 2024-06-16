--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agendar Job só para o índice maior da base (como já é conhecido), exemplo de período: 21:00 toda quarta e domingo.
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Selecionar database Maintenance que é onde se encontra a procedure IndexOptimize
EXECUTE dbo.IndexOptimize @Databases = 'GesCooper90',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@LogToTable=Y,
@Indexes = 'GesCooper90.dbo.MOVESTOQUELEVEL1.PK__MOVESTOQUELEVEL1__2D52A092'


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agendar Job para índices restantes da base, 
-- exemplo de período: 21:05 (horário após a outra job de reindex para dar tempo de bkp e shrink) toda quarta e domingo.
--------------------------------------------------------------------------------------------------------------------------------------------------------
EXECUTE dbo.IndexOptimize @Databases = 'GesCooper90',
@FragmentationLow = NULL,
--@FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
--@FragmentationLevel1 = 30,
@FragmentationLevel2 = 30,
--@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@LogToTable=Y,
@PageCountLevel=10000,
@Indexes = 'ALL_INDEXES, -GesCooper90.dbo.MOVESTOQUELEVEL1.PK__MOVESTOQUELEVEL1__2D52A092'


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agendado Job para backup e shrink otimizados, exemplo de período: 21:00 executando a cada 5 minutos até as 04:00, toda quarta e domingo.
-- retirei a questão do SHRINKFILE, pois simplesmente não funcionava, sql alertava que não podia fazer porque o arquivo estava em uso...
--------------------------------------------------------------------------------------------------------------------------------------------------------
use master
go
BACKUP LOG [GesCooper90] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\BackupLog\ReindexGesCooper90.trn' 
WITH NOFORMAT, NOINIT,  NAME = N'GesCooper90-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

USE [GesCooper90]
GO
DBCC SHRINKFILE (N'GesCooper90_log' , 0, TRUNCATEONLY)
GO