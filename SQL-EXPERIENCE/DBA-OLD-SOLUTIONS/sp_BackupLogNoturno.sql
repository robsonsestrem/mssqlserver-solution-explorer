--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Rotina necessária colocada em Job devido à reindexação semanal, onde foi deixado esta janela de tempo para combinar com as Jobs do Backup Exec.
-- Abaixo para bases de ETL
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BACKUP LOG [IntegraTICravil] TO  DISK = N'F:\Log_SSMS\IntegraTICravil_Log.trn' WITH INIT;
GO

BACKUP LOG [TICRAVIL] TO  DISK = N'F:\Log_SSMS\TICRAVIL_Log.trn' WITH INIT;
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Bases de produção em job com horário distinto
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BACKUP LOG [GesCooper90] TO  DISK = N'F:\Log_SSMS\GesCooper90_Log.trn' WITH INIT;
GO

BACKUP LOG [CooperSystem] TO  DISK = N'F:\Log_SSMS\CooperSystem_Log.trn' WITH INIT;
GO

BACKUP LOG [Edocs] TO  DISK = N'F:\Log_SSMS\Edocs_Log.trn' WITH INIT;
GO

BACKUP LOG [Guru5] TO  DISK = N'F:\Log_SSMS\Guru5_Log.trn' WITH INIT;
GO

BACKUP LOG [Guru6] TO  DISK = N'F:\Log_SSMS\Guru6_Log.trn' WITH INIT;
GO

BACKUP LOG [rhcravil] TO  DISK = N'F:\Log_SSMS\rhcravil_Log.trn' WITH INIT;
GO



--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- backup e shrink para o reindex de bases
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DBCC shrinkfile(integraticravil_log, 60000)