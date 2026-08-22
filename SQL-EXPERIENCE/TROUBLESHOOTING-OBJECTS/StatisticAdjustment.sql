/*
 *
    OBJETIVO: Scripts para ajuste e monitoramento de estatísticas no SQL Server,
              incluindo atualização de estatísticas, verificação da última
              atualização, identificação de alterações (rowmodctr) e
              informações sobre estatísticas automáticas, explícitas e implícitas.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: UPDATE STATISTICS, DBCC SHOW_STATISTICS, sp_updatestats
 */
-- ============================================================
-- Configuração de estatísticas de IO e Time
-- ============================================================
SET STATISTICS IO ON
GO

SET STATISTICS TIME ON
GO

-- ============================================================
-- Atualiza todas as estatísticas do banco de dados
-- ============================================================
BEGIN TRAN
    EXEC sp_updatestats
COMMIT TRAN
GO

-- ============================================================
-- Atualiza estatísticas de uma tabela específica
-- ============================================================
BEGIN TRAN
    UPDATE STATISTICS MOVESTOQUE  -- Atualiza tabela inteira
    WITH FULLSCAN, ALL
COMMIT TRAN
GO

-- ============================================================
-- Atualiza uma estatística específica pelo nome
-- ============================================================
UPDATE STATISTICS MOVESTOQUE IMOVESTOQUE27
GO

-- ============================================================
-- Lista todas as estatísticas de uma tabela
-- ============================================================
EXEC sp_helpstats 'MOVESTOQUE', 'all'
GO

-- ============================================================
-- Lista objetos de estatísticas para as tabelas do banco
-- O campo auto_created armazena o valor 1, confirmando a criação automática
-- ============================================================
USE YOUR_DATABASE
GO

SELECT *
FROM sys.stats
WHERE object_id = OBJECT_ID('CONTABIL')
GO

-- ============================================================
-- Identifica última atualização das estatísticas
-- ============================================================
SELECT
      deriva.column_id
    , deriva.coluna
    , deriva.[Table Name]
    , deriva.[Stat Id]
    , deriva.[Stat Name]
    , deriva.Last_Updated
    , deriva.auto_created
    , deriva.user_created
    , deriva.has_filter
FROM
(
    SELECT
          t.name AS [Table Name]
        , c.name AS coluna
        , c.column_id
        , s.name AS [Stat Name]
        , stats_id AS [Stat Id]
        , stats_date(s.object_id, stats_id) AS Last_Updated
        , s.auto_created    -- 1 = automática
        , s.user_created    -- 1 = criada pelo usuário
        , s.has_filter      -- 1 = índice nonclustered filtrado
    FROM sys.stats AS s
        INNER JOIN sys.tables AS t
            ON s.object_id = t.object_id
        INNER JOIN sys.columns AS c
            ON c.object_id = t.object_id
    WHERE t.name = 'MOVESTOQUE'
        AND c.name IN ('NfDatEmis')
) AS deriva
ORDER BY deriva.Last_Updated
GO

-- ============================================================
-- Indica a quantidade de mudanças (INSERT, UPDATE, DELETE)
-- desde a última atualização via sysindexes (rowmodctr)
-- ============================================================
SELECT
      i.id AS ObjectId
    , t.name AS TableName
    , i.indid AS Index_Stat_Id       -- ID de statistics na sysindexes
    , i.name AS Index_Stat_Name      -- Nome da statistics
    , i.rowmodctr AS Status_DML      -- Número de alterações desde a última atualização
    , i.rows AS Total_Rows_Column    -- Número de linhas com statistics
    , i.dpages
FROM sysindexes i
    JOIN sys.tables t ON i.id = t.object_id
WHERE t.name = 'MOVESTOQUE'
GO

-- ============================================================
-- Verifica a última atualização de um campo específico
-- Obs.: Trazer o nome da estatística no parâmetro
-- Nota: Utilizar a opção WITH STAT_HEADER para exibir apenas o cabeçalho
-- ============================================================
DBCC SHOW_STATISTICS ('MOVESTOQUE', _WA_Sys_0000000D_2A7633E7) WITH STAT_HEADER
GO

-- ============================================================
-- Observações sobre estatísticas:
--
-- 3 formas de criação de estatísticas:
--   1. Automática: criada automaticamente pelo Query Processor
--   2. Explícita: criada pelo usuário (CREATE STATISTICS)
--   3. Implícita: criada como decorrência da criação de índices
--
-- Atualização automática: ocorre quando rowmodctr atinge
-- 500 + 20% do total de tuplas do campo.
-- O SQL Server deve zerar o rowmodctr automaticamente.
-- Caso contrário, a atualização manual é necessária.
-- ============================================================

-- ============================================================
-- Exemplo do MSDN
-- ============================================================
/*
USE AdventureWorks2012;
GO
UPDATE STATISTICS Production.Product(Products)
    WITH FULLSCAN;
GO

-- Sintaxe: UPDATE STATISTICS table_or_indexed_view_name
--          [ ( statistics_name ) ]
--          [ WITH FULLSCAN | SAMPLE ... ]
*/
