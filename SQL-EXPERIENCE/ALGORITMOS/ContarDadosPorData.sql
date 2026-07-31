/*
 *
	OBJETIVO: Contagem de registros agrupados por data, demonstrando duas técnicas
			  distintas para normalização temporal (remoção da parte horária):
			  conversão explícita para DATE e uso de FLOOR com CAST para DATETIME.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/t-sql/functions/date-and-time-data-types-and-functions-transact-sql
 */
-- ============================================================
-- Contagem de Dados por Data: 
-- Técnicas de Normalização Temporal
-- ============================================================

-- ============================================================
-- OPÇÃO 01: Zera o time convertendo explicitamente para DATE
-- ============================================================

-- Conversão direta para DATE remove automaticamente a parte horária
SELECT 
    x.Data
    ,COUNT(*) AS DadosTotais
FROM
(
    SELECT CAST(t1.DateReference AS DATE) AS Data
    FROM Management.HistoryIndexFragmentation AS t1
) AS x
GROUP BY x.Data
ORDER BY x.Data DESC

-- ============================================================
-- OPÇÃO 02: Zera o time com FLOOR e 
-- agrupamento otimizado com SUBSTRING
-- ============================================================

-- FLOOR converte DATETIME para FLOAT e trunca a parte decimal (horário)
-- SUBSTRING extrai o mês para agrupamento adicional
SELECT 
    x.TimeZerado
    ,COUNT(*) AS TotalRegistros
FROM
(
    SELECT CAST(FLOOR(CAST(t1.DateReference AS FLOAT)) AS DATETIME) AS TimeZerado
    FROM IntegraTICravil.Management.HistoryIndexFragmentation AS t1
) AS x
GROUP BY 
    SUBSTRING(CONVERT(VARCHAR(10), x.TimeZerado, 103), 4, 2)
    ,x.TimeZerado
ORDER BY x.TimeZerado DESC
