use CooperSystem
go

CREATE OR ALTER FUNCTION System.fn_Isdigit (@string varchar(max))  
RETURNS INT
with encryption
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