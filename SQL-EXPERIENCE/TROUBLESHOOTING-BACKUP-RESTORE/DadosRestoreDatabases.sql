/*
    OBJETIVO: Consultar o histórico de restaurações realizadas no SQL Server,
              exibindo detalhes como data, usuário, tipo de restore e
              relacionamento com os bancos de dados atuais.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Histórico completo de restaurações
-- ============================================================
SELECT
    restore_history_id
  , restore_date
  , destination_database_name
  , user_name
  , backup_set_id
  , restore_type
  , replace
  , recovery
  , restart
  , stop_at
  , device_count
  , stop_at_mark_name
  , stop_before
FROM
    msdb.dbo.restorehistory;


-- ============================================================
-- Histórico de restaurações com nome do banco atual
-- ============================================================
SELECT
    d.name                                                                     AS [Nome do Banco de Dados]
  , rh.destination_database_name
  , rh.restore_date
FROM
    msdb.dbo.restorehistory AS rh
    INNER JOIN sys.databases AS d
        ON rh.destination_database_name = d.name
ORDER BY
    rh.restore_date DESC;
