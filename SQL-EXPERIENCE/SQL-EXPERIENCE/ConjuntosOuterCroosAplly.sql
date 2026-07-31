/*
	OBJETIVO: Demonstrar as diferenças práticas entre UNION ALL, OUTER APPLY
			  e CROSS APPLY, utilizando tabelas temporárias com dados de exemplo
			  para ilustrar o comportamento de cada operador em cenários de
			  junção e subconsulta correlacionada.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Declaração e população das tabelas de exemplo
-- ============================================================
DECLARE @Tabela1 TABLE
(
      Codigo INT
    , Valor  INT
);

DECLARE @Tabela2 TABLE
(
      Codigo INT
    , Valor  INT
);

INSERT INTO @Tabela1
(
      Codigo
    , Valor
)
VALUES
      (1, 1)
    , (2, 2)
    , (NULL, NULL);

INSERT INTO @Tabela2
(
      Codigo
    , Valor
)
VALUES
      (1, 1)
    , (2, 2)
    , (3, 3)
    , (4, 4)
    , (5, 5)
    , (NULL, NULL);

-- ============================================================
-- Exemplo 1: UNION ALL - Concatenação simples de todos os registros
-- ============================================================
SELECT
      Codigo
    , Valor
FROM @Tabela1
UNION ALL
SELECT
      Codigo
    , Valor
FROM @Tabela2;

-- ============================================================
-- Exemplo 2: OUTER APPLY - Retorna todos os 
-- registros da tabela esquerda
-- mais os correspondentes da direita (semelhante a LEFT JOIN)
-- ============================================================
SELECT
      T.Codigo
    , T.Valor
FROM @Tabela1 AS T
OUTER APPLY
(
    SELECT
          Codigo
    FROM @Tabela2
    WHERE Codigo = T.Codigo
) AS T2;

-- ============================================================
-- Exemplo 3: CROSS APPLY - Retorna apenas 
-- os registros da tabela esquerda que possuem
-- correspondência na direita (semelhante a INNER JOIN)
-- ============================================================
SELECT
      T.Codigo
    , T.Valor
FROM @Tabela1 AS T
CROSS APPLY
(
    SELECT
          Codigo
    FROM @Tabela2
    WHERE Codigo = T.Codigo
) AS T2;

