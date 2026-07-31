/*
 *
	OBJETIVO: Função scalar para remoção de caracteres especiais e acentuação
			  de uma string no SQL Server, mantendo apenas letras (a-z, A-Z),
			  números (0-9) e espaços em branco.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.dirceuresende.com/blog/como-remover-acentuacao-e-caracteres-especiais-de-uma-string-no-sql-server/
 */
-- ============================================================
-- Função de Remoção de Caracteres Especiais
-- ============================================================
USE YOUR_DATABASE
GO

CREATE FUNCTION System.fn_RemoveSpecialCharacters
(
    @String AS VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
WITH ENCRYPTION
AS
BEGIN
    DECLARE
        @Result AS VARCHAR(MAX)
        , @StartingIndex AS INT = 0

    -- Loop para remover cada caractere especial encontrado
    WHILE (1 = 1)
    BEGIN
        SET @StartingIndex = PATINDEX('%[^a-Z|0-9|^ ]%', @String)

        IF (@StartingIndex <> 0)
            SET @String = REPLACE(@String, SUBSTRING(@String, @StartingIndex, 1), '')
        ELSE
            BREAK
    END

    -- Remove o caractere pipe (|) usado como separador no PATINDEX
    SET @Result = REPLACE(@String, '|', '')

    RETURN @Result
END
GO
