----------------------------------------------------------------------------------------------------------------------------------
-- Refer�ncias -> https://www.dirceuresende.com/blog/quebrando-strings-em-sub-strings-utilizando-separador-no-sql-server/
-- permite quebrar uma string delimitada por algum (ou alguns) caracter em sub-strings. 
-- Para quem � desenvolvedor Web, � o que faz a fun��o explode do PHP ou a Split do Java, Javascript, C#, etc..
-- Basicamente, voc� tem uma string como o exemplo abaixo:

--nome;nascimento;email
--Nome 1;1994-05-29;email@gmail.com
--Nome 2;1981-07-10;email@yahoo.com.br
--Nome 3;2001-02-27;email@hotmail.com

-- Imagine que voc� queira recuperar apenas o nome e o e-mail dos registros acima. Dividindo 
-- cada linha utilizando o caracter �;� como separador, temos uma 3 sub-strings. 
-- � exatamente isso que a fun��o abaixo faz:
----------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO
CREATE FUNCTION Management.[fn_ValueSeparateByVarious] ( @String varchar(8000), @Separador varchar(8000), @PosBusca int )
RETURNS varchar(8000)
WITH ENCRYPTION
AS BEGIN
    
    DECLARE @Index int, @Max int, @Retorno varchar(8000)

    DECLARE @Partes as TABLE ( Id_Parte int identity(1,1), Texto varchar(8000) )

    SET @Index = charIndex(@Separador,@String)

    WHILE (@Index > 0) BEGIN	
        INSERT INTO @Partes SELECT SubString(@String,1,@Index-1)
        SET @String = Rtrim(Ltrim(SubString(@String,@Index+Len(@Separador),Len(@String))))
        SET @Index = charIndex(@Separador,@String)
    END

    IF (@String != '') INSERT INTO @Partes SELECT @String

    SELECT @Max = Count(*) FROM @Partes

    IF (@PosBusca = 0) SET @Retorno = Cast(@Max as varchar(5))
    IF (@PosBusca < 0) SET @PosBusca = @Max + 1 + @PosBusca
    IF (@PosBusca > 0) SELECT @Retorno = Texto FROM @Partes WHERE Id_Parte = @PosBusca

    RETURN RTRIM(LTRIM(@Retorno))

END
GO


----------------------------------------------------------------------------------------------------------------------------------
-- EXEMPLO DE USO
----------------------------------------------------------------------------------------------------------------------------------
DECLARE @strOrigem VARCHAR(MAX) = 'Testando|String|Para|O|Blog'
 
SELECT Management.fn_Split(@strOrigem, '|', 1) -- Vai imprimir na tela 'Testando'
SELECT Management.fn_Split(@strOrigem, '|', 5) -- Vai imprimir na tela 'Blog'