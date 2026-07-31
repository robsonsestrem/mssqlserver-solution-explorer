/*
 *
    OBJETIVO: Função para dividir uma string delimitada por um separador em substrings,
              retornando um elemento específico ou a quantidade total de elementos.
              Funciona como a função EXPLODE do PHP ou SPLIT do Java/JavaScript/C#.
    PROJETO: mssqlserver-solution-explorer

    PARÂMETROS:
    - @String:     String original a ser dividida
    - @Separador:  Caractere(s) utilizado(s) como delimitador
    - @PosBusca:   Posição do elemento a ser retornado
                   - 0: Retorna a quantidade total de elementos
                   - >0: Retorna o elemento na posição especificada
                   - <0: Retorna o elemento a partir do final (ex: -1 = último elemento)

    REFERÊNCIAS: https://www.dirceuresende.com/blog/quebrando-strings-em-sub-strings-utilizando-separador-no-sql-server/
 *
 */
-- ================================================================================================================================
-- FUNÇÃO: fn_ValueSeparateByVarious
-- Divide uma string delimitada e retorna um elemento específico ou o total
-- ================================================================================================================================
USE YOUR_DATABASE
GO

CREATE FUNCTION Management.[fn_ValueSeparateByVarious]
(
    @String VARCHAR(8000),
    @Separador VARCHAR(8000),
    @PosBusca INT
)
RETURNS VARCHAR(8000)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @Index INT
          , @Max INT
          , @Retorno VARCHAR(8000)

    -- Tabela temporária para armazenar os elementos divididos
    DECLARE @Partes AS TABLE
    (
        Id_Parte INT IDENTITY(1, 1),
        Texto VARCHAR(8000)
    )

    -- Loop para dividir a string com base no separador
    SET @Index = CHARINDEX(@Separador, @String)

    WHILE (@Index > 0)
    BEGIN
        INSERT INTO @Partes
        SELECT
            SUBSTRING(@String, 1, @Index - 1)

        SET @String = RTRIM(LTRIM(SUBSTRING(@String, @Index + LEN(@Separador), LEN(@String))))
        SET @Index = CHARINDEX(@Separador, @String)
    END

    -- Insere o último elemento (após o último separador)
    IF (@String != '')
        INSERT INTO @Partes
        SELECT
            @String

    -- Obtém a quantidade total de elementos
    SELECT
        @Max = COUNT(*)
    FROM
        @Partes

    -- Retorna a contagem total quando @PosBusca = 0
    IF (@PosBusca = 0)
        SET @Retorno = CAST(@Max AS VARCHAR(5))

    -- Suporte para índices negativos (a partir do final)
    IF (@PosBusca < 0)
        SET @PosBusca = @Max + 1 + @PosBusca

    -- Retorna o elemento na posição especificada
    IF (@PosBusca > 0)
        SELECT
            @Retorno = Texto
        FROM
            @Partes
        WHERE
            Id_Parte = @PosBusca

    RETURN RTRIM(LTRIM(@Retorno))
END
GO


-- ================================================================================================================================
-- EXEMPLO DE TESTE DA FUNÇÃO
-- ================================================================================================================================
-- Exemplo 1: Dividindo uma lista de nomes
DECLARE @exemplo1 VARCHAR(MAX) = 'nome;nascimento;email'
SELECT
    Management.fn_ValueSeparateByVarious(@exemplo1, ';', 1) AS PrimeiroElemento,
    Management.fn_ValueSeparateByVarious(@exemplo1, ';', 2) AS SegundoElemento,
    Management.fn_ValueSeparateByVarious(@exemplo1, ';', 3) AS TerceiroElemento
-- Resultado: 'nome' | 'nascimento' | 'email'

-- Exemplo 2: Trabalhando com índices negativos
DECLARE @strOrigem VARCHAR(MAX) = 'Testando|String|Para|O|Blog'

SELECT Management.fn_ValueSeparateByVarious(@strOrigem, '|', 1)  -- Retorna 'Testando'
SELECT Management.fn_ValueSeparateByVarious(@strOrigem, '|', 5)  -- Retorna 'Blog'
SELECT Management.fn_ValueSeparateByVarious(@strOrigem, '|', 0)  -- Retorna '5'
SELECT Management.fn_ValueSeparateByVarious(@strOrigem, '|', -1) -- Retorna 'Blog' (último elemento)
GO
