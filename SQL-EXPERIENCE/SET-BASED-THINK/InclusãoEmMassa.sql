
--------------------------------------------------------------------------------------------------------------------------------------------
-- Soluções para inclusão em massa
--------------------------------------------------------------------------------------------------------------------------------------------

-- com cursor

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
	
	SELECT NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, COD_ID
	FROM dbo.tb_clientes_tmp

	OPEN cursor_objects
	FETCH NEXT FROM cursor_objects INTO @NOME_COMPLETO, @CPF, @SEXO, @DATA_NASC, @CEP, @LOGRADOURO, @NUMERO, @COMPLEMENTO, @BAIRRO, @MUNICIPIO, @ESTADO, @DDD, @TELEFONE, @EMAIL, @COD_ID

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		
		SET @COD_ID = (SELECT CAST(ISNULL(MAX(COD_ID), '')+1 AS int) FROM dbo.tb_cliente)

		INSERT INTO dbo.tb_cliente(COD_ID,NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL)
		values				(@COD_ID,@NOME_COMPLETO, @CPF, @SEXO, @DATA_NASC, @CEP, @LOGRADOURO, @NUMERO, @COMPLEMENTO, @BAIRRO, @MUNICIPIO, @ESTADO, @DDD, @TELEFONE, @EMAIL)

		FETCH NEXT FROM cursor_objects INTO @NOME_COMPLETO, @CPF, @SEXO, @DATA_NASC, @CEP, @LOGRADOURO, @NUMERO, @COMPLEMENTO, @BAIRRO, @MUNICIPIO, @ESTADO, @DDD, @TELEFONE, @EMAIL, @COD_ID
	END

--------------------------------------------------------------------------------------------------------------------------------------------
-- agora com soluções de melhor desempenho
--------------------------------------------------------------------------------------------------------------------------------------------


-- exemplo com uma tabela que tenha identity
INSERT INTO dbo.tb_cliente(NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, DELETADO)
SELECT NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, '' as DELETADO
FROM dbo.tb_clientes_tmp
GO


-- exemplo sem identity e com max
INSERT INTO dbo.tb_cliente(COD_ID,NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, DELETADO)
SELECT (SELECT CAST(ISNULL(MAX(COD_ID),'') +1 AS int) FROM dbo.tb_cliente), NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, '' as DELETADO
FROM dbo.tb_clientes_tmp


-- exemplo sem identity 
-- é quase igual ao MAX
-- neste caso só server para a tabela quando ta vazia, se eu rodar o script mais uma vez ele viola a primary key
INSERT INTO dbo.tb_cliente(COD_ID,NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, DELETADO)
SELECT
(convert(int,ROW_NUMBER() over(order by nome_completo))) -- dessa forma o sql server não precisa buscar o último registro como é feito no MAX
,NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, '' as DELETADO
FROM dbo.tb_clientes_tmp



-- exemplo sem identity e com o cross join
-- com esse posso rodar várias vezes o script 
-- que a sequência vai se manter consecutiva
INSERT INTO dbo.tb_cliente(COD_ID,NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, DELETADO)
SELECT
(convert(int,ROW_NUMBER() over(order by nome_completo))+t1.max_cod_id) 
,NOME_COMPLETO, CPF, SEXO, DATA_NASC, CEP, LOGRADOURO, NUMERO, COMPLEMENTO, BAIRRO, MUNICIPIO, ESTADO, DDD, TELEFONE, EMAIL, '' as DELETADO
FROM dbo.tb_clientes_tmp as tmp
cross join (
	SELECT ISNULL(MAX(COD_ID), '0') AS max_cod_id FROM dbo.tb_cliente
) as t1


