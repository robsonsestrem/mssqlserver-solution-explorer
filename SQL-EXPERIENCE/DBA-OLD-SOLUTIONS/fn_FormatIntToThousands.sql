/*
 *
    OBJETIVO: Função para formatação de valores inteiros com separadores de milhar.
              Permite escolher entre vírgula ou ponto como separador de milhar.
    PROJETO: mssqlserver-solution-explorer

    PARÂMETROS:
    - @Valor: Número do tipo BIGINT a ser formatado
    - @separador: 1 = Vírgula como separador de milhar / 2 = Ponto como separador de milhar

    LIMITAÇÕES:
    - 15 caracteres é o limite para o BIGINT, com os separadores fica 19 caracteres no total
    - O limite de 20 caracteres no SUBSTRING foi definido para acomodar o tamanho máximo
 *
 */
-- ================================================================================================================================
-- FUNÇÃO: fn_FormatIntToThousands
-- Formata valores BIGINT com separadores de milhar
-- ================================================================================================================================
CREATE OR ALTER FUNCTION Management.fn_FormatIntToThousands
(
    @Valor BIGINT,
    @separador TINYINT
)
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
    RETURN
        CASE
            -- Formata com vírgula como separador de milhar
            WHEN @separador = 1
            THEN REVERSE(
                     SUBSTRING(
                         REVERSE(
                             CONVERT(
                                 VARCHAR(30),
                                 CONVERT(MONEY, @valor),
                                 1
                             )
                         ),
                         4,
                         20
                     )
                 )

            -- Formata com ponto como separador de milhar
            WHEN @separador = 2
            THEN REPLACE(
                     REVERSE(
                         SUBSTRING(
                             REVERSE(
                                 CONVERT(
                                     VARCHAR(30),
                                     CONVERT(MONEY, @valor),
                                     1
                                 )
                             ),
                             4,
                             20
                         )
                     ),
                     ',',
                     '.'
                 )

            -- Retorna o valor como string sem formatação
            ELSE CAST(@Valor AS VARCHAR(30))
        END
END
GO


-- ================================================================================================================================
-- EXEMPLO DE TESTE DA FUNÇÃO
-- ================================================================================================================================
SELECT
    Management.fn_FormatIntToThousands(1234567890, 1) AS FormatoVirgula,
    Management.fn_FormatIntToThousands(1234567890, 2) AS FormatoPonto,
    Management.fn_FormatIntToThousands(1234567890, 3) AS SemFormatacao
GO

-- Resultados esperados:
-- FormatoVirgula: 1.234.567.890
-- FormatoPonto:   1,234,567,890
-- SemFormatacao:  1234567890
