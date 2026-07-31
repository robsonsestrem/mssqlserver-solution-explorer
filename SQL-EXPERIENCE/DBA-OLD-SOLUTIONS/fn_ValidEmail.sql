/*
 *
	OBJETIVO: Função scalar para validação de formato de e-mail no SQL Server,
			  verificando se a string contém apenas caracteres permitidos
			  (letras minúsculas, números, @, ., _, -) e se segue o padrão
			  básico de e-mail (algo@algo.algo).
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Função de Validação de E-mail
-- ============================================================
USE YOUR_DATABASE
GO

CREATE FUNCTION Management.fn_ValidEmail
(
    @Ds_Email AS VARCHAR(MAX)
)
RETURNS BIT
AS
BEGIN
    DECLARE @Retorno AS BIT = 0

    -- Validação em três etapas:
    -- 1. Verifica se contém apenas caracteres permitidos
    -- 2. Verifica se segue o padrão básico (algo@algo.algo)
    -- 3. Verifica se não contém @ duplicado
    SELECT
        @Retorno = 1
    WHERE @Ds_Email NOT LIKE '%[^a-z,0-9,@,.,_,-]%'
        AND @Ds_Email LIKE '%_@_%_.__%'
        AND @Ds_Email NOT LIKE '%_@@_%_.__%'

    RETURN @Retorno
END
GO


-- ============================================================
-- Exemplo de Uso
-- ============================================================
SELECT Management.fn_ValidEmail('sestrem.robson@gmail.com.br')


