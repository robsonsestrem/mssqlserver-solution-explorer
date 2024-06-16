use GesCooper90
go

declare @inicio datetime ='20170331'
declare @fim    datetime ='20170331'

SELECT
    v.Codigo,
    v.Nome,          
    v.Desativacao,
	v.Filial,
    avg(v.MargenCad) as MediaMargem,          
    sum(v.Quantidade) as Quantidade,  
	--              
    REPLACE(cast(sum(v.total - V.Desconto - V.PIS - V.Cofins - V.ICMS) as money),'.',',') AS 'R.o.l', -- receita operacional líquida (venda líquida)   
	-- 
    REPLACE(sum(v.Custo), '.',',')      AS Custo

	--sum(v.total / v.Quantidade)          AS PreçoMedio,
FROM
(
  SELECT 

		p2.procod             AS Codigo,
		p2.pronom             AS Nome,
		--
		CASE WHEN P2.ProFlag35 = 1 THEN 'HABILITADA'
		ELSE 'DESABILITADA'
		END              AS Desativacao,  
		--
		m.NfNumero            AS NumeroDoc,
		m.NfDatEmis            AS DataEmissao,
		m.NfFilCod            AS Filial,
        p2.ProVlrMargen           AS MargenCad,
        SUM(m2.ItemQtdade)       as Quantidade,
        SUM ((m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres)) AS Total,
        SUM(m2.itemvlrdesc)          AS Desconto,
        SUM (m2.itemvlrpis)          AS PIS,
        SUM (m2.itemvlrcofins)         AS COFINS,
		--
        SUM ((m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres)) * ((100 - cast(m2.itemredicms as decimal(15,2)) ) / 100)       AS ICMS,
		--
        (cast(cmv.CustoMercadoriaVendida as money) * sum(m2.ItemQtdade))      AS Custo -- SEGREDO PARA O CÁCULO DE CUSTO

   FROM TRANSACIONADORES AS t WITH(nolock)
   INNER JOIN MOVESTOQUE AS m WITH (nolock) 
   ON m.NfForCod = t.TraCod
   INNER JOIN MOVESTOQUELEVEL1 AS m2 WITH (nolock) 
    ON m2.NfFilCod = m.NfFilCod
       AND m2.NfDatEmis = m.NfDatEmis
       AND m2.NfNumero = m.NfNumero
   INNER JOIN PRODUTOS AS p2 WITH(nolock) 
     ON p2.ProCod = m2.ItemProCod
   INNER JOIN IntegraTICravil.Bi.HistoricoCMV as cmv with(nolock)
      ON cmv.NumeroControle = m2.NfNumero
      AND cmv.CodigoFilial = m2.NfFilCod
      AND cmv.DataEmissao = m2.NfDatEmis
      AND cmv.SequenciaItemNota = m2.ItemNumSeq      
   WHERE m.NfDatEmis BETWEEN @inicio AND @fim    
     AND m.NfeCStat NOT IN (101,102)
     AND m.NfSituacao NOT IN (1,4)  
     AND m.NfOpeEstCod in (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204, 5, 236)   
  AND p2.ProSituacao NOT IN ('n')
  AND p2.ProFamCod BETWEEN 10 AND 30 

   --and p2.procod = 1469 
   --and m.nffilcod = 25 
   GROUP BY m2.ItemRedIcms,
			p2.procod,
			m.NfNumero,
			m.NfDatEmis,
			p2.pronom ,
			m.NfFilCod,
			p2.ProVlrMargen,
			p2.ProFlag35,
			cmv.CustoMercadoriaVendida,
			m2.ItemQtdade   
) AS v
group by v.Codigo,
		v.Nome,          
		v.Desativacao,		
		v.Filial
		