/*
 *
	OBJETIVO: Demonstração comparativa de operadores de conjunto e aplicação
			  tabular no T-SQL: UNION ALL (união de result sets), OUTER APPLY
			  (equivalente a LEFT JOIN lateral) e CROSS APPLY (equivalente a
			  INNER JOIN lateral), utilizando table variables como base de teste.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *
 */
-- ============================================================
-- Operadores de Conjunto: UNION ALL, OUTER APPLY e CROSS APPLY
-- ============================================================

-- Declaração das table variables de teste
DECLARE @Tabela1 TABLE
(
    Codigo INT
    ,Valor INT
)

DECLARE @Tabela2 TABLE
(
    Codigo INT
    ,Valor INT
)

-- População da primeira tabela de teste
INSERT INTO @Tabela1
VALUES
    (1, 1)
    ,(2, 2)
    ,(NULL, NULL)

-- População da segunda tabela de teste
INSERT INTO @Tabela2
VALUES
    (1, 1)
    ,(2, 2)
    ,(3, 3)
    ,(4, 4)
    ,(5, 5)
    ,(NULL, NULL)

-- ============================================================
-- CONSULTA 01: UNION ALL
-- Une os result sets das duas tabelas preservando duplicatas
-- ============================================================
SELECT
    t1.Codigo
    ,t1.Valor
FROM @Tabela1 AS t1

UNION ALL

SELECT
    t2.Codigo
    ,t2.Valor
FROM @Tabela2 AS t2

-- ============================================================
-- CONSULTA 02: OUTER APPLY
-- Equivalente a LEFT JOIN lateral: retorna todas as linhas
-- da tabela externa, com NULL quando não houver correspondência
-- ============================================================
SELECT
    t.Codigo
    ,t.Valor
FROM @Tabela1 AS t
OUTER APPLY
(
    SELECT
        t2.Codigo
    FROM @Tabela2 AS t2
    WHERE t2.Codigo = t.Codigo
) AS t2

-- ============================================================
-- CONSULTA 03: CROSS APPLY
-- Equivalente a INNER JOIN lateral: retorna apenas as linhas
-- da tabela externa que possuam correspondência na aplicação
-- ============================================================
SELECT
    t.Codigo
    ,t.Valor
FROM @Tabela1 AS t
CROSS APPLY
(
    SELECT
        t2.Codigo
    FROM @Tabela2 AS t2
    WHERE t2.Codigo = t.Codigo
) AS t2
