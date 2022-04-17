------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exerc�cios com Rank
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/*
LAG/LEAD (scalar_expression [,offset] [,default])
    OVER ( [ partition_by_clause ] order_by_clause )
	1� par�metro -> valor escalar
	2� par�metro -> quantidade voltar/pr�ximo
	3� par�metro -> valor padr�o caso seja nulo
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
  -- no dense_rank s� muda a forma de contar (ele repetiri se tivesse valores iguais)
 ,DENSE_RANK() OVER (PARTITION BY custid ORDER BY val DESC) AS DenseRank
FROM OrderValues


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exerc�cios com valores
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
;
WITH vendasPorMes2007
AS
(SELECT
    MONTH(orderdate) AS monthno
   ,SUM(val) AS val
  FROM OrderValues
  WHERE orderdate >= '20070101'
  AND orderdate < '20080101'
  GROUP BY MONTH(orderdate)),
manipulacao
AS
(SELECT
    monthno
   ,Val
   ,LAG(val) OVER (ORDER BY monthno) AS Anterior
   ,LEAD(val) OVER (ORDER BY monthno) AS Proximo
    -- na 4� linha terei o c�culo certo, pois vai ser poss�vel fazer a m�dia dos 3 anteriores (forma ainda engessada)
   ,(LAG(val, 1, 0) OVER (ORDER BY monthno) + LAG(val, 2, 0) OVER (ORDER BY monthno) + LAG(val, 3, 0) OVER (ORDER BY monthno)) / 3 AS Media3UltimosMeses
    -- neste caso tenho a m�dia calculada para 4 meses, ele pega os 3 anteriores e a linha atual (� mais din�mico)
   ,AVG(val) OVER (ORDER BY monthno ROWS BETWEEN 3 PRECEDING AND CURRENT ROW) AS Media3UltimosMesesEAtual
    -- somat�ria ascendente dos valores, total de valores at� a linha atual, �ltimo valor mostra valor total dos 12 meses
   ,SUM(val) OVER (ORDER BY monthno ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Somat�ria
    -- usado "val" da fun��o FIRST_VALUE para subtrair com os outros valores sequenciais 
   ,val - FIRST_VALUE(val) OVER (ORDER BY monthno ROWS UNBOUNDED PRECEDING) AS DifValorAtualComJaneiro
    -- �timo valor da coluna "val"
   ,LAST_VALUE(val) OVER (ORDER BY val ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS 'LAST_VAL'
    -- Primeiro valor da coluna "val"
   ,FIRST_VALUE(val) OVER (ORDER BY val ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS 'FIRST_VAL'

  FROM vendasPorMes2007)
SELECT
  *
  -- �ltimo valor da coluna "somat�ria" � o total e com isso � poss�vel fazer o percentual
 ,100. * t3.val / LAST_VALUE(t3.Somat�ria) OVER (ORDER BY t3.Somat�ria ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS PercentualDoTotal
FROM manipulacao AS t3


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Teste com soma progressiva
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  custid
 ,orderid
 ,orderdate
 ,val
 ,
  -- Traz percentual deste "val" na linha em rela��o com o "val" total por cliente
  100. * val / SUM(val) OVER (PARTITION BY custid) AS percoftotalcust
 ,
  -- Realiza somat�ria ascendente dos "val" por cliente ordenado por data e pedido
  SUM(val) OVER (PARTITION BY custid ORDER BY orderdate, orderid ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS [SomaValoresAt�LinhaAtual]
FROM OrderValues;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exerc�cios com GROUPING SETS; ROLLUP; CUBE
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------		
SELECT
  GROUPING_ID(YEAR(orderdate), MONTH(orderdate)) AS groupid
 ,YEAR(orderdate) AS orderyear
 ,MONTH(orderdate) AS ordermonth
 ,SUM(val) AS salesvalue
FROM Sales.OrderValues
GROUP BY CUBE (YEAR(orderdate), MONTH(orderdate)) -- ou rollup
ORDER BY groupid, orderyear, ordermonth;

SELECT
  country
 ,city
 ,COUNT(custid) AS noofcustomers
FROM Sales.Customers
GROUP BY GROUPING SETS
(
(country, city),
(country),
(city),
()
);


SELECT
  YEAR(orderdate) AS orderyear
 ,MONTH(orderdate) AS ordermonth
 ,DAY(orderdate) AS orderday
 ,SUM(val) AS salesvalue
FROM Sales.OrderValues
GROUP BY ROLLUP (YEAR(orderdate), MONTH(orderdate), DAY(orderdate));


SELECT
  YEAR(orderdate) AS orderyear
 ,MONTH(orderdate) AS ordermonth
 ,DAY(orderdate) AS orderday
 ,SUM(val) AS salesvalue
FROM Sales.OrderValues
GROUP BY CUBE (YEAR(orderdate), MONTH(orderdate), DAY(orderdate));


------------------------------------------------------------------------------------------------------------------------------------------------------
/* Mais exerc�cios com windows function */
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Declarando a vari�vel @Tab1 para exemplos com diversas fun��es --
DECLARE @Tab1 TABLE (
  Col1 INT
)

