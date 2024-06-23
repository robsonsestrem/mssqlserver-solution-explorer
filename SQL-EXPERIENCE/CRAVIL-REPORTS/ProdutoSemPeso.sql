SELECT p.procod                                        AS Codigo, 
       p.pronom                                        AS Nome, 
       p.profamcod                                     AS Familia, 
       p.progrpcod                                     AS Grupo, 
       p.prosubcod                                     AS Subgrupo, 
       (SELECT dbo.Getestoque(1, p.procod, Getdate())) AS SaldoEstoque, 
       p.pronomembestoque                              AS Medida, 
       p.provlrpeso                                    AS PesoBruto, 
       p.provlrpliq                                    AS PesoLíquido 
FROM   produtos AS p 
WHERE  prosituacao LIKE '%s' -- só ativos 
       AND provlrpliq = 0 
       AND provlrpeso = 0 
ORDER  BY profamcod 
-- usada função escalar -> dbo.getEstoque 