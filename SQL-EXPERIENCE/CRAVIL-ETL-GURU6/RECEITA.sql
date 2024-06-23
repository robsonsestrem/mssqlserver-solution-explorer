USE GesCooper90
GO
DECLARE @datainicio DATETIME = '2017-02-22 00:00:00.000'
DECLARE @datafinal DATETIME =  '2017-02-22 23:59:59.997' -- caso informar horas vai trazer

SELECT 
	   x.Filial, 
       x.NomeFilial, 
       x.setor, 
       x.NomeSetor, 
       x.secao, 
       x.NomeSecao, 
       x.CentroCusto, 
       x.NomeCentro, 
       x.NumControle, 
       x.NF, 
       x.Op, 
       x.VendRepre, 
       x.NomeRepre, 
       x.ClienteFornecedor, 
       x.NomeCliente, 
       x.Cidade, 
       x.Item, 
       x.Nomeitem, 
       x.Emissao, 
       x.CodFamilia, 
       x.NomeFamilia, 
       x.CodGrupo, 
       x.NomeGrupo, 
       x.CodSubgrupo, 
       x.NomeSubgrupo, 
       x.Desconto, 
       x.Pis, 
       x.Cofins, 
       x.Icms, 
       x.Comissao, 
       ( ( x.Margem / 100 ) * ( x.ValorBruto ) ) AS Margem R$, 
       x.Peso, 
       x.Qtdade, 
       x.ValorBruto, 
       CASE 
         WHEN x.peso > 0 THEN ( ( ( x.frete ) / z.SomaPeso ) * x.Peso ) 
         ELSE 0 
       END												AS Frete, 


       CASE 
         WHEN x.Op NOT IN ( 5, 60 ) 
              AND x.Peso = 0 THEN 'Sem peso' 
         ELSE 'Correto' 
       END												AS Status,


	   cast(cmv.CustoMedioUnitario as money)		as CMV,
	 
	   cast(cmv.CustoMedioUnitario as money) * x.Qtdade		 as CMV x QTDADE 
        
FROM   (SELECT y.Filial, 
               y.Emissao, 
               y.NumControle, 
               Sum(Y.Peso) AS SomaPeso 
        FROM   vw_Movimentacao_Receita AS y 
        WHERE  y.Emissao between @datainicio AND @datafinal 
        GROUP  BY y.Filial,				
                  y.Emissao, 
                  y.NumControle
		) AS z 

       INNER JOIN vw_Movimentacao_Receita AS x  
               ON x.Filial = z.Filial 
                  AND x.Emissao = z.Emissao 
                  AND x.NumControle = z.NumControle 
	   CROSS apply GetCustoMercadoria(X.Filial, X.Item, X.Emissao) AS cmv	       
WHERE  x.Emissao between @datainicio AND @datafinal 











