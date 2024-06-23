use GesCooper90
go

DECLARE @datainicio DATETIME = '2015-09-15' 
DECLARE @datafinal DATETIME = '2015-09-15' 


SELECT	 m.nffilcod                                              AS Filial, 
         f.filnomreduzido                                        AS NomeFilial, 
         m.nfsetcod                                              AS Setor, 
         setor.setnom                                            AS NomeSetor, 
         m.nfseccod                                              AS Secao, 
         sec.secnom                                              AS NomeSecao, 
         m.nfcencusdestino                                       AS CentroCusto, 
         ce.cennom                                               AS NomeCentro, 
         m.nfnumero                                              AS NumControle, 
         m.nfnumdoc                                              AS NF, 
         m.nfopeestcod                                           AS Op, 
         m.nfventracod                                           AS VendRepre, 
         repre.tranom                                            AS NomeRepre, 
         m.nfforcod                                              AS ClienteFornecedor, 
         t.tranom                                                AS NomeCliente, 
         city.munnom                                             AS Cidade, 
         city.estcod                                             AS Estado, 
         mum.itemprocod                                          AS Item, 
         p.pronom                                                AS Nomeitem, 
         m.nfdatemis                                             AS Emissao, 
         p.profamcod                                             AS CodFamilia, 
         fa.famnom                                               AS NomeFamilia, 
         p.progrpcod                                             AS CodGrupo, 
         gr.grpnom                                               AS NomeGrupo, 
         p.prosubcod                                             AS CodSubgrupo, 
         sub.subnom                                              AS NomeSubgrupo, 
         p.provlrmargen                                          AS Margem, 
         ( ( p.provlrpliq * mum.itemqtdade ) / 1000 )            AS Peso,                          
         mum.itemqtdade                                          AS Qtdade, 
         mum.ItemVlrUnitario									 AS ValorUnitario,    
         ( mum.itemtotinf - mum.itemvlrdesc + mum.itemvlracres ) AS ValorTotal
		 		         
  FROM   transacionadores AS t WITH(nolock) 
         INNER JOIN movestoque AS m WITH (nolock) 
                 ON m.nfforcod = t.tracod 
         LEFT OUTER JOIN transacionadores AS repre WITH (nolock) 
                 ON repre.tracod = m.nfventracod 
         INNER JOIN movestoquelevel1 AS mum WITH (nolock) 
                 ON mum.nffilcod = m.nffilcod 
                    AND mum.nfdatemis = m.nfdatemis 
                    AND mum.nfnumero = m.nfnumero 
         INNER JOIN produtos AS p WITH(nolock) 
                 ON p.procod = mum.itemprocod 
         INNER JOIN familias AS fa WITH(nolock) 
                 ON p.profamcod = fa.famcod 
         INNER JOIN grupos gr WITH(nolock) 
                 ON p.progrpcod = gr.grpcod 
                    AND p.profamcod = gr.famcod 
         INNER JOIN subgrupos sub WITH(nolock) 
                 ON p.prosubcod = sub.subcod 
                    AND p.progrpcod = sub.grpcod 
                    AND p.profamcod = sub.famcod 
         LEFT JOIN municipios AS city WITH(nolock) 
                 ON city.muncod = t.tramuncod 
                    AND city.estcod = t.traestcod 
                    AND city.paicod = t.trapaicod 
         INNER JOIN filiais AS f WITH(nolock) 
                 ON m.nffilcod = f.filcod 
         LEFT JOIN centrocusto AS ce WITH(nolock) 
                 ON m.nfcencusdestino = ce.cencod 
         LEFT JOIN secao AS setor WITH(nolock) 
                 ON m.nfsetcod = setor.setcod 
         LEFT JOIN secaolevel1 AS sec WITH(nolock) 
                 ON m.nfseccod = sec.seccod 
					AND m.nfsetcod = sec.setcod 				
  WHERE  m.nfecstat NOT IN ( 101, 102 ) 
         AND m.nfsituacao IN ( 2, 3 ) 
         AND m.nfopeestcod = 3                       
	     AND m.NfDatEmis BETWEEN @datainicio AND @datafinal
	     AND m.NfFilcod = 1
