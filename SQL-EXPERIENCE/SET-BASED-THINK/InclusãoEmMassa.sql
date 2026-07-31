/*
 *
	OBJETIVO: Scripts demonstrativos para inclusão em massa de dados, comparando abordagens
			  com cursor (baixo desempenho) versus soluções baseadas em conjunto (INSERT SELECT)
			  para melhor performance, incluindo tratamento de chave primária com e sem IDENTITY.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Soluções para inclusão em massa
-- ============================================================

-- ============================================================
-- Abordagem 1: Utilizando CURSOR (baixo desempenho - evitar)
-- ============================================================
DECLARE
    @NOME_COMPLETO VARCHAR(70),
    @CPF VARCHAR(11),
    @SEXO VARCHAR(1),
    @DATA_NASC VARCHAR(11),
    @CEP VARCHAR(8),
    @LOGRADOURO VARCHAR(90),
    @NUMERO VARCHAR(6),
    @COMPLEMENTO VARCHAR(60),
    @BAIRRO VARCHAR(65),
    @MUNICIPIO VARCHAR(55),
    @ESTADO VARCHAR(2),
    @DDD VARCHAR(3),
    @TELEFONE VARCHAR(15),
    @EMAIL VARCHAR(100),
    @COD_ID INT

DECLARE cursor_objects CURSOR LOCAL FOR
    SELECT
        NOME_COMPLETO,
        CPF,
        SEXO,
        DATA_NASC,
        CEP,
        LOGRADOURO,
        NUMERO,
        COMPLEMENTO,
        BAIRRO,
        MUNICIPIO,
        ESTADO,
        DDD,
        TELEFONE,
        EMAIL,
        COD_ID
    FROM dbo.tb_clientes_tmp

OPEN cursor_objects
FETCH NEXT FROM cursor_objects
INTO
    @NOME_COMPLETO,
    @CPF,
    @SEXO,
    @DATA_NASC,
    @CEP,
    @LOGRADOURO,
    @NUMERO,
    @COMPLEMENTO,
    @BAIRRO,
    @MUNICIPIO,
    @ESTADO,
    @DDD,
    @TELEFONE,
    @EMAIL,
    @COD_ID

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @COD_ID =
    (
        SELECT CAST(ISNULL(MAX(COD_ID), '') + 1 AS INT)
        FROM dbo.tb_cliente
    )

    INSERT INTO dbo.tb_cliente
    (
        COD_ID,
        NOME_COMPLETO,
        CPF,
        SEXO,
        DATA_NASC,
        CEP,
        LOGRADOURO,
        NUMERO,
        COMPLEMENTO,
        BAIRRO,
        MUNICIPIO,
        ESTADO,
        DDD,
        TELEFONE,
        EMAIL
    )
    VALUES
    (
        @COD_ID,
        @NOME_COMPLETO,
        @CPF,
        @SEXO,
        @DATA_NASC,
        @CEP,
        @LOGRADOURO,
        @NUMERO,
        @COMPLEMENTO,
        @BAIRRO,
        @MUNICIPIO,
        @ESTADO,
        @DDD,
        @TELEFONE,
        @EMAIL
    )

    FETCH NEXT FROM cursor_objects
    INTO
        @NOME_COMPLETO,
        @CPF,
        @SEXO,
        @DATA_NASC,
        @CEP,
        @LOGRADOURO,
        @NUMERO,
        @COMPLEMENTO,
        @BAIRRO,
        @MUNICIPIO,
        @ESTADO,
        @DDD,
        @TELEFONE,
        @EMAIL,
        @COD_ID
END

CLOSE cursor_objects
DEALLOCATE cursor_objects

-- ============================================================
-- Abordagem 2: INSERT SELECT com IDENTITY (alta performance)
-- ============================================================
INSERT INTO dbo.tb_cliente
(
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    DELETADO
)
SELECT
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    '' AS DELETADO
FROM dbo.tb_clientes_tmp
GO

-- ============================================================
-- Abordagem 3: Sem IDENTITY com MAX 
-- (funciona apenas para tabela vazia)
-- ============================================================
INSERT INTO dbo.tb_cliente
(
    COD_ID,
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    DELETADO
)
SELECT
    (
        SELECT CAST(ISNULL(MAX(COD_ID), '') + 1 AS INT)
        FROM dbo.tb_cliente
    ) AS COD_ID,
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    '' AS DELETADO
FROM dbo.tb_clientes_tmp
GO

-- ============================================================
-- Abordagem 4: Sem IDENTITY com ROW_NUMBER 
-- (tabela vazia, melhor que MAX)
-- ============================================================
INSERT INTO dbo.tb_cliente
(
    COD_ID,
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    DELETADO
)
SELECT
    CONVERT(INT, ROW_NUMBER() OVER (ORDER BY nome_completo)) AS COD_ID,
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    '' AS DELETADO
FROM dbo.tb_clientes_tmp
GO

-- ============================================================
-- Abordagem 5: Sem IDENTITY 
-- com ROW_NUMBER + CROSS JOIN (permite execuções múltiplas)
-- ============================================================
INSERT INTO dbo.tb_cliente
(
    COD_ID,
    NOME_COMPLETO,
    CPF,
    SEXO,
    DATA_NASC,
    CEP,
    LOGRADOURO,
    NUMERO,
    COMPLEMENTO,
    BAIRRO,
    MUNICIPIO,
    ESTADO,
    DDD,
    TELEFONE,
    EMAIL,
    DELETADO
)
SELECT
    CONVERT(INT, ROW_NUMBER() OVER (ORDER BY tmp.nome_completo) + t1.max_cod_id) AS COD_ID,
    tmp.NOME_COMPLETO,
    tmp.CPF,
    tmp.SEXO,
    tmp.DATA_NASC,
    tmp.CEP,
    tmp.LOGRADOURO,
    tmp.NUMERO,
    tmp.COMPLEMENTO,
    tmp.BAIRRO,
    tmp.MUNICIPIO,
    tmp.ESTADO,
    tmp.DDD,
    tmp.TELEFONE,
    tmp.EMAIL,
    '' AS DELETADO
FROM dbo.tb_clientes_tmp AS tmp
CROSS JOIN
(
    SELECT ISNULL(MAX(COD_ID), 0) AS max_cod_id
    FROM dbo.tb_cliente
) AS t1
GO
