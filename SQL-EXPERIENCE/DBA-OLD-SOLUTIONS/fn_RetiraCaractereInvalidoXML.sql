/*
 *
    OBJETIVO: Função para remover caracteres inválidos para formatação XML,
              substituindo-os por '?' para evitar problemas de parsing.
    PROJETO: mssqlserver-solution-explorer
    
    - Caracteres inválidos em XML: 0x00-0x08, 0x0B, 0x0C, 0x0E-0x1F
 *
 */
-- ================================================================================================================================
-- FUNÇÃO: fncRetira_Caractere_Invalido_XML
-- Substitui caracteres de controle inválidos para XML por '?'
-- ================================================================================================================================
USE [YOUR_DATABASE]
GO

CREATE FUNCTION Management.[fncRetira_Caractere_Invalido_XML]
(
    @Text VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @Result NVARCHAR(4000)

    -- Substitui os caracteres de controle (0x01 a 0x1F) por '?'
    -- Exceto os caracteres 0x09 (TAB), 0x0A (LF), 0x0D (CR) que são válidos no XML
    SELECT
        @Result =
        REPLACE(
            REPLACE(
                REPLACE(
                    REPLACE(
                        REPLACE(
                            REPLACE(
                                REPLACE(
                                    REPLACE(
                                        REPLACE(
                                            REPLACE(
                                                REPLACE(
                                                    REPLACE(
                                                        REPLACE(
                                                            REPLACE(
                                                                REPLACE(
                                                                    REPLACE(
                                                                        REPLACE(
                                                                            REPLACE(
                                                                                REPLACE(
                                                                                    REPLACE(
                                                                                        REPLACE(
                                                                                            REPLACE(
                                                                                                REPLACE(
                                                                                                    REPLACE(
                                                                                                        REPLACE(
                                                                                                            REPLACE(
                                                                                                                REPLACE(
                                                                                                                    REPLACE(
                                                                                                                        @Text,
                                                                                                                        NCHAR(1), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(2), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(3), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(4), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(5), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(6), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(7), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(8), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(11), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(12), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(14), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(15), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(16), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(17), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(18), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(19), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(20), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(21), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(22), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(23), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(24), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(25), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(26), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(27), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(28), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(29), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(30), N'?'
                                                                                                                    ),
                                                                                                                        NCHAR(31), N'?'
                                                                                                                    )
    RETURN @Result
END
GO


-- ================================================================================================================================
-- EXEMPLO DE TESTE DA FUNÇÃO
-- ================================================================================================================================
DECLARE @textoComCaracteresInvalidos VARCHAR(MAX)
SET @textoComCaracteresInvalidos = 'Texto' + NCHAR(1) + 'com' + NCHAR(2) + 'caracteres' + NCHAR(31) + 'invalidos'

SELECT
    @textoComCaracteresInvalidos AS TextoOriginal,
    Management.fncRetira_Caractere_Invalido_XML(@textoComCaracteresInvalidos) AS TextoLimpo
GO

-- Resultado esperado:
-- TextoOriginal: Texto[caractere]com[caractere]caracteres[caractere]invalidos
-- TextoLimpo:    Texto?com?caracteres?invalidos
