
BEGIN TRANSACTION 

UPDATE vendasecf 
SET    cupclicod = 199 
WHERE  filcod = 4 
       AND cupdatmov = '2015-04-01' 
       AND cupcodigo = 82766 
       AND caicod = 2 

BEGIN TRANSACTION 

UPDATE movestoque 
SET    nfforcod = 199 
WHERE  nfdatemis = '2015-04-01' 
       AND nffilcod = 4 
       AND nfnumdoc = 82766 
       AND nfnumero = 341612 

COMMIT -- OU ROLBACK 

 