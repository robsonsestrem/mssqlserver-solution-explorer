/*
 *
	OBJETIVO: Validação de CPF e CNPJ através do cálculo dos dígitos verificadores,
	          retornando 'TRUE' quando válido e 'FALSE' quando inválido.
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Validação de CPF e CNPJ
-- ============================================================
USE [YOUR_DATABASE];
GO

-- Criação da função de validação de CPF/CNPJ
CREATE OR ALTER FUNCTION [System].[fn_ValidCPF_CNPJ]
(
    @validar VARCHAR(30)
)
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @CPF_CNPJ NVARCHAR(30);
    DECLARE @size BIT;

    -- Remove caracteres não numéricos do documento
    SET @CPF_CNPJ = [System].[fn_OnlyNumber](@validar);

    -- Validação do tamanho (CPF = 11 dígitos, CNPJ = 14 dígitos)
    IF (LEN(@CPF_CNPJ) NOT IN (11, 14))
    BEGIN
        SET @size = 0;
    END
    ELSE
    BEGIN
        SET @size = 1;
    END

    DECLARE
        @DIGITO1 INT
      , @DIGITO2 INT
      , @VALOR1 INT
      , @VALOR2 INT;

    DECLARE
        @I INT
      , @J INT
      , @TOTAL_TMP INT
      , @COEFICIENTE_TMP INT
      , @DIGITO_TMP INT
      , @VALOR_TMP INT;

    -- Extrai os dois dígitos verificadores do final do documento
    SET @DIGITO1 = SUBSTRING(@CPF_CNPJ, LEN(@CPF_CNPJ) - 1, 1);
    SET @DIGITO2 = SUBSTRING(@CPF_CNPJ, LEN(@CPF_CNPJ), 1);
    SET @J = 1;

    -- Loop para cálculo dos dois dígitos verificadores
    WHILE (@J <= 2)
    BEGIN
        SELECT
            @TOTAL_TMP = 0
          , @COEFICIENTE_TMP = 2;

        SET @I = ((LEN(@CPF_CNPJ) - 3) + @J);

        -- Cálculo do dígito verificador através da soma ponderada
        WHILE (@I >= 0)
        BEGIN
            SELECT
                @DIGITO_TMP = SUBSTRING(@CPF_CNPJ, @I, 1)
              , @TOTAL_TMP = @TOTAL_TMP + (@DIGITO_TMP * @COEFICIENTE_TMP)
              , @COEFICIENTE_TMP = @COEFICIENTE_TMP + 1;

            -- Para CNPJ, o coeficiente reinicia em 2 após atingir 9
            IF (@COEFICIENTE_TMP > 9)
                AND (LEN(@CPF_CNPJ) = 14)
            BEGIN
                SET @COEFICIENTE_TMP = 2;
            END

            SET @I = @I - 1;
        END

        -- Cálculo do dígito verificador esperado
        SET @VALOR_TMP = 11 - (@TOTAL_TMP % 11);

        IF (@VALOR_TMP >= 10)
        BEGIN
            SET @VALOR_TMP = 0;
        END

        -- Armazena o primeiro e segundo dígitos calculados
        IF (@J = 1)
        BEGIN
            SET @VALOR1 = @VALOR_TMP;
        END
        ELSE
        BEGIN
            SET @VALOR2 = @VALOR_TMP;
        END

        SET @J = @J + 1;
    END

    -- Retorna TRUE se ambos os dígitos conferem e o tamanho é válido
    RETURN
        CASE
            WHEN (@VALOR1 = @DIGITO1)
                AND (@VALOR2 = @DIGITO2)
                AND (@size = 1) THEN 'TRUE'
            WHEN (@VALOR1 = @DIGITO1)
                AND (@VALOR2 = @DIGITO2)
                AND (@size = 0) THEN 'FALSE'
            ELSE 'FALSE'
        END;
END
GO
