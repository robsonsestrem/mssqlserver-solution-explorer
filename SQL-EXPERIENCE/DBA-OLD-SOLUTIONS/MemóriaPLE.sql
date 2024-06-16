---------------------------------------------------------------------------------------------------------------------------------
-- https://medium.com/@pelegrini/indicadores-do-sql-server-page-life-expectancy-b82d0d0a377b
-- https://blog.sqlauthority.com/2014/05/01/sql-server-good-value-for-page-life-expectancy-notes-from-the-field-026/
---------------------------------------------------------------------------------------------------------------------------------
WITH 
    tm_cte AS (
        SELECT CONVERT(int, value_in_use) / 1024. [memory_gb],
            CONVERT(int, value_in_use) / 1024. / 4. * 300 [counter_by_memory]
        FROM sys.configurations
        WHERE name like 'max server memory%'
    ),
    cached_cte AS (
        SELECT 
        COUNT(*) * 8. / 1024. / 1024. [cached_gb],
            COUNT(*) * 8. / 1024. / 1024.  / 4. * 300 [counter_by_cache]
        FROM [sys].[dm_os_buffer_descriptors]
)
SELECT CEILING(counter_by_memory) [Limite 1],
    CEILING(counter_by_cache) [Limite 2]
FROM tm_cte, cached_cte;