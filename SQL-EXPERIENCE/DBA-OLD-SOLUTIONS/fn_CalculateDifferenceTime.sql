USE Maintenance
GO

CREATE OR ALTER FUNCTION Management.fn_CalculateDifferenceTime 
(
    @antes DATETIME, @depois DATETIME
)
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @result VARCHAR(30)
          , @temp DATETIME;
    IF (@antes > @depois)
		BEGIN
			SET @temp = @antes;
			SET @antes = @depois;
			SET @depois = @temp;
		END
	
	SET @result = ( CONVERT(VARCHAR, ABS(DATEDIFF(SECOND, @antes, @depois) / 60 / 60 / 24))
						+ ' ' + RIGHT('00' + CONVERT(VARCHAR, ABS(((DATEDIFF(SECOND, @antes, @depois) / 60) / 60) % 24)), 2) 
						+ ':' + RIGHT('00' + CONVERT(VARCHAR, ABS((DATEDIFF(SECOND, @antes, @depois) / 60) % 60)), 2) 
						+ ':' + RIGHT('00' + CONVERT(VARCHAR, ABS(DATEDIFF(SECOND, @antes, @depois) % 60)), 2)
					  )
	RETURN @result
END

-------------------------------------------------------------------------------------------------------------------------------------------
-- Teste para calcular tempo
-------------------------------------------------------------------------------------------------------------------------------------------
--USE Maintenance
--GO
--DECLARE @antes DATETIME = '2013-11-29 11:30:40.157';
--DECLARE @depois DATETIME = '2014-05-27 14:10:50.637';

--SELECT Management.fn_CalculateDifferenceTime(@antes , @depois)