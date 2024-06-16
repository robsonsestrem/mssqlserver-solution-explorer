-- http://mahedee.net/dbcc-sqlperf-for-transaction-log-management/
-- https://dynamicsmerge.wordpress.com/2021/02/09/sql-server-e-possivel-limpar-os-dados-de-estatisticas-de-espera-da-sys-dm_os_wait_stats-do-sql-server/


DBCC SQLPERF('sys.dm_os_wait_stats',CLEAR);


DBCC SQLPERF ('sys.dm_os_latch_stats', clear);
