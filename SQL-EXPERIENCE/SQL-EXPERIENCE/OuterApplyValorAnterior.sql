/*
	OBJETIVO: Demonstrar o uso de OUTER APPLY para obter o valor anterior
			  (LAG) em uma série temporal, utilizando uma subconsulta correlacionada
			  com TOP 1 para recuperar o registro imediatamente anterior.
			  Também apresenta o uso de SEQUENCE para geração automática
			  de números de ordem.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Exemplo 1: Utilizando ROW_NUMBER para ordenação
-- ============================================================
DECLARE @Tabela TABLE
(
      data  DATE
    , Valor DECIMAL(18, 2)
);

INSERT INTO @Tabela
(
      data
    , Valor
)
SELECT GETDATE() - 1, 100
UNION ALL
SELECT GETDATE() - 2, 200
UNION ALL
SELECT GETDATE() - 3, 200
UNION ALL
SELECT GETDATE() - 4, 300
UNION ALL
SELECT GETDATE() - 5, 400
UNION ALL
SELECT GETDATE() - 6, 500
UNION ALL
SELECT GETDATE() - 7, 600
UNION ALL
SELECT GETDATE() - 8, 700
UNION ALL
SELECT GETDATE() - 9, 800;

SELECT
      ROW_NUMBER() OVER (ORDER BY T1.data)      AS Ordem
    , T1.data
    , T1.Valor
    , ISNULL(Anterior.Valor, 0)                 AS [Valor Anterior]
FROM @Tabela AS T1
OUTER APPLY
(
    SELECT TOP 1
          T.Valor
    FROM @Tabela AS T
    WHERE T.data < T1.data
    ORDER BY
          T.data DESC
) AS Anterior
ORDER BY
      T1.data;

-- ============================================================
-- Exemplo 2: Utilizando SEQUENCE para geração da ordem
-- ============================================================

-- ============================================================
-- Criação da sequência (executar uma única vez)
-- ============================================================
/*
CREATE SEQUENCE Seq AS INT
START WITH 1
INCREMENT BY 1
MINVALUE 1
MAXVALUE 1000
CACHE 10
NO CYCLE;
*/

-- ============================================================
-- Declaração e população da tabela de exemplo
-- ============================================================
DECLARE @Tabela2 TABLE
(
      data  DATE
    , Valor DECIMAL(18, 2)
);

INSERT INTO @Tabela2
(
      data
    , Valor
)
SELECT GETDATE() - 1, 100
UNION ALL
SELECT GETDATE() - 2, 200
UNION ALL
SELECT GETDATE() - 3, 200
UNION ALL
SELECT GETDATE() - 4, 300
UNION ALL
SELECT GETDATE() - 5, 400
UNION ALL
SELECT GETDATE() - 6, 500
UNION ALL
SELECT GETDATE() - 7, 600
UNION ALL
SELECT GETDATE() - 8, 700
UNION ALL
SELECT GETDATE() - 9, 800;

-- ============================================================
-- Consulta utilizando NEXT VALUE FOR com SEQUENCE
-- ============================================================
SELECT
      NEXT VALUE FOR Seq OVER (ORDER BY T.data) AS Ordem
    , T.data
    , T.Valor
    , ISNULL(Anterior.Valor, 0) AS [Valor Anterior]
FROM @Tabela2 AS T
OUTER APPLY
(
    SELECT TOP 1
          TA.Valor
    FROM @Tabela2 AS TA
    WHERE TA.data < T.data
    ORDER BY
          TA.data DESC
) AS Anterior;
