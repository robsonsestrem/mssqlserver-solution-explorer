-------------------------------------------------------------------------------------------------------------
-- Refer�ncia -> http://www.sqlservercentral.com/scripts/Converter+Inteiro+em+Horas/73984/
-- Foi necess�rio para campos da senior onde � um interio com minutos totais
-------------------------------------------------------------------------------------------------------------
use YOUR_DATABASE
go

create or alter FUNCTION Management.fn_IntToTime(@TEMPO INT)

RETURNS VARCHAR(20)
with encryption
AS
BEGIN
DECLARE @HORARIO VARCHAR(20)

DECLARE @HORA    INT
DECLARE @MINUTO  INT
DECLARE @SEGUNDO INT

SET @HORA    = (@TEMPO/3600)
SET @MINUTO  = (@TEMPO%3600) / 60
SET @SEGUNDO = (@TEMPO%3600) % 60


SELECT @HORARIO =
    CASE WHEN @TEMPO/3600 >= 1 THEN

        CASE LEN(CAST((@HORA)        AS VARCHAR)) WHEN 1 THEN '0' ELSE '' END
      + CAST ((@HORA) AS VARCHAR) + ':'

      + CASE LEN(CAST((@MINUTO)        AS VARCHAR)) WHEN 1 THEN '0' ELSE '' END
      + CAST((@MINUTO) AS VARCHAR) +  ':'

      + CASE LEN(CAST((@SEGUNDO)    AS VARCHAR)) WHEN 1 THEN '0' ELSE '' END
      + CAST((@SEGUNDO) AS VARCHAR)

    ELSE
        CASE LEN(CAST((@MINUTO)        AS VARCHAR)) WHEN 1 THEN '0' ELSE '' END
      + CAST((@MINUTO) AS VARCHAR) +  ':'

      + CASE LEN(CAST((@SEGUNDO)    AS VARCHAR)) WHEN 1 THEN '0' ELSE '' END
      + CAST((@SEGUNDO) AS VARCHAR)
    END

RETURN(@HORARIO)
END


----------------------------------------------------------------------------------------------------------------------
--select 
---- c�lculodo para valor inteiro, se fosse decimal o que vem depois da v�rgula � percentula de 60, ou seja, 80% de 60
--528 / 60 horas			
--,  528 % 60 as minutos	-- o que sobra � o percentual de 60 (1 hora)