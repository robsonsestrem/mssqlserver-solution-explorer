---------------------------------------------------------------------------------------------------------------------------------------------------
-- Utiliza��o de alguns tipos de fun��es com strings
---------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo usando CHARINDEX:
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  CHARINDEX('SQL', 'Microsoft SQL Server')
-- Esta chamada de fun��o ir� retornar a localiza��o da cadeia de caracteres �SQL�, 
-- come�ando, na seq��ncia de �Microsoft SQL Server�. Neste caso, a fun��o CHARINDEX 
-- ir� retornar o n�mero 11, que como voc� pode ver � a posi��o inicial de �S� em cadeia �Microsoft SQL Server�. 


---------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo usando PATINDEX:
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  PATINDEX('%8%', 'AB8CD')
-- Como a fun��o CHARINDEX, a fun��o PATINDEX retorna a posi��o inicial do padr�o dentro da seq��ncia que est� sendo pesquisada. 
-- Se voc� tem uma chamada de fun��o PATINDEX assim: PATINDEX (�%BC%�, �ABCD�)
-- Em seguida, o resultado da chamada da fun��o PATINDEX � 2 , O sinal % � um car�cter universal (car�cter curinga). 

-- Existem quatro tipo de caractere curinga dispon�vel em SQL Server. Temos que usar LIKE ou palavra-chave PATINDEX.

-- % � usado para representar qualquer coisa antes, depois ou toda string.

-- [] � usado para procurar car�ter �nico dentro de um intervalo (AZ ou 0-9) ou um �nico caractere no padr�o de correspond�ncia.

-- [^] � usado para procurar por uma seq��ncia sem o car�ter dado no colchete ap�s ^ s�mbolo e na posi��o especificada.

-- _ (Sublinhado) Usado para encontrar uma string que contenha o texto n�o levando em considera��o o primeiro car�cter.


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

-- ele pega a segunda String e joga numa posi��o da 1� 
-- substituindo o que estava nessa primeira
SELECT
  STUFF('abcdef', 2, 3, 'ijklmn'); -- resultado -> aijklmnef

SELECT
  REPLACE(contactname, ',', '') AS newcontactname
 ,SUBSTRING(contactname, CHARINDEX(N',', contactname) + 1, LEN(contactname) - CHARINDEX(N',', contactname) + 1) AS firstname
FROM Sales.Customers;

select CHOOSE(valorInteiro % 3 + 1, N'A', N'B', N'C') AS custgroup,


---------------------------------------------------------------------------------------------------------------------------------------------------
-- Fun��es PARSE e FORMAT
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
-- Criando rotinas para exerc�cios
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
-- acrescentar zeros em um campo n�merico, atrav�s da fun��o string Replace � poss�vel realizar a repeti��o de um �nico caracter, 
-- como tamb�m de uma seq��ncia de caracteres, especificando a quando de vezes que esta caracter deve ser repetido.
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
