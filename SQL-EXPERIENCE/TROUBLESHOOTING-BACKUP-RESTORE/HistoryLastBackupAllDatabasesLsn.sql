/*
    OBJETIVO: Consultar o histórico dos últimos backups de bancos de dados,
              exibindo informações como tamanho, tempo de execução, LSNs
              (Log Sequence Number) e tipo de backup, permitindo filtro
              por banco específico ou todos os bancos.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- Último backup de todos os bancos de dados com LSN
-- ============================================================
SELECT TOP 100
    s.database_name
  , m.physical_device_name
  , CAST(CAST(s.backup_size / 1000000 AS INT) AS VARCHAR(14)) + ' ' + 'MB'  AS bkSize
  , CAST(DATEDIFF(SECOND, s.backup_start_date, s.backup_finish_date) AS VARCHAR(10)) + ' ' + 'Seconds' AS TimeTaken
  , s.backup_start_date
  , s.backup_finish_date
  , CAST(s.first_lsn AS VARCHAR(50))                                         AS first_lsn
  , CAST(s.last_lsn AS VARCHAR(50))                                          AS last_lsn
  , CASE s.type
        WHEN 'D' THEN 'Full'
        WHEN 'I' THEN 'Differential'
        WHEN 'L' THEN 'Transaction Log'
    END                                                                      AS BackupType
  , s.server_name
  , s.recovery_model
FROM
    msdb.dbo.backupset AS s
    INNER JOIN msdb.dbo.backupmediafamily AS m
        ON s.media_set_id = m.media_set_id
WHERE
    s.database_name = DB_NAME() -- Remova esta linha para todos os bancos
ORDER BY
    s.backup_start_date DESC
  , s.backup_finish_date;
GO
