/*
	OBJETIVO: Demonstrar a implementação dos equivalentes das funções LAG, LEAD,
			  FIRST_VALUE e LAST_VALUE (disponíveis nativamente a partir do
			  SQL Server 2012) utilizando ROW_NUMBER e funções de janela em
			  versões anteriores (SQL Server 2008), com exemplos práticos
			  de cálculo de valores anteriores e posteriores em séries temporais.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS:
	https://sqlscope.wordpress.com/2014/05/26/lag-and-lead-for-sql-server-2008/
*/

-- ============================================================
-- Exemplo 1: Implementação de LAG e LEAD com CTE
-- ============================================================
WITH balance_details
AS
(
    SELECT *
    FROM
    (
        VALUES
              ('Tom',   '20140101', 100)
            , ('Tom',   '20140102', 120)
            , ('Tom',   '20140103', 150)
            , ('Tom',   '20140104', 140)
            , ('Tom',   '20140105', 160)
            , ('Tom',   '20140106', 180)
            , ('Jerry', '20140101', 210)
            , ('Jerry', '20140102', 240)
            , ('Jerry', '20140103', 230)
            , ('Jerry', '20140104', 270)
            , ('Jerry', '20140105', 190)
            , ('Jerry', '20140106', 200)
            , ('David', '20140101', 170)
            , ('David', '20140102', 230)
            , ('David', '20140103', 240)
            , ('David', '20140104', 210)
            , ('David', '20140105', 160)
            , ('David', '20140106', 200)
    ) AS t (customer, balancedate, balance)
)
, balance_cte
AS
(
    SELECT
          ROW_NUMBER() OVER (PARTITION BY customer ORDER BY balancedate)               AS rn
        , (ROW_NUMBER() OVER (PARTITION BY customer ORDER BY balancedate)) / 2         AS rndiv2
        , (ROW_NUMBER() OVER (PARTITION BY customer ORDER BY balancedate) + 1) / 2     AS rnplus1div2
        -- , COUNT(*) OVER (PARTITION BY customer)                                    AS partitioncount
        , customer
        , balancedate
        , balance
    FROM balance_details
)
SELECT
      cte.rn
    , cte.rndiv2
    , cte.rnplus1div2
    , cte.customer
    , cte.balancedate
    , cte.balance
    , CASE
          WHEN cte.rn % 2 = 1
          THEN MAX(CASE WHEN cte.rn % 2 = 0 THEN cte.balance END) OVER (PARTITION BY cte.customer, cte.rndiv2)
          ELSE MAX(CASE WHEN cte.rn % 2 = 1 THEN cte.balance END) OVER (PARTITION BY cte.customer, cte.rnplus1div2)
      END AS balance_lag
    , CASE
          WHEN cte.rn % 2 = 1
          THEN MAX(CASE WHEN cte.rn % 2 = 0 THEN cte.balance END) OVER (PARTITION BY cte.customer, cte.rnplus1div2)
          ELSE MAX(CASE WHEN cte.rn % 2 = 1 THEN cte.balance END) OVER (PARTITION BY cte.customer, cte.rndiv2)
      END AS balance_lead
    -- , MAX(CASE WHEN cte.rn = 1 THEN cte.balance END) OVER (PARTITION BY cte.customer) AS first_value
    -- , MAX(CASE WHEN cte.rn = partitioncount THEN cte.balance END) OVER (PARTITION BY cte.customer) AS last_value
    -- , MAX(CASE WHEN cte.rn = 4 THEN cte.balance END) OVER (PARTITION BY cte.customer) AS fourth_value
FROM balance_cte AS cte
ORDER BY
      cte.customer
    , cte.balancedate;

-- ============================================================
-- Exemplo 2: Implementação com dados de teste adicionais
-- ============================================================
DECLARE @testeLag TABLE
(
      nome    VARCHAR(50)
    , dataRef DATETIME
    , valor   INT
);

INSERT INTO @testeLag
(
      nome
    , dataRef
    , valor
)
VALUES
      ('paulo', '2017-07-10', 100)
    , ('paulo', '2017-07-11', 220)
    , ('paulo', '2017-07-12', 333)
    , ('paulo', '2017-07-13', 444)
    , ('paulo', '2017-07-14 10:22:07.877', 110)
    , ('paulo', '2017-07-15', 880)
    , ('paulo', '2017-07-16', 560)
    , ('paulo', '2017-07-17', 560);

WITH origem
AS
(
    SELECT
          t.nome
        , t.dataRef
        , t.valor
        , (SELECT MAX(dataRef) FROM @testeLag)                                         AS LastDate
        , MAX(t.dataRef) OVER (PARTITION BY t.nome)                                    AS LastDate2
    FROM @testeLag AS t
    GROUP BY
          t.nome
        , t.dataRef
        , t.valor
)
, calculaOrigem
AS
(
    SELECT
          o.nome
        , o.dataRef
        , o.valor
        , o.LastDate
        , o.LastDate2
        , ROW_NUMBER() OVER (PARTITION BY o.nome ORDER BY o.dataRef)                   AS rn
        , (ROW_NUMBER() OVER (PARTITION BY o.nome ORDER BY o.dataRef)) / 2             AS rndiv2
        , (ROW_NUMBER() OVER (PARTITION BY o.nome ORDER BY o.dataRef) + 1) / 2         AS rnMais1Div2
    FROM origem  AS o
)
SELECT
      c.rn
    , c.rndiv2
    , c.rnMais1Div2
    , c.nome
    , c.dataRef
    , c.valor
    , CASE
          WHEN c.rn % 2 = 1
          THEN MAX(CASE WHEN c.rn % 2 = 0 THEN c.valor END) OVER (PARTITION BY c.nome, c.rndiv2)
          ELSE MAX(CASE WHEN c.rn % 2 = 1 THEN c.valor END) OVER (PARTITION BY c.nome, c.rnMais1Div2)
      END                                                                              AS LAG
    , CASE
          WHEN c.rn % 2 = 1
          THEN MAX(CASE WHEN c.rn % 2 = 0 THEN c.valor END) OVER (PARTITION BY c.nome, c.rnMais1Div2)
          ELSE MAX(CASE WHEN c.rn % 2 = 1 THEN c.valor END) OVER (PARTITION BY c.nome, c.rndiv2)
      END                                                                              AS LEAD
    , (
          SELECT valor
          FROM calculaOrigem
          WHERE dataRef = DATEADD(DAY, -5, c.LastDate)
      )                                                                                AS DiasAtrasLastDate
    , (
          SELECT valor
          FROM calculaOrigem
          WHERE dataRef = DATEADD(DAY, -5, c.LastDate2)
      )                                                                                AS DiasAtrasLastDate2
    , c.LastDate
    , c.LastDate2
FROM calculaOrigem AS c;

-- ============================================================
-- Observações sobre a técnica utilizada:
--   - A divisão inteira por 2 do ROW_NUMBER é usada para agrupar
--     pares de linhas consecutivas (ex: 2 e 3 div 2 = 1).
--   - Para LAG: quando a linha atual é ímpar, busca-se o valor
--     par do mesmo grupo; quando par, busca-se o valor ímpar
--     do grupo anterior.
--   - Para LEAD: o princípio é o mesmo, mas com a expressão
--     de divisão oposta na cláusula de partição.
--   - O código comentado também mostra como obter FIRST_VALUE
--     e LAST_VALUE, além de valores em posições específicas (Nth).
-- ============================================================
