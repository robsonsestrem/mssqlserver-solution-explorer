SELECT T.tracod             AS Fornecedor, 
       T.tranom             AS Nome_Fornecedor, 
       P2.procod            AS Cod_Produto, 
       P.pronom             AS Nome_Produto, 
       CASE P.prosituacao 
         WHEN 's' THEN 'Ativo' 
         WHEN 'c' THEN 'Ativo-Compra_Direta' 
       END                  AS Situacao, 
       Isnull(( CASE T.trapermitetroca 
                  WHEN 0 THEN 'Não' 
                  WHEN 1 THEN 'Sim' 
                END ), ' ') AS Permite_Troca 
FROM   transacionadores AS T WITH(nolock) 
       INNER JOIN produtoslevel2 AS P2 WITH(nolock) 
               ON P2.proforcod = T.tracod 
       INNER JOIN produtos AS P 
               ON P.procod = P2.procod 
WHERE  T.trasit = 1 
       AND P.prosituacao <> 'n' 
ORDER  BY T.tracod, 
          P2.procod