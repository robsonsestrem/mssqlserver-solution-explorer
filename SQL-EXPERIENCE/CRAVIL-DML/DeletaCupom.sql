-- Identifica Cupom - 
SELECT * 
FROM   vendasecflevel1 --tabela filho com itens dos cupons de venda 
WHERE  filcod = 23 
       AND cupdatmov = '2015-06-24' 
       AND caicod = 3 
       AND caiopecod = 3
       AND CupCodigo = 0

-- deleta cupom reconhecido - 
BEGIN TRANSACTION 

DELETE FROM vendasecflevel1 
WHERE  filcod = 23 
       AND cupdatmov = '2015-06-24' 
       AND caicod = 3 
       AND caiopecod = 3
       AND CupCodigo = 0

COMMIT -- OU ROLBACK 



-- Identifica Cupom - 
SELECT filcod    AS Filial, 
       cupdatmov AS Data, 
       caicod    AS caixa, 
       caiopecod AS operador, 
       cupcodigo AS Cupom, 
       cupclicod AS Cliente 
FROM   vendasecf --Tabela pai apenas com os cupons 
WHERE  filcod = 23 
       AND cupdatmov = '2015-06-24' 
       AND caicod = 3 
       AND caiopecod = 3
       AND CupCodigo = 0

-- deleta cupom reconhecido - 
BEGIN TRANSACTION 

DELETE FROM vendasecf 
WHERE  filcod = 23 
       AND cupdatmov = '2015-06-24' 
       AND caicod = 3 
       AND caiopecod = 3
       AND CupCodigo = 0
       
COMMIT 



 

 

 

 

 

 

 

 
 
 
 
 