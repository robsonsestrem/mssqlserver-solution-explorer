USE [Maintenance]
GO

/*
OBJETIVO: Procedure responsável por retirar os caracteres inválidos para o XML.

-- EXEMPLO EXECUÇÃO
SELECT dbo.fncRetira_Caractere_Invalido_XML('teste')
*/

CREATE FUNCTION Management.[fncRetira_Caractere_Invalido_XML] (
	@Text VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
	DECLARE @Result NVARCHAR(4000)

	SELECT @Result = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
							(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
									(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
											(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE
													(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( 
																													@Text
													 ,NCHAR(1),N'?'),NCHAR(2),N'?'),NCHAR(3),N'?'),NCHAR(4),N'?'),NCHAR(5),N'?'),NCHAR(6),N'?')
											 ,NCHAR(7),N'?'),NCHAR(8),N'?'),NCHAR(11),N'?'),NCHAR(12),N'?'),NCHAR(14),N'?'),NCHAR(15),N'?')
									 ,NCHAR(16),N'?'),NCHAR(17),N'?'),NCHAR(18),N'?'),NCHAR(19),N'?'),NCHAR(20),N'?'),NCHAR(21),N'?')
							 ,NCHAR(22),N'?'),NCHAR(23),N'?'),NCHAR(24),N'?'),NCHAR(25),N'?'),NCHAR(26),N'?'),NCHAR(27),N'?')
						 ,NCHAR(28),N'?'),NCHAR(29),N'?'),NCHAR(30),N'?'),NCHAR(31),N'?');

	RETURN @Result
END


GO
