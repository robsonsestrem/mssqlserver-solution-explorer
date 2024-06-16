use GesCooper90
go

DECLARE @dataInicio datetime = '2014-05-02',
		@dataFinal datetime = '2014-05-02'

SELECT x.Filial, 
       x.Nome_Filial, 
       x.Setor, 
       x.Nome_Setor, 
       x.Secao, 
       x.Nome_Secao, 
       x.Centro_Custo, 
       x.Nome_Centro, 
       x.NumControle, 
       x.NF, 
       x.Op, 
       x.Emissao, 
       x.Vend_Repre, 
       x.Nome_Repre, 
       x.Cliente_Fornecedor, 
       x.Nome_Cliente, 
       x.Cidade, 
       x.Item, 
       x.Nome_Item, 
       x.Cod_Familia, 
       x.Nome_Familia, 
       x.Cod_Grupo, 
       x.Nome_Grupo, 
       x.Cod_Subgrupo, 
       x.Nome_Subgrupo, 
       x.Peso, 
       x.Desconto_Iten, 
       x.Valor_Bruto, 
       x.Qtdade, 
       cmv.CustoMedioUnitario, 
       cmv.CustoMedioUnitario * x.Qtdade AS CMV x Qtd 
FROM  (SELECT m.nffilcod                                            AS Filial, 
              fil.filnom                                            AS Nome_Filial, 
              m.nfsetcod                                            AS Setor, 
              setor.setnom                                          AS Nome_Setor, 
              m.nfseccod                                            AS Secao, 
              sec.secnom                                            AS Nome_Secao, 
              m.nfcencusdestino                                     AS Centro_Custo, 
              ce.cennom                                             AS Nome_Centro, 
              m.nfnumero                                            AS NumControle, 
              m.nfnumdoc                                            AS NF, 
              m.nfopeestcod                                         AS Op, 
              m.nfdatemis                                           AS Emissao, 
              m.nfventracod                                         AS Vend_Repre, 
              repre.tranom                                          AS Nome_Repre, 
              m.nfforcod                                            AS Cliente_Fornecedor, 
              t.tranom                                              AS Nome_Cliente, 
              city.munnom                                           AS Cidade, 
              mum.itemprocod                                        AS Item, 
              p.pronom                                              AS Nome_Item, 
              p.profamcod                                           AS Cod_Familia, 
              fa.famnom                                             AS Nome_Familia, 
              p.progrpcod                                           AS Cod_Grupo, 
              gr.grpnom                                             AS Nome_Grupo, 
              p.prosubcod                                           AS Cod_Subgrupo, 
              sub.subnom                                            AS Nome_Subgrupo, 
              mum.itempeso                                          AS Peso, 
              mum.itemvlrdesc                                       AS Desconto_Iten, 
             ( mum.itemtotinf - mum.itemvlrdesc ) * mum.itemqtdade  AS Valor_Bruto, 
              mum.itemqtdade                                        AS Qtdade 
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
              INNER JOIN grupos AS gr WITH(nolock)
                      ON p.progrpcod = gr.grpcod 
              INNER JOIN subgrupos AS sub WITH(nolock)
                      ON p.prosubcod = sub.subcod 
                         AND p.progrpcod = sub.grpcod
                         AND p.profamcod = sub.famcod
              INNER JOIN filiais AS fil WITH(nolock)
                      ON m.nffilcod = fil.filcod 
              LEFT JOIN centrocusto AS ce WITH(nolock)
                      ON m.nfcencusdestino = ce.cencod 
              LEFT JOIN secao AS setor WITH(nolock) 
                      ON m.nfsetcod = setor.setcod 
              LEFT JOIN secaolevel1 AS sec WITH(nolock)
                      ON m.nfseccod = sec.seccod 
						 AND m.nfsetcod = sec.setcod 
              INNER JOIN municipios AS city WITH(nolock)
                      ON city.muncod = t.tramuncod 
       WHERE  m.nfecstat NOT IN ( 101, 102 )						--desconsidera notas canceladas 
              AND m.nfopeestcod IN ( 84, 10 )						--operação de devolução 
              AND m.nfdatemis BETWEEN @dataInicio AND @dataFinal	--filtrar data necessária              
      ) x 
      CROSS apply GetCustoMercadoria(x.Filial, x.Item, x.Emissao) cmv 