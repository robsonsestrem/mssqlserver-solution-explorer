/*
 *
	OBJETIVO: Demonstração completa de manipulação de dados XML no SQL Server,
			  incluindo criação de schemas XML, validação de documentos,
			  consultas com FOR XML (RAW, AUTO, PATH), formatação de saída,
			  definição de raiz, aliases, atributos, e conversões de tipo.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *	
 */
-- ============================================================
-- Manipulando schema simples de XML
-- ============================================================
DECLARE @xml XML
SET @xml = '<pessoa> nome= "robson" </pessoa>'
SELECT @xml

CREATE TABLE ##testexml
(
    id INT,
    nome VARCHAR(50),
    dados XML
)

INSERT INTO ##testexml
VALUES
    (1, 'robson', '<pessoa> <cpf>151456135051</cpf> <rg> 4564654</rg> </pessoa>'),
    (2, 'teste1', '<pessoa cpf="654654564" rg="65465456"/>')

SELECT
    *
FROM ##testexml

DROP TABLE ##testexml


-- ============================================================
-- Criando XML SCHEMA COLLECTION para validação
-- ============================================================
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


-- ============================================================
-- O Schema fará validação no campo XML conforme padrões definidos
-- ============================================================
CREATE TABLE testexml
(
    id INT,
    nome VARCHAR(50),
    dados XML(meus_documentos)
)

-- Conforme validação, o 1º nó deve ter o nome "DOCUMENTOS"
-- Os elementos também devem seguir a sequência (RG antes de CPF)
INSERT INTO testexml
VALUES
(
    1,
    'robson',
    '<DOCUMENTOS> <RG>4564654</RG> <CPF>151456135051</CPF></DOCUMENTOS>'
)

-- INSERT INTO testexml VALUES (2, 'teste1', '<DOCUMENTOS RG="65465456" CPF="654654564" />')
-- Neste caso não recebe como atributo, apenas como elementos

SELECT
    *
FROM testexml
GO


-- ============================================================
-- TRABALHANDO COM AS COLUNAS DO 
-- TIPO XML - FOR XML ROW, AUTO, PATH
-- ============================================================
CREATE TABLE TIPO_PRODUTO
(
    COD_TIPO_PRODUTO INT IDENTITY PRIMARY KEY,
    NOME_TIPO_PRODUTO VARCHAR(50)
)

CREATE TABLE PRODUTO
(
    COD_PRODUTO INT IDENTITY(1, 1) PRIMARY KEY,
    NOME_PRODUTO VARCHAR(50),
    PRECO_PRODUTO DECIMAL(9, 2),
    COD_TIPO_PRODUTO INT REFERENCES TIPO_PRODUTO
)

INSERT INTO TIPO_PRODUTO
(
    NOME_TIPO_PRODUTO
)
VALUES
    ('FERRAMENTA'),
    ('FRUTA'),
    ('MATERIAL ESCOLAR')

INSERT INTO PRODUTO
(
    NOME_PRODUTO,
    PRECO_PRODUTO,
    COD_TIPO_PRODUTO
)
VALUES
    ('MARRETA', 40, 1),
    ('SERROTE', 70, 1),
    ('CADERNO', 12, 3),
    ('LIMA', 19, 1),
    ('MARTELO', 30, 1),
    ('LIMA', 3.7, 2),
    ('SARGENTO', 27.23, 1),
    ('MAMÃO', 4.7, 2),
    ('LARANJA', 6.5, 2)
GO


-- ============================================================
-- OBS.: Tipos de dados suportados por XML são UNICODE, 
-- aceita acento, ç, etc.
-- OBS2.: Não se usa espaço/TAB em nome de tabelas, 
-- pois no XML vai trazer o hexadecimal
-- ============================================================

-- ============================================================
-- FOR XML com diferentes modos
-- ============================================================
SELECT * FROM PRODUTO FOR XML RAW
SELECT * FROM PRODUTO FOR XML AUTO
SELECT * FROM PRODUTO FOR XML PATH
GO


-- ============================================================
-- Colocando alias
-- ============================================================
SELECT * FROM PRODUTO FOR XML RAW ('OUTRO_NOME') -- modo para trocar de nome com o RAW

SELECT * FROM PRODUTO AS p FOR XML AUTO -- alias aparece no lugar do nome da tabela

SELECT * FROM PRODUTO FOR XML PATH ('OUTRO_NOME') -- muda nome do elemento
GO


-- ============================================================
-- Colocando raiz
-- ============================================================
SELECT * FROM PRODUTO FOR XML RAW, ROOT ('RAIZ')
SELECT * FROM PRODUTO FOR XML AUTO, ROOT ('RAIZ')
SELECT * FROM PRODUTO FOR XML PATH, ROOT ('RAIZ')
GO


-- ============================================================
-- Trabalhando com JOIN - NÃO PODE FICAR SEM ORDER BY, pois bagunça o XML
-- ============================================================
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
FOR XML PATH -- Funciona mas sem organização

SELECT
    *
FROM TIPO_PRODUTO AS t1
INNER JOIN PRODUTO AS t2
    ON t1.COD_TIPO_PRODUTO = t2.COD_TIPO_PRODUTO
ORDER BY t1.COD_TIPO_PRODUTO
FOR XML RAW -- Não funciona porque tem campos com nomes iguais

SELECT
    t1.*,
    t2.COD_PRODUTO,
    t2.NOME_PRODUTO,
    t2.PRECO_PRODUTO
FROM TIPO_PRODUTO AS t1
INNER JOIN PRODUTO AS t2
    ON t1.COD_TIPO_PRODUTO = t2.COD_TIPO_PRODUTO
ORDER BY t1.COD_TIPO_PRODUTO
FOR XML RAW -- Solução para o RAW funcionar
GO


-- ============================================================
-- Formatações diversas - atributos dentro de elementos
-- ============================================================
SELECT
    COD_PRODUTO AS '@COD_PRODUTO',
    NOME_PRODUTO,
    PRECO_PRODUTO
FROM PRODUTO
FOR XML PATH

SELECT
    COD_PRODUTO AS '@COD_PRODUTO',
    COD_TIPO_PRODUTO AS 'DETALHES/@TIPO',
    NOME_PRODUTO AS 'DETALHES/@NOME',
    PRECO_PRODUTO AS 'DETALHES/PRECO'
FROM PRODUTO
FOR XML PATH

SELECT
    COD_PRODUTO AS '@COD_PRODUTO',
    NOME_PRODUTO AS 'NOME',
    PRECO_PRODUTO AS 'PRECO'
FROM PRODUTO
FOR XML PATH ('PRODUTO'), ROOT ('PRODUTOS')
GO


-- ============================================================
-- Conversões com XML
-- ============================================================
SELECT
    T1.COD_TIPO_PRODUTO,
    T1.NOME_TIPO_PRODUTO,
    (
        SELECT *
        FROM PRODUTO
        FOR XML PATH
    ) AS Dados_Varchar, -- não traz convertido
    CONVERT
    (
        XML,
        (
            SELECT *
            FROM PRODUTO
            FOR XML PATH
        )
    ) AS Dados_Convert, -- conversão explícita
    (
        SELECT *
        FROM PRODUTO
        FOR XML PATH, TYPE
    ) AS Dados_Type -- palavra reservada TYPE faz a conversão
FROM TIPO_PRODUTO AS T1
GO


-- ============================================================
-- Limpeza
-- ============================================================
DROP TABLE testexml
DROP TABLE PRODUTO
DROP TABLE TIPO_PRODUTO
DROP XML SCHEMA COLLECTION meus_documentos
GO
