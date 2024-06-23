USE GesCooper90
GO

SELECT * FROM MOVESTOQUE as m
where m.NFNumCarga = 32214
and m.NfFilCod = 76
and m.NfTranPlaca = 'QHIL1727'


USE GesCooper90
GO

BEGIN TRAN

UPDATE MOVESTOQUE SET NfTranPlaca = 'QHL1727'
where NFNumCarga = 32214
and NfFilCod = 76
and NfTranPlaca = 'QHIL1727'

COMMIT

SELECT @@TRANCOUNT 

ROLLBACK