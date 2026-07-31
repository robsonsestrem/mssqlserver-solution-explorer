/*
 *
	OBJETIVO: Exercícios práticos com Window Functions no T-SQL, demonstrando
			  funções de ranking (ROW_NUMBER, RANK, DENSE_RANK, NTILE),
			  funções de deslocamento (LAG, LEAD), funções de valor
			  (FIRST_VALUE, LAST_VALUE), funções de distribuição
			  (PERCENT_RANK, CUME_DIST) e agrupamentos avançados
			  (GROUPING SETS, ROLLUP, CUBE).
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *
 */
-- ============================================================
-- SEÇÃO 1: EXERCÍCIOS COM RANK
-- Funções de classificação sobre valores de pedidos por cliente
-- ============================================================
/*
LAG/LEAD (scalar_expression [,offset] [,default])
OVER ( [ partition_by_clause ] order_by_clause )
1º parâmetro -> valor escalar
2º parâmetro -> quantidade voltar/próximo
3º parâmetro -> valor padrão caso seja nulo
*/

SELECT
    orderid
    ,orderdate
    ,custid
    ,val
    -- Feito rank sobre valores de cada pedido de vendas "Val" por cliente
    ,RANK() OVER (PARTITION BY custid ORDER BY val DESC) AS RankValorPorCliente
    -- Feito rank em percentual sobre valores de cada pedido de vendas "Val" por cliente
    ,PERCENT_RANK() OVER (PARTITION BY custid ORDER BY val DESC) AS RankPercentual
    --, RANK() OVER (PARTITION BY custid, YEAR(orderdate) ORDER BY val DESC) AS RankValorPorClienteAno
    -- no dense_rank só muda a forma de contar (ele repetiri se tivesse valores iguais)
    ,DENSE_RANK() OVER (PARTITION BY custid ORDER BY val DESC) AS DenseRank
FROM OrderValues


