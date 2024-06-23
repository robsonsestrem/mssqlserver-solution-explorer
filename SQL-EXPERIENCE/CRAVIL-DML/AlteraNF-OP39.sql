
 
-- Identificação - 
USE gescooper90 

SELECT nffilcod                         AS Filial, 
       nfnumero                         AS Pedido, 
       CONVERT(VARCHAR, nfdatemis, 105) AS Data, 
       nfopeestcod                      AS Código, 
       nfforcod                         AS Fornecedor 
FROM   movestoque 
WHERE  nffilcod = 77 
       AND nfdatemis >= '2014-07-23' 
       AND nfopeestcod = 39 

-- Alteração do transacionador abaixo - 
UPDATE movestoque 
SET    nfforcod = 1801 
WHERE  nffilcod = 77 --definir todas as condições para não 
       AND nfdatemis = '2014-07-23' --afetar linhas indesejadas 
       AND nfopeestcod = 39 
       AND nfnumero = 927876 