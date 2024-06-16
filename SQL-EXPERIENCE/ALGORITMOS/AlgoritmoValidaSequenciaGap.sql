/*
SELECT ProdutoID + 1 AS Inicio,
  (SELECT MIN(P2.ProdutoID) FROM tblProdutos AS P2
   WHERE P2.ProdutoID > P1.ProdutoID) – 1 AS Termino
FROM tblProdutos AS P1
WHERE NOT EXISTS
  (SELECT * FROM tblProdutos AS P2
   WHERE P2.ProdutoID = P1.ProdutoID + 1)
  AND ProdutoID < (SELECT MAX(ProdutoID) FROM tblProdutos AS P1)
*/

-- REFERÊNCIA: GUSTAVO MAIA - MVP

use IntegraTICravil
go
  SELECT t1.IdBaseDados + 1 AS Inicio,
  (
   SELECT MIN(t2.IdBaseDados) FROM Management.InstanceDatabases AS t2
   WHERE t2.IdBaseDados > t1.IdBaseDados) - 1 AS Termino
   FROM Management.InstanceDatabases AS t1
   WHERE NOT EXISTS
	  (
	  SELECT * FROM Management.InstanceDatabases AS t2
	  WHERE t2.IdBaseDados = t1.IdBaseDados + 1
	  )
	AND t1.IdBaseDados < (SELECT MAX(t1.IdBaseDados) 

  FROM Management.InstanceDatabases AS t1
  )