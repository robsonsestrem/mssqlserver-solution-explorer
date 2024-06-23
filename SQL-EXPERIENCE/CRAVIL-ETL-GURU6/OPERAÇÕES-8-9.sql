USE GesCooper90
GO
declare @inicio datetime
	    , @fim datetime	

set @inicio = '20170901'
set @fim	= '20170930'

SELECT   m.nffilcod												 AS Filial, 
         isnull(f.filnomreduzido, '')                            AS NomeFilial, 
         m.nfsetcod                                              AS Setor, 
         isnull(setor.setnom, '')                                AS NomeSetor, 
         m.nfseccod                                              AS Secao, 
         isnull(sec.secnom, '')                                  AS NomeSecao, 
         m.nfcencusdestino                                       AS CentroCusto, 
         isnull(ce.cennom, '')                                   AS NomeCentro, 
         m.nfnumero                                              AS NumControle, 
         m.nfnumdoc                                              AS NF, 
         m.nfopeestcod                                           AS Op, 
		 m.NfSituacao											 AS Situacao,		
         m.nfforcod                                              AS ClienteFornecedor,
         isnull(t.tranom, '')                                    AS NomeCliente,
         isnull(city.munnom, '')                                 AS Cidade,
         city.estcod                                             AS Estado,
         m2.itemprocod                                           AS Item,
         isnull(p.pronom, '')                                    AS Nomeitem,
		 m2.ItemNumSeq											 AS SequenciaItem,
         m.nfdatemis                                             AS Emissao, 
         p.profamcod                                             AS CodFamilia, 
         isnull(fa.famnom, '')                                   AS NomeFamilia, 
         p.progrpcod                                             AS CodGrupo, 
         isnull(gr.grpnom, '')                                   AS NomeGrupo, 
         p.prosubcod                                             AS CodSubgrupo, 
         isnull(sub.subnom, '')                                  AS NomeSubgrupo, 
         p.provlrmargen                                          AS Margem, 
         ( ( p.provlrpliq * m2.itemqtdade ) / 1000 )             AS Peso, 
         m2.itemqtdade                                           AS Qtdade,
		 --
		 case when (( (m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 )) = 0 then 0
			 else round((( (m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 ) / (m2.itemtotinf)) * 100,0, 1)
		 end													 AS Aliquota,				 
		 --
		 cast(((m2.itempericms / 100) * 
		 (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) 
		 ) * ( (100 - m2.itemredicms) / 100 ) as decimal(15,2))  AS ICMS, 
		 --
         cast(( m2.itemtotinf - 
		 m2.itemvlrdesc + m2.itemvlracres ) as decimal(15,2))    AS ValorBruto,
		 --		          		                        		 
		 cast((	(( m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres ) - ((m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 )) -
		 m2.itemvlrpis - m2.itemvlrcofins) as decimal(15,2))	 AS ValorLiquido	
		 		 		 		 		 
  FROM   TRANSACIONADORES AS t WITH(nolock) 
         INNER JOIN MOVESTOQUE AS m WITH (nolock) 
                 ON m.nfforcod = t.tracod 
         LEFT OUTER JOIN TRANSACIONADORES AS repre WITH (nolock) 
                 ON repre.tracod = m.nfventracod 
         INNER JOIN MOVESTOQUELEVEL1 AS m2 WITH (nolock) 
                 ON m2.nffilcod = m.nffilcod 
                    AND m2.nfdatemis = m.nfdatemis 
                    AND m2.nfnumero = m.nfnumero 
         INNER JOIN PRODUTOS AS p WITH(nolock) 
                 ON p.procod = m2.itemprocod 
         INNER JOIN FAMILIAS AS fa WITH(nolock) 
                 ON p.profamcod = fa.famcod 
         INNER JOIN GRUPOS gr WITH(nolock) 
                 ON p.progrpcod = gr.grpcod 
                    AND p.profamcod = gr.famcod 
         INNER JOIN SUBGRUPOS sub WITH(nolock) 
                 ON p.prosubcod = sub.subcod 
                    AND p.progrpcod = sub.grpcod 
                    AND p.profamcod = sub.famcod 
         LEFT JOIN MUNICIPIOS AS city WITH(nolock) 
                 ON city.muncod = t.tramuncod 
                    AND city.estcod = t.traestcod 
                    AND city.paicod = t.trapaicod 
         INNER JOIN FILIAIS AS f WITH(nolock) 
                 ON m.nffilcod = f.filcod 
         LEFT JOIN CENTROCUSTO AS ce WITH(nolock) 
                 ON m.nfcencusdestino = ce.cencod 
         LEFT JOIN SECAO AS setor WITH(nolock) 
                 ON m.nfsetcod = setor.setcod 
         LEFT JOIN SECAOLEVEL1 AS sec WITH(nolock) 
                 ON m.nfseccod = sec.seccod 
					AND m.NfSetCod = sec.SetCod 				
  WHERE  m.NfeCStat NOT IN (101, 102) 
         AND m.NfSituacao NOT IN (1, 4) 
         AND m.NfOpeEstCod in (38, 8, 9)
		 and m.NfDatEmis between @inicio and @fim

