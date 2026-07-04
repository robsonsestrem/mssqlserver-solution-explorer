/*
================================================================================
OBJETIVO: Function para validação de CPF/CNPJ via cálculo dos dígitos
		  verificadores. Inclui algoritmos exploratórios de extração de
		  caracteres por categoria (números, letras, especiais) com CTE recursiva.
PROJETO: mssqlserver-solution-explorer
================================================================================
*/

-- Referência: https://sqlfromhell.wordpress.com/tag/removendo-caracteres-especiais/

USE IntegraTICravil;
GO

-- Criação/alteração da function de validação de CPF e CNPJ
ALTER FUNCTION Management.fn_ValidCPF_CNPJ(@validar VARCHAR(30))
RETURNS VARCHAR(30)
WITH ENCRYPTION
AS
BEGIN
	DECLARE @CPF_CNPJ   NVARCHAR(30);
	DECLARE @size       BIT;

	-- Remove caracteres não numéricos e valida o comprimento (11 = CPF, 14 = CNPJ)
	SET @CPF_CNPJ = Management.fn_OnlyNumber(@validar);

	IF LEN(@CPF_CNPJ) NOT IN (11, 14)
		BEGIN
			SET @size = 0;
		END
	ELSE
		SET @size = 1;

	DECLARE
		@DIGITO1    INT
	   ,@DIGITO2    INT
	   ,@VALOR1     INT
	   ,@VALOR2     INT;

	DECLARE
		@I                  INT
	   ,@J                  INT
	   ,@TOTAL_TMP          INT
	   ,@COEFICIENTE_TMP    INT
	   ,@DIGITO_TMP         INT
	   ,@VALOR_TMP          INT;

	-- Captura os dois últimos dígitos verificadores da string numérica
	SET @DIGITO1 = SUBSTRING(@CPF_CNPJ, LEN(@CPF_CNPJ) - 1, 1);
	SET @DIGITO2 = SUBSTRING(@CPF_CNPJ, LEN(@CPF_CNPJ), 1);
	SET @J = 1;

	-- Loop externo: itera duas vezes para calcular cada dígito verificador
	WHILE @J <= 2
	BEGIN
		SELECT
			@TOTAL_TMP          = 0
		   ,@COEFICIENTE_TMP    = 2;

		SET @I = ((LEN(@CPF_CNPJ) - 3) + @J);

		-- Loop interno: percorre os dígitos aplicando os coeficientes de ponderação
		WHILE @I >= 0
		BEGIN
			SELECT
				@DIGITO_TMP         = SUBSTRING(@CPF_CNPJ, @I, 1)
			   ,@TOTAL_TMP          = @TOTAL_TMP + (@DIGITO_TMP * @COEFICIENTE_TMP)
			   ,@COEFICIENTE_TMP    = @COEFICIENTE_TMP + 1;

			-- Para CNPJ (14 dígitos): reinicia o coeficiente após atingir 9
			IF (@COEFICIENTE_TMP > 9) AND LEN(@CPF_CNPJ) = 14
				SET @COEFICIENTE_TMP = 2;

			SET @I = @I - 1;
		END;

		SET @VALOR_TMP = 11 - (@TOTAL_TMP % 11);

		IF (@VALOR_TMP >= 10)
			SET @VALOR_TMP = 0;

		IF @J = 1
			SET @VALOR1 = @VALOR_TMP;
		ELSE
			SET @VALOR2 = @VALOR_TMP;

		SET @J = @J + 1;
	END;

	-- Retorna TRUE apenas se ambos os dígitos conferem e o tamanho é válido
	RETURN
		CASE
			WHEN @VALOR1 = @DIGITO1 AND @VALOR2 = @DIGITO2 AND @size = 1 THEN 'TRUE'
			WHEN @VALOR1 = @DIGITO1 AND @VALOR2 = @DIGITO2 AND @size = 0 THEN 'FALSE'
			ELSE 'FALSE'
		END;
END;
GO


/*
================================================================================
ALGORITMOS EXPLORATÓRIOS
Extração de caracteres por categoria (números, letras, especiais) usando
CTE recursiva com acumulação via operador +=.
================================================================================
*/

-- Texto de exemplo para extração de caracteres por categoria
DECLARE @Texto2 NVARCHAR(MAX);
SET @Texto2 = N'O azul é uma das três cores-luz primárias,
e cor-pigmento secundária, resultado da sobreposição dos
pigmentos ciano e magenta. Seu comprimento de onda é da
ordem de 455 a 492 nanômetros do espectro de cores visíveis.';

DECLARE @Result NVARCHAR(MAX);
SET @Result = '';

-- CTE recursiva: decompõe o texto em caracteres individuais (um por linha)
;WITH SPLIT AS
(
    SELECT
        1                               AS ID
       ,SUBSTRING(@Texto2, 1, 1)        AS CH

    UNION ALL

    SELECT
        ID + 1
       ,SUBSTRING(@Texto2, ID + 1, 1)
    FROM SPLIT
    WHERE ID < LEN(@Texto2)
)
-- Acumula apenas os caracteres numéricos via operador += (equivalente ao Java)
SELECT @Result += CH
FROM SPLIT
WHERE CH LIKE '[0-9]'
OPTION (MAXRECURSION 0);

SELECT @Result AS [Resultado];

/*
-- OU SOMENTE LETRAS
SELECT @Result = @Result + CH
FROM SPLIT
WHERE CH LIKE '[A-z]'
OPTION (MAXRECURSION 0);
SELECT @Result AS [Resultado];
*/

/*
-- OU SOMENTE CARACTERES ESPECIAIS (retorna o que NÃO é letra nem número)
SELECT @Result = @Result + CH
FROM SPLIT
WHERE CH LIKE '[A-z0-9]'
OPTION (MAXRECURSION 0);
SELECT @Result AS [Resultado];
*/

/*
-- ESPECIAIS - mesmo resultado mas com CASE
SELECT @Result = @Result
    + (CASE WHEN CH LIKE '[A-z0-9]' THEN CH ELSE '' END)
FROM SPLIT
OPTION (MAXRECURSION 0);
SELECT @Result AS [Resultado];
*/

/*
-- LETRAS - mesmo resultado mas com CASE
SELECT @Result += (CASE WHEN CH LIKE '[A-z]' THEN CH ELSE ' ' END)
FROM SPLIT
OPTION (MAXRECURSION 0);
SELECT @Result AS [Resultado];
*/

/*
-- NÚMEROS - mesmo resultado mas com CASE
SELECT @Result += (CASE WHEN CH LIKE '[0-9]' THEN CH ELSE ' ' END)
FROM SPLIT
OPTION (MAXRECURSION 0);
SELECT @Result AS [Resultado];
*/
