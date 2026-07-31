/*
 *
    OBJETIVO: Função para extrair apenas os caracteres numéricos (0-9) de uma string,
              removendo pontos, traços, barras e qualquer outro caractere não numérico.
    PROJETO: mssqlserver-solution-explorer
 *
 */
-- ================================================================================================================================
-- FUNÇÃO: fn_OnlyNumber
-- Extrai apenas os dígitos numéricos de uma string utilizando CTE recursiva
-- ================================================================================================================================
USE YOUR_DATABASE
GO

CREATE FUNCTION dbaSystem.fn_OnlyNumber
(
    @valor VARCHAR(30)
)
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @Result NVARCHAR(MAX)
    SET @Result = ''

    -- CTE recursiva para percorrer cada caractere da string
    ;WITH SPLIT AS
    (
        -- Caractere inicial (posição 1)
        SELECT
            1 AS ID,
            SUBSTRING(@valor, 1, 1) AS CH

        UNION ALL

        -- Próximos caracteres (posição ID + 1)
        SELECT
            ID + 1,
            SUBSTRING(@valor, ID + 1, 1)
        FROM
            SPLIT
        WHERE
            ID < LEN(@valor)
    )

    -- Concatena apenas os caracteres que são dígitos numéricos
    SELECT
        @Result += CH   -- Mesma lógica do Java (concatenação com +=)
    FROM
        SPLIT
    WHERE
        CH LIKE '[0-9]'
    OPTION (MAXRECURSION 0)   -- Permite recursão até o fim da string

    RETURN @Result
END
GO


-- ================================================================================================================================
-- EXEMPLO DE TESTE DA FUNÇÃO
-- ================================================================================================================================
SELECT
    dbaSystem.fn_OnlyNumber('417.932.349-49') AS CPF,
    dbaSystem.fn_OnlyNumber('(11) 98765-4321') AS Telefone,
    dbaSystem.fn_OnlyNumber('R$ 1.234,56') AS ValorNumerico
GO

-- Resultados esperados:
-- CPF:          41793234949
-- Telefone:     11987654321
-- ValorNumerico:123456
