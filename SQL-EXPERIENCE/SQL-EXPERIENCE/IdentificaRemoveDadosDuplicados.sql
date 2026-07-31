/*
	OBJETIVO: Demonstrar técnicas para identificar e remover registros duplicados
			  em tabelas, utilizando CTE com ROW_NUMBER para deleção direta,
			  além de abordagem alternativa com tabela temporária para preservar
			  uma única ocorrência de cada valor duplicado.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Exemplo 1: Remoção de duplicatas com CTE e ROW_NUMBER
-- ============================================================

-- ============================================================
-- Criação e população da tabela de exemplo
-- ============================================================
CREATE TABLE #prod
(
      Product_Code VARCHAR(10)
    , Product_Name VARCHAR(100)
);

INSERT INTO #prod
(
      Product_Code
    , Product_Name
)
VALUES
      ('123', 'Product_1')
    , ('234', 'Product_2')
    , ('345', 'Product_3')
    , ('345', 'Product_3') -- Registro duplicado
    , ('456', 'Product_4')
    , ('567', 'Product_5')
    , ('678', 'Product_6')
    , ('789', 'Product_7');

-- ============================================================
-- Visualizar os dados antes da remoção
-- ============================================================
SELECT *
FROM #prod;

-- ============================================================
-- CTE com ROW_NUMBER para identificar duplicatas
-- ============================================================
WITH Dups
AS
(
    SELECT
          *
        , ROW_NUMBER() OVER (PARTITION BY Product_Code ORDER BY Product_Code)       AS RowNum
    FROM #prod
)

-- ============================================================
-- Excluir os registros duplicados (mantém apenas o primeiro)
-- ============================================================
DELETE FROM Dups
WHERE RowNum > 1;

-- ============================================================
-- Exemplo 2: Abordagem alternativa com tabela temporária
-- (para cenários onde se deseja preservar apenas uma ocorrência
--  e reinserir os dados)
-- ============================================================

-- ============================================================
-- Identificar os valores que possuem duplicatas e inseri-los
-- em uma tabela temporária (apenas os valores únicos)
-- ============================================================
/*
SELECT DISTINCT
      C1
INTO #OnlyUniqueFromDuplicates
FROM [Table_Having_Duplicates]
GROUP BY C1
HAVING COUNT(C1) > 1;
*/

-- ============================================================
-- Excluir da tabela original todos os registros que possuem
-- duplicatas (inclusive a primeira ocorrência)
-- ============================================================
/*
DELETE FROM [Table_Having_Duplicates]
WHERE EXISTS
(
    SELECT
          C1
    FROM #OnlyUniqueFromDuplicates AS I
    WHERE I.C1 = [Table_Having_Duplicates].C1
);
*/

-- ============================================================
-- Reinserir apenas uma ocorrência de cada valor duplicado
-- ============================================================
/*
INSERT INTO [Table_Having_Duplicates]
(
      C1
)
SELECT C1
FROM #OnlyUniqueFromDuplicates;
*/