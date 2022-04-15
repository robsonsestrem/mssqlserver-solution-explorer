-----------------------------------------------------------------------------------
-- manipulando schema simples de xml
-----------------------------------------------------------------------------------
DECLARE @xml XML
SET @xml = '<pessoa> nome= "robson" </pessoa>'
SELECT @xml

CREATE TABLE ##testexml (
  id INT
 ,nome VARCHAR(50)
 ,dados XML
)

INSERT INTO ##testexml
  VALUES (1, 'robson', '<pessoa> <cpf>151456135051</cpf> <rg> 4564654</rg> </pessoa>')
  , (2, 'teste1', '<pessoa cpf="654654564" rg="65465456"/>')

SELECT
  *
FROM ##testexml

DROP TABLE ##testexml

CREATE XML SCHEMA COLLECTION meus_documentos
AS
N'
<schema xmlns="http://www.w3.org/2001/XMLSchema">
	<element name="DOCUMENTOS">
		<complexType>
		<sequence>
			<element name="RG" type="string" />
			<element name="CPF" type="string"/>
		</sequence>
		</complexType>
	</element>
</schema>
'
GO


-----------------------------------------------------------------------------------
-- O Schema fará validação no campo xml conforme padrões que fiz
-----------------------------------------------------------------------------------
CREATE TABLE testexml -- não pode ser feito numa tabela temporária
(
  id INT
 ,nome VARCHAR(50)
 ,dados XML(meus_documentos)
)

-- conforme validação o 1º nó deve ser com o mesmo nome ou seja "documentos"
-- os elementos também devem seguir a sequência
INSERT INTO testexml
  VALUES (1, 'robson', '<DOCUMENTOS>  <RG>4564654</RG> <CPF>151456135051</CPF></DOCUMENTOS>')

--, (2, 'teste1', '<DOCUMENTOS RG="65465456" CPF="654654564" />') -- NESSE CASO ELE NÃO RECEBE COMO ATRIBUTO

SELECT
  *
FROM testexml


------------------------------------------------------------------------------------------------
/*   TRABALHANDO COM AS COLUNAS DO TIPO XML - FOR XML ROW; FOR XML AUTO; FOR XML PATH      */
------------------------------------------------------------------------------------------------
CREATE TABLE TIPO_PRODUTO (
  COD_TIPO_PRODUTO INT IDENTITY PRIMARY KEY
 ,NOME_TIPO_PRODUTO VARCHAR(50)
)

CREATE TABLE PRODUTO (
  COD_PRODUTO INT IDENTITY (1, 1) PRIMARY KEY
 ,NOME_PRODUTO VARCHAR(50)
 ,PRECO_PRODUTO DECIMAL(9, 2)
 ,COD_TIPO_PRODUTO INT REFERENCES TIPO_PRODUTO
)

INSERT INTO TIPO_PRODUTO (NOME_TIPO_PRODUTO)
  VALUES ('FERRAMENTA'), ('FRUTA'), ('MATERIAL ESCOLAR')


INSERT INTO PRODUTO (NOME_PRODUTO, PRECO_PRODUTO, COD_TIPO_PRODUTO)
  VALUES ('MARRETA', 40, 1),
  ('SERROTE', 70, 1),
  ('CADERNO', 12, 3),
  ('LIMA', 19, 1),
  ('MARTELO', 30, 1),
  ('LIMA', 3.7, 2),
  ('SARGENTO', 27.23, 1),
  ('MAMÃO', 4.7, 2),
  ('LARANJA', 6.5, 2)


-----------------------------------------------------------------------------------------
-- OBS.: TIPOS DE DADOS SUPORTADOS POR XML É UNICOD, OU SEJA, ACEITA ACENTO Ç ETC...
-- OBS2.: NÃO SE USA ESPAÇO/TAB EM NOME DE TABELAS, POIS NO XML VAI TRAZER O HEXADECIMAL
-- DESSES CARACTERES.
-----------------------------------------------------------------------------------------
SELECT
  *
FROM PRODUTO
FOR XML RAW

SELECT
  *
FROM PRODUTO
FOR XML AUTO

SELECT
  *
FROM PRODUTO
FOR XML PATH


-----------------------------------------------------------------------------------------
-- Colocando alias
-----------------------------------------------------------------------------------------
SELECT
  *
