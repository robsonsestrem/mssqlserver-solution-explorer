/*
 *
	OBJETIVO: Função scalar para verificação se uma string contém apenas
			  dígitos numéricos (0-9), retornando 1 se for puramente numérica
			  ou 0 se contiver qualquer caractere não numérico.
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Função de Verificação de Dígitos Numéricos
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER FUNCTION System.fn_Isdigit
(
    @string AS VARCHAR(MAX)
)
RETURNS INT
WITH ENCRYPTION
AS
BEGIN
    -- Retorna 1 se a string contém apenas dígitos, 0 caso contrário
    RETURN
    (
        SELECT
            CASE
                WHEN PATINDEX('%[^0-9]%', @string) > 0 THEN
                    0
                ELSE
                    1
              END AS sp_isdigit
    )
END
GO


------------------------------------------------------------------
-- Exemplo de Uso
------------------------------------------------------------------
SELECT dbo.sp_isdigit('ISSO É UM VALOR NUMÉRICO?')  -- Retorna 0
SELECT dbo.sp_isdigit('3000')                       -- Retorna 1
SELECT dbo.sp_isdigit('2700.00')                    -- Retorna 0 (ponto não é dígito)
