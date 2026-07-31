/*
 *
    OBJETIVO: Função para formatação de valores monetários, convertendo números float
              para o formato de moeda brasileiro (R$ 1.234.567,89).
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS: Júnior Galvão    
 *
 */
-- ======================================================================================================
-- FUNÇÃO: fn_FormatIntToMoney
-- Converte um valor FLOAT para o formato de moeda brasileiro com separadores
-- ======================================================================================================
CREATE OR ALTER FUNCTION Erp.fn_FormatIntToMoney
(
    @Valor FLOAT
)
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
    -- Converte para MONEY, aplica formatação com separadores,
    -- troca ponto por 'x' e vírgula por ponto, depois x por vírgula
    RETURN REPLACE(
               REPLACE(
                   REPLACE(
                       CONVERT(VARCHAR, CONVERT(MONEY, @Valor), 1),
                       '.',
                       'x'
                   ),
                   ',',
                   '.'
               ),
               'x',
               ','
           )
END
GO


-- ======================================================================================================
-- EXEMPLO DE TESTE DA FUNÇÃO
-- ======================================================================================================
DECLARE @Valores TABLE (ValorTotal FLOAT)
INSERT INTO @Valores VALUES (2042993.77), (1631290.05), (1020.44), (4332.30)

SELECT
    Management.fn_FormatIntToMoney(ValorTotal) AS formatado
FROM
    @Valores
GO
-- Resultado: 2.042.993,77 / 1.631.290,05 / 1.020,44 / 4.332,30