INSERT INTO @Tab1
  VALUES (5), (5), (3), (1)

-- Utilizando a Windows Function First_Value --
SELECT
  Col1
 ,FIRST_VALUE(Col1) OVER (ORDER BY Col1) AS 'FIRST'
FROM @Tab1
-- Utilizando a Windows Function Last_Value --
SELECT
  Col1
 ,LAST_VALUE(Col1) OVER (ORDER BY Col1 ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS 'LAST'
FROM @Tab1
-- Utilizando a Windows Function Percent_Rank --
SELECT
  Col1
 ,PERCENT_RANK() OVER (ORDER BY Col1) AS 'PERCENT_RANK()'
 ,RANK() OVER (ORDER BY Col1) AS 'RANK()'
 ,(SELECT
      COUNT(*)
    FROM @Tab1)
  'COUNT'
FROM @Tab1
-- Utilizando a Windows Function Cume_Dist -- CUME_DIST � semelhante � fun��o PERCENT_RANK.
SELECT
  Col1
 ,CUME_DIST() OVER (ORDER BY Col1) AS 'CUME_DIST()'
FROM @Tab1


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Declarando a vari�vel do tipo Table para exemplos com LAG; LEAD --
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Valores TABLE (
  Data DATE
 ,Valor DECIMAL(4, 2)
)

-- Inserindo valores na vari�vel --
INSERT INTO @Valores
  VALUES ('2012-04-01', 0.55),
  ('2012-05-01', 4.07), ('2012-06-01', 10.22),
  ('2012-07-01', 2.59), ('2012-08-01', 5.29)

-- Utilizando as Windows Function Lag e Lead --
SELECT
  Data
 ,Valor
 ,LAG(Valor) OVER (ORDER BY Data) AS 'Posi��o Inicial'
 ,LEAD(Valor) OVER (ORDER BY Data) AS 'Posi��o Posterior'
 ,LAG(Valor, 2) OVER (ORDER BY Data) AS 'Posi��o Intermedi�ria'
 ,LEAD(Valor, 3) OVER (ORDER BY Data) AS 'Posi��o Final'
FROM @Valores


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Criando exemplos com a Tabela Estudantes --
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Estudantes (
  Id INT PRIMARY KEY IDENTITY (1, 1)
 ,Nome VARCHAR(20) NOT NULL
 ,Classificacao TINYINT NOT NULL
 ,Curso VARCHAR(20) NOT NULL
)
GO
-- truncate table Estudantes

-- Inserindo os dados --
INSERT INTO Estudantes (Nome, Classificacao, Curso)
  VALUES ('Kim', 99, 'Ingl�s'),
  ('Thomas', 95, 'Ingl�s'),
  ('Jonh', 92, 'Ingl�s'),
  ('Mag', 97, 'Espanhol'),
  ('Sussy', 90, 'Espanhol'),
  ('Boby', 91, 'Portugu�s'),
  ('Darth', 89, 'Portugu�s')


-- Realizando o Ranking dos Dados - Criando uma Sequ�ncia Num�rica --
-- Row_Number() Over (Order By) --
SELECT
  ROW_NUMBER() OVER (ORDER BY Classificacao DESC) AS 'Ordem de Classifica��o'
 ,Nome
 ,Curso
 ,Classificacao
FROM Estudantes
GO

-- Row_Number() Over (Partition By) --
SELECT
  ROW_NUMBER() OVER (PARTITION BY Curso ORDER BY Classificacao DESC) AS 'Ordem de Classifica��o'
 ,Nome
 ,Curso
 ,Classificacao
FROM Estudantes
GO

-- Rank() Over (Order By) --
SELECT
  RANK() OVER (ORDER BY Curso) AS 'Ranking Por Curso'
 ,Nome
 ,Classificacao
 ,Curso
FROM Estudantes
GO

-- Rank() Over (Partition By) --
SELECT
  RANK() OVER (PARTITION BY Curso ORDER BY Classificacao) AS 'Ranking Por Curso e Classifica��o'
 ,Nome
 ,Classificacao
 ,Curso
FROM Estudantes
GO

-- Dense_Rank() Over (Order By) --
SELECT
  DENSE_RANK() OVER (ORDER BY Curso) AS 'Ranking'
 ,Nome
 ,Classificacao
 ,Curso
FROM Estudantes
GO

-- Dense_Rank() Over (Partition By) --
SELECT
  DENSE_RANK() OVER (PARTITION BY Curso ORDER BY Classificacao) AS 'Ranking Por Curso e Classifica��o'
 ,Nome
 ,Classificacao
 ,Curso
FROM Estudantes
GO

-- NTile Over (Order By) --
SELECT
  NTILE(2) OVER (ORDER BY Curso) AS 'Distribui��o de Linhas por Curso'
 ,Nome
 ,Classificacao
 ,Curso
FROM Estudantes
GO

-- NTile Over (Partition By) --
SELECT
  NTILE(2) OVER (PARTITION BY Curso ORDER BY Classificacao) AS 'Distribui��o de Linhas por Curso e Classifica��o'
 ,Nome
 ,Classificacao
 ,Curso
FROM Estudantes
GO

-- Utilizando todas as fun��es --
SELECT
  Id
 ,Nome
 ,Classificacao
 ,Curso
 ,ROW_NUMBER() OVER (ORDER BY Curso) AS 'Row Number'
 ,RANK() OVER (ORDER BY Curso) AS 'Rank'
 ,DENSE_RANK() OVER (ORDER BY Curso) AS 'Dense Rank'
 ,NTILE(4) OVER (ORDER BY Curso) AS 'NTile'
FROM Estudantes
GO


------------------------------------------------------------------------------------------------------------------------------------------------------ 
-- Criando exemplos com a Tabela tempor�ria #TMP --
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #TMP (
  ID INT
 ,Col1 CHAR(1)
 ,Col2 INT
)
GO

-- Inserindo os Dados na Tabela Tempor�ria #TMP --
INSERT INTO #TMP
  VALUES (1, 'A', 5),
  (2, 'A', 5),
  (3, 'B', 5),
  (4, 'C', 5),
  (5, 'D', 5)
GO

-- Utilizando a Windows Function Range e Rows --
SELECT
  *
 ,SUM(Col2) OVER (ORDER BY Col1 RANGE UNBOUNDED PRECEDING) AS 'Range'
 ,SUM(Col2) OVER (ORDER BY Col1 ROWS UNBOUNDED PRECEDING) 'Rows'
FROM #TMP
DROP TABLE #TMP






