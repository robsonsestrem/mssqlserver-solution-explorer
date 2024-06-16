-------------------------------------------------------------------------------------------------------------------------------------
-- FONTES
-- http://www.dbinternals.com.br/?p=51
-- https://dba-pro.com/como-gerar-numeros-aleatorios-no-sql/
-------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Upper INT;
DECLARE @Lower INT
SET @Lower = 1 ---- The lowest random number
SET @Upper = 999 ---- The highest random number

--Para gerar Randomicamente os nmeros em float:
SELECT Cast((@Upper - @Lower -1) * RAND(CAST(NEWID() AS varbinary)) + @Lower as Float)

--Para gerar Randomicamente os nmeros em Int:
SELECT Cast((@Upper - @Lower -1) * RAND(CAST( NEWID() AS varbinary )) + @Lower as Int)


-------------------------------------------------------------------------------------------------------------------------------------
-- meu teste
select left(replace(checksum(newid()),'-',''),3)