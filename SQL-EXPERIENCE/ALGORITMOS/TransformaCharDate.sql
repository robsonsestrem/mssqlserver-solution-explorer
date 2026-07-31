/*
 *
	OBJETIVO: Demonstração de técnicas de conversão de colunas CHAR(24) contendo
			  valores de data/hora para tipos DATE e TIME, explorando diferentes
			  abordagens de CAST e CONVERT com estilos de formatação.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.sqlservercentral.com/Forums/Topic1526592-392-1.aspx
 */
-- ============================================================
-- Conversão de CHAR para DATE/TIME
-- ============================================================

-- Configuração do formato de data para o batch atual
SET DATEFORMAT DMY

-- ============================================================
-- CONSULTA ATIVA: Conversão de CHAR(24) para DATE
-- ============================================================

-- Extrai apenas a parte da data de uma coluna CHAR(24) contendo timestamp completo
SELECT 
    CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) AS [Date]
FROM dbo.CounterData
GO

-- ============================================================
-- CONSULTAS DE REFERÊNCIA
-- Abordagens alternativas documentadas para uso futuro
-- ============================================================

-- Abordagem 01: Conversão com separação explícita de Date e Time
;WITH SampleData AS
(
    SELECT CAST('2013-12-30 12:09:00.123' AS CHAR(24)) AS CounterDateTime
)
SELECT 
    CONVERT(VARCHAR(10), CONVERT(DATETIME, CounterDateTime), 101) AS Date
    ,CONVERT(VARCHAR(5), CONVERT(DATETIME, CounterDateTime), 108)
        + ' '
        + SUBSTRING(CONVERT(VARCHAR(19), CONVERT(DATETIME, CounterDateTime), 100), 18, 2) AS Time
FROM SampleData
GO


-- Abordagem 02: Conversão direta para VARCHAR com extração via SUBSTRING
;WITH SampleData AS
(
    SELECT CAST('2013-12-30 12:09:00.123' AS CHAR(24)) AS CounterDateTime
)
SELECT 
    CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS Date
    ,SUBSTRING(CONVERT(VARCHAR(19), CounterDateTime, 100), 12, 5) AS Time
    ,CONVERT(DATE, CounterDateTime) AS RealDate
    ,CONVERT(TIME, CounterDateTime) AS RealTime
FROM SampleData
GO


-- Abordagem 03: CTE com conversão explícita para DATETIME
;WITH mySampleData(TheDate) AS
(
    SELECT CONVERT(DATETIME, '2013-12-30 12:09:00.123')
)
SELECT 
    CONVERT(DATE, TheDate) AS RealDate
    ,CONVERT(TIME, TheDate, 108) AS RealTime
    ,CONVERT(VARCHAR, TheDate, 101) AS SimpleDate
    ,CONVERT(VARCHAR, TheDate, 108) AS SimpleTime
FROM mySampleData
GO
