--------------------------------------------------------------------------------------------------------
-- criando uma função...
--------------------------------------------------------------------------------------------------------
CREATE  FUNCTION FVALIDA_NUMEROS (@PALAVRA VARCHAR (1000)) 
RETURNS VARCHAR (1000) AS 
BEGIN
DECLARE
 @RESULTADO VARCHAR (1000), 
 @LETRA VARCHAR(1),
 @QTD_PALAVRA INTEGER,
 @CONT INTEGER

SET @CONT = 0 
SET @QTD_PALAVRA = LEN(@PALAVRA)
SET @RESULTADO = 0
WHILE @CONT < @QTD_PALAVRA 
 BEGIN 
  SET @CONT = @CONT + 1 
  SET @LETRA = SUBSTRING(@PALAVRA,@CONT,1)
  IF @LETRA  IN (0,1,2,3,4,5,6,7,8,9 ) 
   BEGIN
    SET @RESULTADO =  @RESULTADO +  @LETRA 
   END
 END

 RETURN @RESULTADO 
END


--------------------------------------------------------------------------------------------------------
--A lógica para a função abaixo é a seguinte:
--Recebo via Parâmetro a Palavra que quero buscar e a String toda ou texto.
--Faço um loop baseado no tamanho do texto.
--Pego o tamanho da palavra que está sendo procurada e a cada caracter do texto, 
--andamos o tamanho da palavra e comparamos se isso é igual a palavra procurada.
--Se for, soma um no contador de palavras e continua.
--------------------------------------------------------------------------------------------------------
CREATE FUNCTION CountSearchPat
(
      @Word Varchar(100),
      @String Varchar(Max)
)
RETURNS int
AS
BEGIN
 
      -- Declaração Variáveis
      Declare @Count int, @CountWord int
 
      -- Contador de quantas vezes apareceu a palavra
      Set @CountWord = 0
 
      -- Contador do Loop
      Set @Count = 0
 
      -- Loop
      While @Count <= Len(@String)
      Begin
 
            -- Se encontrar a palavra soma mais um para @CountWord
            Set @CountWord =
                  Case When Substring(@String, @Count, Len(@Word)) = @Word
                        Then @CountWord + 1
                        Else @CountWord
                  End
 
            -- Soma mais um ao contador
            Set @Count = @Count + 1
 
      End
 
      -- Retorna Valor
      Return @CountWord
 
END


--------------------------------------------------------------------------------------------------------
--Função isdigit no SQL Server 
--Esta função escalar excelente para testar se um derterminado campo tem strings, 
--letras ou apenas números em SQL Server. 
--Retorna 1 para verdadeiro caso seja apenas números e 0 para falso, caso encontre textos dentro do campo.
--------------------------------------------------------------------------------------------------------
IF EXISTS (
            SELECT * 
              FROM sys.objects 
             WHERE object_id = OBJECT_ID(N'[dbo].[sp_isdigit]') 
               AND type IN (N'FN')
           )
 DROP FUNCTION sp_isdigit
GO
 
CREATE FUNCTION sp_isdigit (@string varchar(max))  
 
RETURNS INT
AS
BEGIN
   RETURN
   (  
     SELECT CASE WHEN PATINDEX('%[^0-9]%', @string) > 0 THEN
       0
      ELSE
       1
      END AS sp_isdigit
   )
END;
GO
/*
Exemplo: 
 
SELECT dbo.sp_isdigit('ISSO É UM VALOR NÚMERICO?'); -- 0 
SELECT dbo.sp_isdigit('3000'); --retorno 1
SELECT dbo.sp_isdigit('2700.00'); --retorno 0 
*/


