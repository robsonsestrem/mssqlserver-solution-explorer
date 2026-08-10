/*
 *
    OBJETIVO: Algoritmo de detecção de GAPs (lacunas) em sequências numéricas
              de identificadores. Identifica intervalos ausentes entre
              IdBaseDados consecutivos na tabela Management.InstanceDatabases,
              retornando o início e o término de cada lacuna encontrada.
    PROJETO: mssqlserver-solution-explorer
 * 
 */
-- ================================================================================
-- Validação de GAPs em Sequência Numérica de Identificadores
-- ================================================================================

-- 
-- Query de referência (algoritmo original aplicado sobre tblProdutos):
-- 
-- SELECT
--       ProdutoID + 1 AS Inicio
--     , (
--           SELECT MIN(P2.ProdutoID)
--           FROM tblProdutos AS P2
--           WHERE P2.ProdutoID > P1.ProdutoID
--       ) - 1 AS Termino
-- FROM tblProdutos AS P1
-- WHERE NOT EXISTS
--     (
--         SELECT
--             *
--         FROM tblProdutos AS P2
--         WHERE P2.ProdutoID = P1.ProdutoID + 1
--     )
--     AND ProdutoID < (
--         SELECT MAX(ProdutoID)
--         FROM tblProdutos AS P1
--     )
-- 
-- REFERÊNCIA: Gustavo Maia - MVP
-- 

-- Define o contexto de execução no banco de dados
USE DBA_PerformanceHub
GO

-- ================================================================================
-- Detecção de GAPs: identifica intervalos ausentes na sequência de IdBaseDados
-- ================================================================================

-- Para cada registro, verifica se o próximo ID consecutivo não existe (NOT EXISTS)
-- e calcula o início (IdBaseDados + 1) e o término (próximo ID existente - 1) da lacuna
SELECT
      t1.IdBaseDados + 1 AS Inicio
    , (
          SELECT
              MIN(t2.IdBaseDados)
          FROM
              Management.InstanceDatabases AS t2
          WHERE
              t2.IdBaseDados > t1.IdBaseDados
      ) - 1 AS Termino
FROM
    Management.InstanceDatabases AS t1
WHERE
    NOT EXISTS
        (
            SELECT
                *
            FROM
                Management.InstanceDatabases AS t2
            WHERE
                t2.IdBaseDados = t1.IdBaseDados + 1
        )
    AND t1.IdBaseDados < (
        SELECT
            MAX(t1.IdBaseDados)
        FROM
            Management.InstanceDatabases AS t1
    )
