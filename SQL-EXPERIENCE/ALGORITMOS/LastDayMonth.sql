------------------------------------------------------------------------------
--Obtendo o último dia do mês:
------------------------------------------------------------------------------


 DECLARE @Mes Int,
@Ano Int,
@DataFinal Date
 
Set @Mes = Month(GetDate())
Set @Ano = Year(GetDate())
 
Set @DataFinal = DATEADD(YEAR, @Ano - 1900, DATEADD(MONTH, @Mes, 0)) - 1
 
SELECT CONVERT(VARCHAR, @DataFinal, 103) AS [Último dia de um determinado mês]
GO

