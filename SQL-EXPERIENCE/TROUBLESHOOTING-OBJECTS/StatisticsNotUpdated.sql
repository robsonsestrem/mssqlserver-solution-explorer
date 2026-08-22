/*
 *
    OBJETIVO: Script para identificar estatísticas que necessitam de atualização
              com base no contador de alterações (rowmodctr) em relação ao
              número total de linhas da tabela, utilizando o limiar
              padrão de 500 + 20% do total de linhas.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: sysindexes, sys.tables, sp_helpstats
 */
-- ============================================================
-- Identifica estatísticas com alto número de alterações
-- ============================================================
USE DBA_PerformanceHub
GO

SELECT
      i.id AS ObjectId
    , t.NAME AS TableName
    , i.indid AS Index_Stat_Id       -- ID de statistics na tabela sysindexes
    , i.NAME AS Index_Stat_Name      -- Nome da statistics
    , i.rowmodctr AS Status_DML      -- Número de alterações desde a última atualização
    , i.rows AS Total_Rows_Column    -- Número de linhas que tem statistics por coluna
    , i.dpages
FROM sysindexes i
    JOIN sys.tables t
        ON i.id = t.object_id
WHERE t.NAME = 'contabil'
    AND i.rowmodctr > ((0.20) * (SELECT COUNT(*) FROM Bi.HistoricoCMV WITH(NOLOCK)) + 500)
ORDER BY i.rowmodctr
GO

-- ============================================================
-- Lista todas as estatísticas da tabela contabil
-- ============================================================
USE YOUR_DATABASE
GO

EXEC sp_helpstats 'contabil', 'all'
GO
