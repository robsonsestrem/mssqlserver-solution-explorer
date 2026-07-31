/*
 *
	OBJETIVO: Demonstração de cálculo do último dia do mês atual no SQL Server
			  utilizando funções de data para obter o mês e ano atuais,
			  construindo a data final com DATEADD e subtração de um dia.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Obtendo o último dia do mês
-- ============================================================
DECLARE @Mes INT
DECLARE @Ano INT
DECLARE @DataFinal DATE

SET @Mes = MONTH(GETDATE())
SET @Ano = YEAR(GETDATE())

-- Calcula o último dia do mês: adiciona mês e ano à data base, depois subtrai 1 dia
SET @DataFinal = DATEADD(YEAR, @Ano - 1900, DATEADD(MONTH, @Mes, 0)) - 1

SELECT
    CONVERT(VARCHAR, @DataFinal, 103) AS [Último dia de um determinado mês]
GO
