---------------------------------------------------------------------------------------------------------------------------------------------------
-- Utilização de alguns tipos de funções com strings
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo usando CHARINDEX:
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  CHARINDEX('SQL', 'Microsoft SQL Server')
-- Esta chamada de função irá retornar a localização da cadeia de caracteres “SQL”, 
-- começando, na seqüência de “Microsoft SQL Server”. Neste caso, a função CHARINDEX 
-- irá retornar o número 11, que como você pode ver é a posição inicial de “S” em cadeia “Microsoft SQL Server”. 


---------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo usando PATINDEX:
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  PATINDEX('%8%', 'AB8CD')
-- Como a função CHARINDEX, a função PATINDEX retorna a posição inicial do padrão dentro da seqüência que está sendo pesquisada. 
-- Se você tem uma chamada de função PATINDEX assim: PATINDEX (‘%BC%’, ‘ABCD’)
-- Em seguida, o resultado da chamada da função PATINDEX é 2 , O sinal % é um carácter universal (carácter curinga). 

-- Existem quatro tipo de caractere curinga disponível em SQL Server. Temos que usar LIKE ou palavra-chave PATINDEX.

-- % É usado para representar qualquer coisa antes, depois ou toda string.

-- [] É usado para procurar caráter único dentro de um intervalo (AZ ou 0-9) ou um único caractere no padrão de correspondência.

-- [^] É usado para procurar por uma seqüência sem o caráter dado no colchete após ^ símbolo e na posição especificada.

-- _ (Sublinhado) Usado para encontrar uma string que contenha o texto não levando em consideração o primeiro carácter.


---------------------------------------------------------------------------------------------------------------------------------------------------
-- Varias formas para se trabalhar com uma string
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  SUBSTRING('Microsoft SQL Server', 11, 3);
SELECT
  LEFT('Microsoft SQL Server', 9);
SELECT
  RIGHT('Microsoft SQL Server', 6);
SELECT
  LEN('Microsoft SQL Server     ');
SELECT
  DATALENGTH('Microsoft SQL Server     ');
SELECT
  CHARINDEX('SQL', 'Microsoft SQL Server');
SELECT
  REPLACE('Microsoft SQL Server Denali', 'Denali', '2012');
SELECT
  UPPER('Microsoft SQL Server');
SELECT
  LOWER('Microsoft SQL Server');

-- ele pega a segunda String e joga numa posição da 1ª 
-- substituindo o que estava nessa primeira
SELECT
  STUFF('abcdef', 2, 3, 'ijklmn'); -- resultado -> aijklmnef

SELECT
  REPLACE(contactname, ',', '') AS newcontactname
 ,SUBSTRING(contactname, CHARINDEX(N',', contactname) + 1, LEN(contactname) - CHARINDEX(N',', contactname) + 1) AS firstname
FROM Sales.Customers;

select CHOOSE(valorInteiro % 3 + 1, N'A', N'B', N'C') AS custgroup,


---------------------------------------------------------------------------------------------------------------------------------------------------
-- Funções PARSE e FORMAT
---------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Valor Varchar(10)
SET @Valor = '1,540.20'

SELECT
  @Valor AS Antes
 ,PARSE(@Valor AS MONEY USING 'en-US') AS Depois

SELECT
  FORMAT(CAST(@Valor AS MONEY), 'C', 'pt-BR')
GO


------------------------------------------------------------------------------------------------------------------------------------------
-- Criando rotinas para exercícios
------------------------------------------------------------------------------------------------------------------------------------------
-- Usando comando SET - SELECT recursivo
CREATE TABLE myWords (
  RowID INT
 ,Word VARCHAR(20)
)
GO

INSERT INTO myWords
  VALUES (1, 'This'), (2, 'is'), (3, 'an'), (4, 'interesting'), (5, 'table')

DECLARE @Sentence AS VARCHAR(8000)
SET @Sentence = ''
SELECT
  @Sentence = @Sentence + word + ' '
FROM myWords
ORDER BY RowID

PRINT @Sentence


------------------------------------------------------------------------------------------------------------------------------------------
-- Diariamente, nos deparamos com a necessidade de repetir o mesmo valor, como por exemplo, 
-- acrescentar zeros em um campo númerico, através da função string Replace é possível realizar a repetição de um único caracter, 
-- como também de uma seqüência de caracteres, especificando a quando de vezes que esta caracter deve ser repetido.
------------------------------------------------------------------------------------------------------------------------------------------
--Veja o exemplo: 
CREATE TABLE #Temp (
  codigo INT
 ,descricao VARCHAR(20)
)
INSERT INTO #temp
  VALUES (1, 'Pedro')
INSERT INTO #temp
  VALUES (2, 'Fer')
INSERT INTO #temp
  VALUES (3, 'JP')
INSERT INTO #temp
  VALUES (4, 'Edu')

SELECT
  CASE codigo
    WHEN 1 THEN REPLICATE('0', 3) + descricao
    WHEN 2 THEN REPLICATE('0', 4) + descricao
    ELSE CAST(codigo AS VARCHAR(10))
  END AS Alteracao
 ,codigo
 ,descricao
FROM #Temp
DROP TABLE #Temp
