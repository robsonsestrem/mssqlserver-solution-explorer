
USE gescooper90 

--teste primeiro para achar a nota (exemplo) 
SELECT colentnffilcod         AS Filial, 
       colentnfdatemis        AS DataEmissão, 
       colentnfnumero         AS NF, 
       colentiteprocod        AS Item, 
       colentiteqtdnotafiscal AS QtdNotaFiscal, 
       colentiteqtdleitor     AS Qtdade/Leitor, 
       colentiteqtddev        AS QtdDevolvida, 
       colentitebarras        AS CodBarras, 
       colentitedatvld        AS DataValidade 
FROM   colentradalevel1 
WHERE  colentnffilcod = 11 
       AND colentnfdatemis = CONVERT(DATETIME, '26/02/2015', 103) 
       AND colentnfnumero = 8045 
       AND colentiteprocod = 16958 

-- Após identificação é realizada alteração - 
UPDATE colentradalevel1 
SET    colentiteqtdleitor = 3 
-- qtdade a ser corrigida, pois passaram o leitor no barras para dar qtdade 
WHERE  colentnffilcod = 11 
       AND colentnfdatemis = CONVERT(DATETIME, '26/02/2015', 103) 
       AND colentnfnumero = 8045 
       AND colentiteprocod = 16958 