FROM PRODUTO
FOR XML RAW ('OUTRO_NOME') -- modo para trocar de nome com o raw

SELECT
  *
FROM PRODUTO p -- posso colocar alias para mostrar no lugar do nome da tabela
FOR XML AUTO			-- alias depois de "auto" não vale

SELECT
  *
FROM PRODUTO
FOR XML PATH ('OUTRO_NOME') -- muda nome do elemento chamado "raw"


-----------------------------------------------------------------------------------------
-- Colocando raiz
-----------------------------------------------------------------------------------------
SELECT
  *
FROM PRODUTO
FOR XML RAW, ROOT ('RAIZ')

SELECT
  *
FROM PRODUTO
FOR XML AUTO, ROOT ('RAIZ')

SELECT
  *
FROM PRODUTO
FOR XML PATH, ROOT ('RAIZ')


-----------------------------------------------------------------------------------------
-- Trabalhando com vários dados - JOIN -- NÃO PODE FICAR SEM ORDER BY, POIS BAGUNÇA O XML
-----------------------------------------------------------------------------------------
SELECT
  *
FROM TIPO_PRODUTO AS t1
INNER JOIN PRODUTO AS t2
  ON t1.COD_TIPO_PRODUTO = t2.COD_TIPO_PRODUTO
ORDER BY t1.COD_TIPO_PRODUTO
FOR XML AUTO -- Agrupou de forma elegante

SELECT
  *
FROM TIPO_PRODUTO AS t1
INNER JOIN PRODUTO AS t2
  ON t1.COD_TIPO_PRODUTO = t2.COD_TIPO_PRODUTO
ORDER BY t1.COD_TIPO_PRODUTO
FOR XML PATH -- até funciona mas sem organização

SELECT
  *
FROM TIPO_PRODUTO AS t1
INNER JOIN PRODUTO AS t2
  ON t1.COD_TIPO_PRODUTO = t2.COD_TIPO_PRODUTO
ORDER BY t1.COD_TIPO_PRODUTO
FOR XML RAW -- não funciona porque tem campos iguais

SELECT
  t1.*
 ,t2.COD_PRODUTO
 ,t2.NOME_PRODUTO
 ,t2.PRECO_PRODUTO
FROM TIPO_PRODUTO AS t1
INNER JOIN PRODUTO AS t2
  ON t1.COD_TIPO_PRODUTO = t2.COD_TIPO_PRODUTO
ORDER BY t1.COD_TIPO_PRODUTO
FOR XML RAW -- jeito para funcionar


-----------------------------------------------------------------------------------------
-- Formatações diversas - SE DIZ ATRIBUTOS DENTRO DE ELEMENTOS
-----------------------------------------------------------------------------------------
SELECT
  COD_PRODUTO '@COD_PRODUTO'
 ,NOME_PRODUTO
 ,PRECO_PRODUTO
FROM PRODUTO
FOR XML PATH

SELECT
  COD_PRODUTO '@COD_PRODUTO'
 ,COD_TIPO_PRODUTO 'DETALHES/@TIPO'
 ,NOME_PRODUTO 'DETALHES/@NOME'
 ,PRECO_PRODUTO 'DETALHES/PRECO'
FROM PRODUTO
FOR XML PATH

SELECT
  COD_PRODUTO '@COD_PRODUTO'
 ,NOME_PRODUTO 'NOME'
 ,PRECO_PRODUTO 'PRECO'
FROM PRODUTO
FOR XML PATH ('PRODUTO'), ROOT ('PRODUTOS')

-- CONVERSÕES
SELECT
  T1.COD_TIPO_PRODUTO
 ,T1.NOME_TIPO_PRODUTO
 ,(SELECT
      *
    FROM PRODUTO
    FOR XML PATH)
  AS Dados_Varchar -- não traz convertido
 ,CONVERT(XML, (SELECT
      *
    FROM PRODUTO
    FOR XML PATH)
  ) AS Dados_Convert -- conversão explícita
 ,(SELECT
      *
    FROM PRODUTO
    FOR XML PATH, TYPE)
  AS Dados_Type	  -- palavra reservada type faz a coversão
FROM TIPO_PRODUTO AS T1


