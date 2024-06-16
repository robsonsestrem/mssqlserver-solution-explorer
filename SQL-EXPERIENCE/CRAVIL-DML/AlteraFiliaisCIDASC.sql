SELECT t1.FilCod
, t1.FilNomReduzido
, t1.FilReceituario
FROM FILIAIS AS t1
WHERE t1.filflag2 = 0
AND t1.FilReceituario IN (3, 1)
AND t1.FilCod NOT IN (90,1)


BEGIN TRAN

UPDATE FILIAIS SET FILRECEITUARIO = 3
WHERE  FilReceituario = 1
AND FilFlag2 = 0
AND FilCod NOT IN (90,1)

COMMIT TRAN

ROLLBACK TRAN