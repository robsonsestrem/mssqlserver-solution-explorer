--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agendar Job s� para o �ndice maior da base (como j� � conhecido), exemplo de per�odo: 21:00 toda quarta e domingo.
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Selecionar database YOUR_DATABASE que � onde se encontra a procedure IndexOptimize
EXECUTE dbo.IndexOptimize @Databases = 'YOUR_DATABASE',
@FragmentationLow = NULL,
@FragmentationMedium = 'INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@LogToTable=Y,
@Indexes = 'YOUR_DATABASE.dbo.MOVESTOQUELEVEL1.PK__MOVESTOQUELEVEL1__2D52A092'


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agendar Job para �ndices restantes da base, 
-- exemplo de per�odo: 21:05 (hor�rio ap�s a outra job de reindex para dar tempo de bkp e shrink) toda quarta e domingo.
--------------------------------------------------------------------------------------------------------------------------------------------------------
EXECUTE dbo.IndexOptimize @Databases = 'YOUR_DATABASE',
@FragmentationLow = NULL,
--@FragmentationMedium = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
@FragmentationHigh = 'INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE',
--@FragmentationLevel1 = 30,
@FragmentationLevel2 = 30,
--@UpdateStatistics = 'ALL',
@OnlyModifiedStatistics = 'Y',
@LogToTable=Y,
@PageCountLevel=10000,
@Indexes = 'ALL_INDEXES, -YOUR_DATABASE.dbo.MOVESTOQUELEVEL1.PK__MOVESTOQUELEVEL1__2D52A092'


--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agendado Job para backup e shrink otimizados, exemplo de per�odo: 21:00 executando a cada 5 minutos at� as 04:00, toda quarta e domingo.
-- retirei a quest�o do SHRINKFILE, pois simplesmente n�o funcionava, sql alertava que n�o podia fazer porque o arquivo estava em uso...
--------------------------------------------------------------------------------------------------------------------------------------------------------
use master
go
BACKUP LOG [YOUR_DATABASE] TO  DISK = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\BackupLog\ReindexYOUR_DATABASE.trn' 
WITH NOFORMAT, NOINIT,  NAME = N'YOUR_DATABASE-Full Database Backup', SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10
GO

USE [YOUR_DATABASE]
GO
DBCC SHRINKFILE (N'YOUR_DATABASE_log' , 0, TRUNCATEONLY)
GO