-- ============================================================
-- SEÇÃO 2: EXERCÍCIOS COM VALORES
-- Manipulação de séries temporais com LAG, LEAD e funções de janela
-- ============================================================
;WITH vendasPorMes2007 AS
(
    SELECT
        MONTH(orderdate) AS monthno
        ,SUM(val) AS val
    FROM OrderValues
    WHERE orderdate >= '20070101'
        AND orderdate < '20080101'
    GROUP BY MONTH(orderdate)
)
,manipulacao AS
(
    SELECT
        monthno
        ,Val
        ,LAG(val) OVER (ORDER BY monthno) AS Anterior
        ,LEAD(val) OVER (ORDER BY monthno) AS Proximo
        -- na 4º linha terei o cálculo certo, pois vai ser possível fazer a média dos 3 anteriores (forma ainda engessada)
        ,(LAG(val, 1, 0) OVER (ORDER BY monthno) + LAG(val, 2, 0) OVER (ORDER BY monthno) + LAG(val, 3, 0) OVER (ORDER BY monthno)) / 3 AS Media3UltimosMeses
        -- neste caso tenho a média calculada para 4 meses, ele pega os 3 anteriores e a linha atual (é mais dinâmico)
        ,AVG(val) OVER (ORDER BY monthno ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS Media3UltimosMesesEAtual
        -- somatória ascendente dos valores, total de valores até a linha atual, último valor mostra valor total dos 12 meses
        ,SUM(val) OVER (ORDER BY monthno ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Somatória
        -- usado "val" da função FIRST_VALUE para subtrair com os outros valores sequenciais
        ,val - FIRST_VALUE(val) OVER (ORDER BY monthno ROWS UNBOUNDED PRECEDING) AS DifValorAtualComJaneiro
        -- último valor da coluna "val"
        ,LAST_VALUE(val) OVER (ORDER BY val ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS [LAST_VAL]
        -- Primeiro valor da coluna "val"
        ,FIRST_VALUE(val) OVER (ORDER BY val ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS [FIRST_VAL]
    FROM vendasPorMes2007
)
SELECT
    *
    -- Último valor da coluna "somatória" é o total e com isso é possível fazer o percentual
    ,100. * t3.val / LAST_VALUE(t3.Somatória) OVER (ORDER BY t3.Somatória ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS PercentualDoTotal
FROM manipulacao AS t3


-- ============================================================
-- SEÇÃO 3: TESTE COM SOMA PROGRESSIVA
-- Cálculo de percentual e somatória acumulada por cliente
-- ============================================================
SELECT
    custid
    ,orderid
    ,orderdate
    ,val
    -- Traz percentual deste "val" na linha em relação com o "val" total por cliente
    ,100. * val / SUM(val) OVER (PARTITION BY custid) AS percoftotalcust
    -- Realiza somatória ascendente dos "val" por cliente ordenado por data e pedido
    ,SUM(val) OVER (PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS [SomaValoresAtéLinhaAtual]
FROM OrderValues


-- ============================================================
-- SEÇÃO 4: EXERCÍCIOS COM GROUPING SETS, ROLLUP E CUBE
-- Agrupamentos multidimensionais para análise hierárquica
-- ============================================================
-- CUBE: gera todas as combinações possíveis de agrupamento
SELECT
    GROUPING_ID(YEAR(orderdate), MONTH(orderdate)) AS groupid
    ,YEAR(orderdate) AS orderyear
    ,MONTH(orderdate) AS ordermonth
    ,SUM(val) AS salesvalue
FROM Sales.OrderValues
GROUP BY CUBE (YEAR(orderdate), MONTH(orderdate))
ORDER BY
    groupid
    ,orderyear
    ,ordermonth

-- GROUPING SETS: define explicitamente os conjuntos de agrupamento
SELECT
    country
    ,city
    ,COUNT(custid) AS noofcustomers
FROM Sales.Customers
GROUP BY GROUPING SETS
(
    (country, city)
    ,(country)
    ,(city)
    ,()
)

-- ROLLUP: gera hierarquia de agrupamentos (ano > mês > dia)
SELECT
    YEAR(orderdate) AS orderyear
    ,MONTH(orderdate) AS ordermonth
    ,DAY(orderdate) AS orderday
    ,SUM(val) AS salesvalue
FROM Sales.OrderValues
GROUP BY ROLLUP (YEAR(orderdate), MONTH(orderdate), DAY(orderdate))

-- CUBE: gera todas as combinações hierárquicas (ano, mês, dia)
SELECT
    YEAR(orderdate) AS orderyear
    ,MONTH(orderdate) AS ordermonth
    ,DAY(orderdate) AS orderday
    ,SUM(val) AS salesvalue
FROM Sales.OrderValues
GROUP BY CUBE (YEAR(orderdate), MONTH(orderdate), DAY(orderdate))


-- ============================================================
-- SEÇÃO 5: MAIS EXERCÍCIOS COM WINDOW FUNCTIONS
-- FIRST_VALUE, LAST_VALUE, PERCENT_RANK, CUME_DIST
-- ============================================================
-- Declaração da variável @Tab1 para exemplos com diversas funções
DECLARE @Tab1 TABLE
(
    Col1 INT
)

INSERT INTO @Tab1
VALUES
    (5)
    ,(5)
    ,(3)
    ,(1)

-- Utilizando a Windows Function First_Value
SELECT
    Col1
    ,FIRST_VALUE(Col1) OVER (ORDER BY Col1) AS [FIRST]
FROM @Tab1

-- Utilizando a Windows Function Last_Value
SELECT
    Col1
    ,LAST_VALUE(Col1) OVER (ORDER BY Col1 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS [LAST]
FROM @Tab1

-- Utilizando a Windows Function Percent_Rank
SELECT
    Col1
    ,PERCENT_RANK() OVER (ORDER BY Col1) AS [PERCENT_RANK()]
    ,RANK() OVER (ORDER BY Col1) AS [RANK()]
    ,(
        SELECT COUNT(*)
        FROM @Tab1
    ) AS [COUNT]
FROM @Tab1

-- Utilizando a Windows Function Cume_Dist (CUME_DIST é semelhante à função PERCENT_RANK)
SELECT
    Col1
    ,CUME_DIST() OVER (ORDER BY Col1) AS [CUME_DIST()]
FROM @Tab1


-- ============================================================
-- SEÇÃO 6: EXEMPLOS COM LAG E LEAD
-- Funções de deslocamento em séries temporais
-- ============================================================
-- Declaração da variável do tipo Table para exemplos com LAG/LEAD
DECLARE @Valores TABLE
(
    Data DATE
    ,Valor DECIMAL(4, 2)
)

-- Inserindo valores na variável
INSERT INTO @Valores
VALUES
    ('2012-04-01', 0.55)
    ,('2012-05-01', 4.07)
    ,('2012-06-01', 10.22)
    ,('2012-07-01', 2.59)
    ,('2012-08-01', 5.29)

-- Utilizando as Windows Function Lag e Lead
SELECT
    Data
    ,Valor
    ,LAG(Valor) OVER (ORDER BY Data) AS [Posição Inicial]
    ,LEAD(Valor) OVER (ORDER BY Data) AS [Posição Posterior]
    ,LAG(Valor, 2) OVER (ORDER BY Data) AS [Posição Intermediária]
    ,LEAD(Valor, 3) OVER (ORDER BY Data) AS [Posição Final]
FROM @Valores


-- ============================================================
-- SEÇÃO 7: TABELA ESTUDANTES
-- Exemplos completos de ROW_NUMBER, RANK, DENSE_RANK e NTILE
-- ============================================================
-- Criando exemplos com a Tabela Estudantes
CREATE TABLE Estudantes
(
    Id INT PRIMARY KEY IDENTITY(1, 1)
    ,Nome VARCHAR(20) NOT NULL
    ,Classificacao TINYINT NOT NULL
    ,Curso VARCHAR(20) NOT NULL
)
GO

-- truncate table Estudantes

-- Inserindo os dados
INSERT INTO Estudantes (Nome, Classificacao, Curso)
VALUES
    ('Kim', 99, 'Inglês')
    ,('Thomas', 95, 'Inglês')
    ,('Jonh', 92, 'Inglês')
    ,('Mag', 97, 'Espanhol')
    ,('Sussy', 90, 'Espanhol')
    ,('Boby', 91, 'Português')
    ,('Darth', 89, 'Português')

-- Realizando o Ranking dos Dados - Criando uma Sequência Numérica
-- Row_Number() Over (Order By)
SELECT
    ROW_NUMBER() OVER (ORDER BY Classificacao DESC) AS [Ordem de Classificação]
    ,Nome
    ,Curso
    ,Classificacao
FROM Estudantes
GO

-- Row_Number() Over (Partition By)
SELECT
    ROW_NUMBER() OVER (PARTITION BY Curso ORDER BY Classificacao DESC) AS [Ordem de Classificação]
    ,Nome
    ,Curso
    ,Classificacao
FROM Estudantes
GO

-- Rank() Over (Order By)
SELECT
    RANK() OVER (ORDER BY Curso) AS [Ranking Por Curso]
    ,Nome
    ,Classificacao
    ,Curso
FROM Estudantes
GO

-- Rank() Over (Partition By)
SELECT
    RANK() OVER (PARTITION BY Curso ORDER BY Classificacao) AS [Ranking Por Curso e Classificação]
    ,Nome
    ,Classificacao
    ,Curso
FROM Estudantes
GO

-- Dense_Rank() Over (Order By)
SELECT
    DENSE_RANK() OVER (ORDER BY Curso) AS [Ranking]
    ,Nome
    ,Classificacao
    ,Curso
FROM Estudantes
GO

-- Dense_Rank() Over (Partition By)
SELECT
    DENSE_RANK() OVER (PARTITION BY Curso ORDER BY Classificacao) AS [Ranking Por Curso e Classificação]
    ,Nome
    ,Classificacao
    ,Curso
FROM Estudantes
GO

-- NTile Over (Order By)
SELECT
    NTILE(2) OVER (ORDER BY Curso) AS [Distribuição de Linhas por Curso]
    ,Nome
    ,Classificacao
    ,Curso
FROM Estudantes
GO

-- NTile Over (Partition By)
SELECT
    NTILE(2) OVER (PARTITION BY Curso ORDER BY Classificacao) AS [Distribuição de Linhas por Curso e Classificação]
    ,Nome
    ,Classificacao
    ,Curso
FROM Estudantes
GO

-- Utilizando todas as funções
SELECT
    Id
    ,Nome
    ,Classificacao
    ,Curso
    ,ROW_NUMBER() OVER (ORDER BY Curso) AS [Row Number]
    ,RANK() OVER (ORDER BY Curso) AS [Rank]
    ,DENSE_RANK() OVER (ORDER BY Curso) AS [Dense Rank]
    ,NTILE(4) OVER (ORDER BY Curso) AS [NTile]
FROM Estudantes
GO


-- ============================================================
-- SEÇÃO 8: TABELA TEMPORÁRIA #TMP
-- Comparação entre RANGE e ROWS em funções de janela
-- ============================================================
-- Criando exemplos com a Tabela temporária #TMP
CREATE TABLE #TMP
(
    ID INT
    ,Col1 CHAR(1)
    ,Col2 INT
)
GO

-- Inserindo os Dados na Tabela Temporária #TMP
INSERT INTO #TMP
VALUES
     (1, 'A', 5)
    ,(2, 'A', 5)
    ,(3, 'B', 5)
    ,(4, 'C', 5)
    ,(5, 'D', 5)
GO

-- Utilizando a Windows Function Range e Rows
SELECT
    *
    ,SUM(Col2) OVER (ORDER BY Col1 RANGE UNBOUNDED PRECEDING) AS [Range]
    ,SUM(Col2) OVER (ORDER BY Col1 ROWS UNBOUNDED PRECEDING) AS [Rows]
FROM #TMP

DROP TABLE #TMP
