/*
	OBJETIVO: Fornecer funções auxiliares para identificar, localizar e remover
			  caracteres ocultos (não imprimíveis ou de controle) em strings,
			  utilizando expressões PATINDEX com listas de caracteres permitidos
			  para detectar e limpar dados problemáticos em tabelas.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS:
	https://www.dirceuresende.com/blog/sql-server-como-identificar-e-substituir-coisas-estranhas-caracteres-ocultos-invisiveis-em-strings-e-tabelas/
*/

-- ============================================================
-- Função: fn_Possui_Caractere_Oculto
-- Retorna 1 se a string contiver caracteres não permitidos
-- ============================================================
CREATE FUNCTION [dbo].[fn_Possui_Caractere_Oculto]
(
      @String VARCHAR(MAX)
)
RETURNS BIT
WITH ENCRYPTION
AS
BEGIN
    RETURN
    (
        CASE
            WHEN PATINDEX
                 (
                     '%[^ !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\^_`abcdefghijklmnopqrstuvwxyz|{}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ[[]%'
                   , REPLACE(@String, ']', '')
                 ) > 0
            THEN 1
            ELSE 0
        END
    );
END;
GO

-- ============================================================
-- Exemplo de uso: fn_Possui_Caractere_Oculto
-- ============================================================
/*
SELECT
      hbp.TextData
FROM history_blocked_process                                                        AS hbp
WHERE dbo.fn_Possui_Caractere_Oculto(CAST(hbp.TextData AS NVARCHAR(MAX))) = 1;
GO
*/

-- ============================================================
-- Função: fn_Mostra_Caracteres_Ocultos
-- Retorna a posição e o código ASCII de cada caractere oculto
-- ============================================================
CREATE FUNCTION [dbo].[fn_Mostra_Caracteres_Ocultos]
(
      @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @Result            VARCHAR(MAX) = '';
    DECLARE @Contador          INT          = 1;
    DECLARE @Total             INT;
    DECLARE @AdicionarBarra    BIT          = 0;

    SET @Total = LEN(@String);

    WHILE (@Contador <= @Total)
    BEGIN
        IF (PATINDEX
            (
                '%[^ !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\^_`abcdefghijklmnopqrstuvwxyz|{}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ[[]%'
              , SUBSTRING(REPLACE(@String, ']', ''), @Contador, 1)
            ) > 0
        )
        BEGIN
            SET @Result +=
                CASE
                    WHEN @AdicionarBarra = 1
                    THEN ' | '
                    ELSE ''
                END
                + 'Pos ' + CAST(@Contador AS VARCHAR(100))
                + ': CHAR(' + CAST(ASCII(SUBSTRING(@String, @Contador, 1)) AS VARCHAR(5))
                + ')';
            SET @AdicionarBarra = 1;
        END;

        SET @Contador += 1;
    END;

    RETURN @Result;
END;
GO

-- ============================================================
-- Exemplo de uso: fn_Mostra_Caracteres_Ocultos
-- ============================================================
/*
DECLARE @STRING NVARCHAR(MAX) =
(
    SELECT TOP 1
          CAST(hbp.TextData AS NVARCHAR(MAX))
    FROM history_blocked_process                                                        AS hbp
);

SELECT dbo.fn_Mostra_Caracteres_Ocultos(@STRING)                                       AS [hidden_data];
-- Resultado esperado: Pos 1119: CHAR(10) | Pos 2149: CHAR(10)
GO
*/

-- ============================================================
-- Função: fn_Remove_Caracteres_Ocultos
-- Remove todos os caracteres não permitidos da string
-- ============================================================
CREATE FUNCTION [dbo].[fn_Remove_Caracteres_Ocultos]
(
      @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN
    DECLARE @Result           VARCHAR(MAX);
    DECLARE @StartingIndex    INT = 0;

    WHILE (1 = 1)
    BEGIN
        SET @StartingIndex = PATINDEX
                             (
                                 '%[^ !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\^_`abcdefghijklmnopqrstuvwxyz|{}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ[[]%'
                               , REPLACE(@String, ']', '')
                             );

        IF (@StartingIndex <> 0)
        BEGIN
            SET @String = REPLACE(@String, SUBSTRING(@String, @StartingIndex, 1), '');
        END;
        ELSE
        BEGIN
            BREAK;
        END;
    END;

    SET @Result = REPLACE(@String, '|', '');

    RETURN @Result;
END;
GO

-- ============================================================
-- Exemplo de uso: fn_Remove_Caracteres_Ocultos
-- ============================================================
/*
DECLARE @STRING NVARCHAR(MAX) =
(
    SELECT TOP 1
          CAST(hbp.TextData AS NVARCHAR(MAX))
    FROM history_blocked_process                                                        AS hbp
);

SELECT dbo.fn_Remove_Caracteres_Ocultos(@STRING)                                      AS [no_hidden_data];
GO
*/