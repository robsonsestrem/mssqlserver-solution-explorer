/*
 * OBJETIVO: Scripts de análise de uso de índices no SQL Server,
 *           incluindo identificação de índices não utilizados
 *           (zero user_seeks com alto volume de updates)
 *           e candidatos a REBUILD/REORGANIZE com base em
 *           fragmentação e espaço utilizado por página.
 *
 * REFERÊNCIAS:
 *   https://dbabrasil.net.br/dicas-para-um-dba-iniciante-identificando-indices-nao-utilizados-no-sql-server/
 */
-- ============================================================
-- Análise de Uso de Índices
-- ============================================================

-- Índices não utilizados: identifica objetos com custo de manutenção
-- (updates) desproporcional ao benefício de leitura (seeks zerados)
SELECT
    OBJECT_NAME(dmi.object_id) AS tbl_name
    , i.name AS idx_name
    , dmi.*
    , 'DROP INDEX [dbo].[' + OBJECT_NAME(dmi.object_id) + '].[' + i.name + ']' AS command_drop
FROM sys.dm_db_index_usage_stats AS dmi
JOIN sys.indexes AS i
    ON dmi.index_id = i.index_id
    AND dmi.object_id = i.object_id
WHERE dmi.database_id = DB_ID()
    AND OBJECT_NAME(dmi.object_id) IN ('ESPMD', 'PSSOA', 'RESPC', 'AGEEP', 'UNDSD', 'MEDIC', 'ENCAM', 'CNSUL')
    AND dmi.user_updates > dmi.user_seeks
    AND dmi.user_seeks = 0
ORDER BY dmi.user_updates DESC

-- ============================================================
-- Candidatos para REBUILD ou REORGANIZE
-- ============================================================

-- Monta comando dinâmico para consultar fragmentação física dos índices
-- e classificar a ação recomendada: REORGANIZE (5%-30%) ou REBUILD (>30%)
DECLARE @database VARCHAR(50) = 'H_YOUR_DATABASE_TDE'
DECLARE @comando  VARCHAR(MAX)

SET @comando = '
SELECT
    t.name AS TableName
    , ind.name AS IndexName
    , indexstats.index_depth
    , indexstats.index_level
    , indexstats.avg_fragmentation_in_percent
    , indexstats.avg_page_space_used_in_percent
    , indexstats.page_count
    , CASE
        WHEN indexstats.avg_fragmentation_in_percent BETWEEN 5 AND 30 THEN
            ''Reorganize''
        ELSE
            ''Rebuild''
      END AS Action
    , ''ALTER INDEX '' + ind.name + '' ON ' + @database + '.dbo.'' + t.name + '' ''
      + CASE
          WHEN indexstats.avg_fragmentation_in_percent BETWEEN 5 AND 30 THEN
              ''REORGANIZE;''
          ELSE
              ''REBUILD;''
        END AS command
FROM [' + @database + '].sys.dm_db_index_physical_stats(DB_ID(''' + @database + '''), NULL, NULL, NULL, ''DETAILED'') AS indexstats
INNER JOIN [' + @database + '].sys.indexes AS ind
    ON ind.object_id = indexstats.object_id
    AND ind.index_id = indexstats.index_id
INNER JOIN [' + @database + '].sys.tables AS t
    ON t.object_id = ind.object_id
WHERE indexstats.alloc_unit_type_desc = ''IN_ROW_DATA''
    AND indexstats.index_type_desc != ''HEAP''
    AND indexstats.page_count > 1000
    AND indexstats.avg_fragmentation_in_percent >= 5
    AND indexstats.index_level = 0
    AND indexstats.avg_page_space_used_in_percent < 75
ORDER BY
    ind.name
    , index_level
    , indexstats.avg_fragmentation_in_percent DESC
'

EXECUTE (@comando)
