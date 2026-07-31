/*
 *
    OBJETIVO: Funções escalares para validação e manipulação de strings no SQL Server:
              FVALIDA_NUMEROS extrai apenas os dígitos numéricos de uma string,
              CountSearchPat conta quantas vezes uma palavra aparece em um texto,
              sp_isdigit verifica se um campo contém apenas números (retorna 1 ou 0).
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/en-us/sql/t-sql/functions/patindex-transact-sql?view=sql-server-ver17
 *  https://learn.microsoft.com/en-us/sql/tools/sql-database-projects/concepts/sql-code-analysis/t-sql-naming-issues?view=sql-server-ver17
 */
--
-- Funções de Validação e Manipulação de Strings e Números
--

-- ============================================================
-- Função 1: FVALIDA_NUMEROS
-- Extrai apenas os caracteres numéricos de uma string
-- ============================================================

-- Cria função escalar que percorre cada caractere da string
-- e concatena apenas os dígitos numéricos no resultado
CREATE FUNCTION FVALIDA_NUMEROS (@PALAVRA VARCHAR(1000))
RETURNS VARCHAR(1000)
AS
BEGIN
    -- Declaração das variáveis de controle do loop e resultado
    DECLARE
          @RESULTADO   VARCHAR(1000)
        , @LETRA       VARCHAR(1)
        , @QTD_PALAVRA INTEGER
        , @CONT        INTEGER

    SET @CONT = 0
    SET @QTD_PALAVRA = LEN(@PALAVRA)
    SET @RESULTADO = 0

    -- Percorre cada caractere da string de entrada
    WHILE @CONT < @QTD_PALAVRA
    BEGIN
        SET @CONT = @CONT + 1
        SET @LETRA = SUBSTRING(@PALAVRA, @CONT, 1)

        -- Se o caractere for um dígito numérico, concatena no resultado
        IF @LETRA IN (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
        BEGIN
            SET @RESULTADO = @RESULTADO + @LETRA
        END
    END

    RETURN @RESULTADO
END
GO

-- ============================================================
-- Função 2: CountSearchPat
-- Conta quantas vezes uma palavra aparece em uma string
-- ============================================================

-- Lógica: percorre a string caractere a caractere e compara o trecho
-- do tamanho da palavra procurada com a palavra-alvo.
-- Se coincidir, incrementa o contador de ocorrências.
CREATE FUNCTION CountSearchPat
(
      @Word   VARCHAR(100)
    , @String VARCHAR(MAX)
)
RETURNS INT
AS
BEGIN
    -- Declaração de variáveis
    DECLARE
          @Count     INT
        , @CountWord INT

    -- Contador de quantas vezes a palavra apareceu
    SET @CountWord = 0

    -- Contador do loop
    SET @Count = 0

    -- Percorre a string caractere a caractere
    WHILE @Count <= LEN(@String)
    BEGIN
        -- Se encontrar a palavra, soma mais um para @CountWord
        SET @CountWord =
            CASE
                WHEN SUBSTRING(@String, @Count, LEN(@Word)) = @Word
                THEN @CountWord + 1
                ELSE @CountWord
            END

        -- Soma mais um ao contador
        SET @Count = @Count + 1
    END

    -- Retorna o total de ocorrências encontradas
    RETURN @CountWord
END
GO

-- ============================================================
-- Função 3: sp_isdigit
-- Verifica se uma string contém apenas dígitos numéricos
-- ============================================================

-- Remove a função se já existir (evita erro em recriação)
IF EXISTS (
    SELECT
        *
    FROM
        sys.objects
    WHERE
        object_id = OBJECT_ID(N'[dbo].[sp_isdigit]')
        AND type IN (N'FN')
)
    DROP FUNCTION sp_isdigit
GO

-- Cria função escalar que utiliza PATINDEX para verificar se a string
-- contém apenas números. Retorna 1 (verdadeiro) ou 0 (falso).
--
-- OBS: A nomenclatura "sp_" é reservada pelo SQL Server para system stored
--      procedures. A Microsoft desaconselha explicitamente o uso deste
--      prefixo em objetos de usuário, pois pode causar busca desnecessária
--      no banco master e degradação de performance.
CREATE FUNCTION sp_isdigit (@string VARCHAR(MAX))
RETURNS INT
AS
BEGIN
    RETURN
    (
        SELECT
            CASE
                WHEN PATINDEX('%[^0-9]%', @string) > 0
                THEN 0
                ELSE 1
            END AS sp_isdigit
    )
END;
GO

-- Exemplos de uso:
-- SELECT dbo.sp_isdigit('ISSO É UM VALOR NUMÉRICO?'); -- retorno: 0
-- SELECT dbo.sp_isdigit('3000');                        -- retorno: 1
-- SELECT dbo.sp_isdigit('2700.00');                     -- retorno: 0 (possui ponto)
