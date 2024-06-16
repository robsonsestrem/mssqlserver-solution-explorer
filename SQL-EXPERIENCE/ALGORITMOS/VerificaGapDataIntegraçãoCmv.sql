use IntegraTICravil
go
declare @mes int = 04
	   ,@ano int = 2017


  SELECT DAY(t1.DataEmissao) + 1 AS Inicio,
   (
   SELECT MIN(DAY(t2.DataEmissao)) FROM Bi.HistoricoCMV AS t2
   WHERE DAY(t2.DataEmissao) > DAY(t1.DataEmissao)
   AND MONTH(t2.DataEmissao) = @mes
   AND YEAR(t2.DataEmissao) = @ano
   ) - 1 AS Termino

   FROM Bi.HistoricoCMV AS t1
   WHERE NOT EXISTS
	  (
	  SELECT * FROM Bi.HistoricoCMV AS t2
	  WHERE DAY(t2.DataEmissao) = DAY(t1.DataEmissao) + 1
	  AND MONTH(t2.DataEmissao) = @mes
	  AND YEAR(t2.DataEmissao) = @ano
	  )
	AND DAY(t1.DataEmissao) < (SELECT MAX(DAY(t1.DataEmissao)) 
							   FROM Bi.HistoricoCMV AS t1
							   WHERE MONTH(t1.DataEmissao) = @mes
							   AND YEAR(t1.DataEmissao) = @ano
							   )
	AND MONTH(t1.DataEmissao) = @mes
	AND YEAR(t1.DataEmissao) = @ano




	SELECT * FROM Bi.HistoricoCMV as c
	where DataEmissao >= '20170416 00:00:00.000' and DataEmissao <= '20170416 23:59:59.997'