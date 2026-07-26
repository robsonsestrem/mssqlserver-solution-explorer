---------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/sql-server-como-identificar-e-substituir-coisas-estranhas-caracteres-ocultos-invisiveis-em-strings-e-tabelas/
---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Para ajudar nessa identificação, a função abaixo nos ajudará a identificar as linhas que possuem esses caracteres de controle:
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fn_Possui_Caractere_Oculto](
    @String VARCHAR(MAX)
)
RETURNS BIT
WITH ENCRYPTION
AS
BEGIN
    RETURN (CASE WHEN PATINDEX('%[^ !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\^_`abcdefghijklmnopqrstuvwxyz|{}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ[[]%', REPLACE(@String, ']', '')) > 0 THEN 1 ELSE 0 END)
END
GO


-------------------------------------------------------
-- Exemplo de uso -> [fn_Possui_Caractere_Oculto]
-------------------------------------------------------
SELECT hbp.TextData 
FROM history_blocked_process hbp
WHERE dbo.[fn_Possui_Caractere_Oculto] (CAST(hbp.TextData AS NVARCHAR(MAX))) = 1
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Vai receber a string original e retornar a posição e qual o código ASCII de cada caracter oculto na string:
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fn_Mostra_Caracteres_Ocultos](
    @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

    DECLARE 
        @Result VARCHAR(MAX) = '', 
        @Contador INT = 1,
        @Total INT,
        @AdicionarBarra BIT = 0
    
    
    SET @Total = LEN(@String)

    WHILE(@Contador <= @Total)
    BEGIN
        
        IF (PATINDEX('%[^ !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\^_`abcdefghijklmnopqrstuvwxyz|{}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ[[]%', SUBSTRING(REPLACE(@String, ']', ''), @Contador, 1)) > 0)
        BEGIN
            SET @Result += (CASE WHEN @AdicionarBarra = 1 THEN ' | ' ELSE '' END) + 'Pos ' + CAST(@Contador AS VARCHAR(100)) + ': CHAR(' + CAST(ASCII(SUBSTRING(@String, @Contador, 1)) AS VARCHAR(5)) + ')'
            SET @AdicionarBarra = 1
        END

        SET @Contador += 1

    END
    
    RETURN @Result

END
GO


-------------------------------------------------------
-- Exemplo de uso -> [fn_Mostra_Caracteres_Ocultos]
-------------------------------------------------------
DECLARE @STRING NVARCHAR(MAX) = (SELECT TOP 1 CAST(hbp.TextData AS NVARCHAR(MAX)) FROM history_blocked_process hbp)
SELECT dbo.fn_Mostra_Caracteres_Ocultos(@STRING) AS [hidden_data]
-- result: Pos 1119: CHAR(10) | Pos 2149: CHAR(10)


---------------------------------------------------------------------------------------------------------------------------------------------------------
-- Retorna os dados sem caracteres ocultos:
---------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[fn_Remove_Caracteres_Ocultos](
    @String VARCHAR(MAX)
)
RETURNS VARCHAR(MAX)
AS
BEGIN

    
    DECLARE 
        @Result VARCHAR(MAX), 
        @StartingIndex INT = 0
    
    
    WHILE (1 = 1)
    BEGIN 
        
        SET @StartingIndex = PATINDEX('%[^ !"#$%&''()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ\^_`abcdefghijklmnopqrstuvwxyz|{}~€‚ƒ„…†‡ˆ‰Š‹ŒŽ‘’“”•–—˜™š›œžŸ¡¢£¤¥¦§¨©ª«¬­®¯°±²³´µ¶·¸¹º»¼½¾¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ[[]%', REPLACE(@String, ']', ''))
        
        IF (@StartingIndex <> 0)
            SET @String = REPLACE(@String,SUBSTRING(@String, @StartingIndex,1),'') 
        ELSE
            BREAK

    END	
    
    SET @Result = REPLACE(@String,'|','')
    
    RETURN @Result

END
GO


-------------------------------------------------------
-- Exemplo de uso -> [fn_Remove_Caracteres_Ocultos]
-------------------------------------------------------
DECLARE @STRING NVARCHAR(MAX) = (SELECT TOP 1 CAST(hbp.TextData AS NVARCHAR(MAX)) FROM history_blocked_process hbp)
SELECT dbo.[fn_Remove_Caracteres_Ocultos](@STRING) AS [no_hidden_data]

