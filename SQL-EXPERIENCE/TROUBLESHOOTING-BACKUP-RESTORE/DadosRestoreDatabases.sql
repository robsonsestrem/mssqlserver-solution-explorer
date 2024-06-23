SELECT restore_history_id
      ,restore_date
      ,destination_database_name
      ,user_name
      ,backup_set_id
      ,restore_type
      ,replace
      ,recovery
      ,restart
      ,stop_at
      ,device_count
      ,stop_at_mark_name
      ,stop_before
FROM msdb.dbo.restorehistory

---------------------------------------------------------------------------
SELECT
    d.name AS 'Nome do Banco de Dados',
    rh.destination_database_name,
    rh.restore_date
FROM msdb.dbo.restorehistory rh
JOIN sys.databases d ON rh.destination_database_name = d.name
ORDER BY rh.restore_date DESC;







