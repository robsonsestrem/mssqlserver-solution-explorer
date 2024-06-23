------------------------------------------------------------------------------
--	zerar os produtos quando se usa a rotina do ajuste geral
------------------------------------------------------------------------------
						--Identifica
USE gescooper90
go
select i2.InvDatBal, i2.InvFilCod, i2.InvIteFec, i2.InvProCod, i2.InvProNom
from INVENTARIOLEVEL1 AS i2
WHERE  invfilcod = 6
       AND invdatbal = '2017-08-09'
						
						--Altera	
USE gescooper90 
go
BEGIN TRAN 

UPDATE INVENTARIOLEVEL1 
SET    InvIteFec = 0 
WHERE  invfilcod = 28
       AND InvDatBal = '2016-03-28'
       
COMMIT 

SELECT @@TRANCOUNT 

ROLLBACK

------------------------------------------------------------------------------
--	zerar data do encerramento ajuste Parcial (invDatEnc)
------------------------------------------------------------------------------
					--Identifica inventário
USE gescooper90
go
SELECT * 
FROM   inventario 
WHERE  invfilcod = 17
       AND invdatbal = '2017-08-09'
       
					--Altera inventário
USE gescooper90 
go
BEGIN TRAN 

UPDATE inventario 
SET    invdatenc = '1753-01-01' 
WHERE  invfilcod = 17
       AND invdatenc = '2017-08-10'	
	   and InvDatBal = '2017-08-09' -- a data de encerramento pode ter mais datas de balanço encerrados

COMMIT 

SELECT @@TRANCOUNT 

ROLLBACK

-- levantamento físico no SIG gera notas de operação 8 e 9
-- sendo necessário cancelar e eliminar antes de refazer o ajuste.