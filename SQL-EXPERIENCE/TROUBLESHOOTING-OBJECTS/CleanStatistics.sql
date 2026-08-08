/*
    OBJETIVO: Limpar as estatísticas de espera (wait stats) e de travas (latch stats)
              do SQL Server, reiniciando os contadores para monitoramento
              a partir de um ponto de referência.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    http://mahedee.net/dbcc-sqlperf-for-transaction-log-management/
    https://dynamicsmerge.wordpress.com/2021/02/09/sql-server-e-possivel-limpar-os-dados-de-estatisticas-de-espera-da-sys-dm_os_wait_stats-do-sql-server/
*/
-- ============================================================
-- Limpeza de estatísticas de espera
-- ============================================================
DBCC SQLPERF('sys.dm_os_wait_stats', CLEAR);


-- ============================================================
-- Limpeza de estatísticas de travas (latches)
-- ============================================================
DBCC SQLPERF('sys.dm_os_latch_stats', CLEAR);

