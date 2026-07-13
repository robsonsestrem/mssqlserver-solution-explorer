-- 1 = v�rgula
-- 2 = ponto
-- 15 caracteres � o limite para o bigint, assim o reverse ficou 
-- arredondado para 20, pois no total com os pontos fica 19 caracteres
-- mesmo n�o entrando na condi��o do ELSE dava problema de erro de convers�o bigint para varchar

USE YOUR_DATABASE
GO
create or alter Function Management.fn_FormatIntToThousands(@Valor bigint, @separador tinyint) 
Returns varchar(30) 
with encryption
as
Begin
	RETURN
		CASE 
			 WHEN @separador = 1 THEN REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (30),	CONVERT (MONEY, @valor), 1)), 4, 20))
			 
			 WHEN @separador = 2 THEN REPLACE( REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (30),	CONVERT (MONEY, @valor), 1)), 4, 20)),',','.' )
		ELSE cast(@Valor as varchar(30))	
		END

End;
Go