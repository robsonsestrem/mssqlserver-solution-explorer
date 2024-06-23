------------------------------------------------------------------------------
-- Alterando data dos produtos do inventário (parte analítica)
------------------------------------------------------------------------------
						--Identifica
USE gescooper90 
go
select i2.InvDatBal, i2.InvFilCod, i2.InvIteFec, i2.InvProCod, i2.InvProNom
from INVENTARIOLEVEL1 AS i2
WHERE  invfilcod = 73
       AND invdatbal = '20170429'
						
						--Altera	
USE gescooper90 
go
BEGIN TRAN 

UPDATE INVENTARIOLEVEL1 
SET    InvDatBal = '20170430' 
WHERE  invfilcod = 73
       AND InvDatBal = '20170429'
       
COMMIT 

SELECT @@TRANCOUNT 

ROLLBACK

------------------------------------------------------------------------------
-- Alterando data de cada número de inventário (parte sintética)
------------------------------------------------------------------------------
					--Identifica inventário
SELECT * 
FROM   inventario 
WHERE  invfilcod = 73
       AND invdatbal = '20170429'
       
					--Altera inventário
USE gescooper90 

BEGIN TRAN 

UPDATE inventario 
SET    InvDatBal = '20170430' 
WHERE  invfilcod = 73
       AND InvDatBal = '20170429'	-- Obs.: data de encerramento sempre um dia após inventário

COMMIT 

SELECT @@TRANCOUNT 

ROLLBACK

-- levantamento físico no SIG gera notas de operação 8 e 9
-- sendo necessário cancelar e eliminar antes de refazer o ajuste.