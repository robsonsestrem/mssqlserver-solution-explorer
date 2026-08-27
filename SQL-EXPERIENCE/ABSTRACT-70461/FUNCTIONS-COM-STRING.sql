/*
 *
	OBJETIVO: Demonstração de diversas funções de manipulação de strings no SQL Server,
			  incluindo CHARINDEX, PATINDEX, SUBSTRING, LEFT, RIGHT, LEN, DATALENGTH,
			  REPLACE, STUFF, UPPER, LOWER, PARSE, FORMAT, REPLICATE, e exemplos
			  práticos de uso em consultas e rotinas.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *	
 */
-- ============================================================
-- Exemplo usando CHARINDEX
-- ============================================================
SELECT
    CHARINDEX('SQL', 'Microsoft SQL Server')
-- Esta chamada de função irá retornar a localização da cadeia de caracteres "SQL",
-- começando na sequência de "Microsoft SQL Server". Neste caso, a função CHARINDEX
-- irá retornar o número 11, que é a posição inicial de "S" em "Microsoft SQL Server".


-- ============================================================
-- Exemplo usando PATINDEX
-- ============================================================
SELECT
    PATINDEX('%8%', 'AB8CD')
-- Como a função CHARINDEX, a função PATINDEX retorna a posição inicial do padrão
-- dentro da sequência que está sendo pesquisada.
-- PATINDEX('%BC%', 'ABCD') retorna 2.
-- O sinal % é um caractere curinga.


-- ============================================================
-- Caracteres curinga disponíveis no SQL Server
-- ============================================================
-- % - Usado para representar qualquer coisa antes, depois ou toda string.
-- [] - Usado para procurar caractere único dentro de um intervalo (A-Z ou 0-9)
--      ou um único caractere no padrão de correspondência.
-- [^] - Usado para procurar por uma sequência sem o caractere dado no colchete
--       após o símbolo ^ e na posição especificada.
-- _ - (Sublinhado) Usado para encontrar uma string que contenha o texto não
--     levando em consideração o primeiro caractere.


-- ============================================================
-- Várias formas para se trabalhar com uma string
-- ============================================================
SELECT SUBSTRING('Microsoft SQL Server', 11, 3)
SELECT LEFT('Microsoft SQL Server', 9)
SELECT RIGHT('Microsoft SQL Server', 6)
SELECT LEN('Microsoft SQL Server     ')
SELECT DATALENGTH('Microsoft SQL Server     ')
SELECT CHARINDEX('SQL', 'Microsoft SQL Server')
SELECT REPLACE('Microsoft SQL Server Denali', 'Denali', '2012')
SELECT UPPER('Microsoft SQL Server')
SELECT LOWER('Microsoft SQL Server')

-- STUFF: pega a segunda string e insere na posição da primeira,
-- substituindo o que estava nessa posição
SELECT STUFF('abcdef', 2, 3, 'ijklmn') -- resultado: aijklmnef

-- Exemplo prático com REPLACE e SUBSTRING
SELECT
    REPLACE(contactname, ',', '') AS newcontactname,
    SUBSTRING
    (
        contactname,
        CHARINDEX(N',', contactname) + 1,
        LEN(contactname) - CHARINDEX(N',', contactname) + 1
    ) AS firstname
FROM Sales.Customers

-- Exemplo com CHOOSE
SELECT CHOOSE(valorInteiro % 3 + 1, N'A', N'B', N'C') AS custgroup
GO


-- ============================================================
-- Funções PARSE e FORMAT
-- ============================================================
DECLARE @Valor VARCHAR(10)
SET @Valor = '1,540.20'

SELECT
    @Valor AS Antes,
    PARSE(@Valor AS MONEY USING 'en-US') AS Depois

SELECT
    FORMAT(CAST(@Valor AS MONEY), 'C', 'pt-BR')
GO


-- ============================================================
-- Criando rotinas para exercícios
-- ============================================================
-- Usando comando SET - SELECT recursivo para concatenar strings
CREATE TABLE myWords
(
    RowID INT,
    Word VARCHAR(20)
)
GO

INSERT INTO myWords
VALUES (1, 'This'), (2, 'is'), (3, 'an'), (4, 'interesting'), (5, 'table')

DECLARE @Sentence AS VARCHAR(8000)
SET @Sentence = ''

SELECT @Sentence = @Sentence + word + ' '
FROM myWords
ORDER BY RowID

PRINT @Sentence
GO


-- ============================================================
-- Exemplo de REPLICATE para preencher com zeros à esquerda
-- ============================================================
CREATE TABLE #Temp
(
    codigo INT,
    descricao VARCHAR(20)
)

INSERT INTO #Temp
VALUES (1, 'Pedro'), (2, 'Fer'), (3, 'JP'), (4, 'Edu')

SELECT
    CASE codigo
        WHEN 1 THEN REPLICATE('0', 3) + descricao
        WHEN 2 THEN REPLICATE('0', 4) + descricao
        ELSE CAST(codigo AS VARCHAR(10))
    END AS Alteracao,
    codigo,
    descricao
FROM #Temp

DROP TABLE #Temp
GO
