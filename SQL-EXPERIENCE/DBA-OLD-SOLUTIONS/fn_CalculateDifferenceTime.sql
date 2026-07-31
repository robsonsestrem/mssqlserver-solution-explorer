/*
 *
	OBJETIVO: Função scalar para cálculo de diferença de tempo entre dois
			  valores DATETIME, retornando o resultado formatado como
			  "dias hh:mm:ss" (ex: "179 02:40:10").
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ======================================================================================================
-- Função de Cálculo de Diferença de Tempo
-- ======================================================================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER FUNCTION Management.fn_CalculateDifferenceTime
(
    @antes AS DATETIME
    , @depois AS DATETIME
)
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
    DECLARE
        @result AS VARCHAR(30)
        , @temp AS DATETIME

    -- Inverte os valores se @antes for maior que @depois
    IF (@antes > @depois)
    BEGIN
        SET @temp = @antes
        SET @antes = @depois
        SET @depois = @temp
    END

    -- Calcula a diferença em segundos e formata como "dias hh:mm:ss"
    SET @result = (
        CONVERT(VARCHAR, ABS(DATEDIFF(SECOND, @antes, @depois) / 60 / 60 / 24))
        + ' ' + RIGHT('00' + CONVERT(VARCHAR, ABS(((DATEDIFF(SECOND, @antes, @depois) / 60) / 60) % 24)), 2)
        + ':' + RIGHT('00' + CONVERT(VARCHAR, ABS((DATEDIFF(SECOND, @antes, @depois) / 60) % 60)), 2)
        + ':' + RIGHT('00' + CONVERT(VARCHAR, ABS(DATEDIFF(SECOND, @antes, @depois) % 60)), 2)
    )

    RETURN @result
END
GO


-- ======================================================================================================
-- Teste para calcular tempo
-- ======================================================================================================
USE YOUR_DATABASE
GO
DECLARE @antes AS DATETIME = '2013-11-29 11:30:40.157'
DECLARE @depois AS DATETIME = '2014-05-27 14:10:50.637'

SELECT Management.fn_CalculateDifferenceTime(@antes, @depois)

