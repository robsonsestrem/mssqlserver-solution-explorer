USE [GesCooper90]
GO

create or alter VIEW [dbo].[vw_MovimentacaoTransferencia] 
AS 
  SELECT m.nffilcod                                              AS Filial, 
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
		 m.NfSituacao											 AS Situacao,			-- adicionado 26-04-2017
         m.nfventracod                                           AS VendRepre, 
         repre.tranom                                            AS NomeRepre, 
         m.nfforcod                                              AS ClienteFornecedor, 
         t.tranom                                                AS NomeCliente, 
         city.munnom                                             AS Cidade, 
         city.estcod                                             AS Estado, 
         m2.itemprocod                                           AS Item, 
         p.pronom                                                AS Nomeitem,
		 m2.ItemNumSeq											 AS SequenciaItem,		-- adicionado 28-02-2017 
         m.nfdatemis                                             AS Emissao, 
         p.profamcod                                             AS CodFamilia, 
         fa.famnom                                               AS NomeFamilia, 
         p.progrpcod                                             AS CodGrupo, 
         gr.grpnom                                               AS NomeGrupo, 
         p.prosubcod                                             AS CodSubgrupo, 
         sub.subnom                                              AS NomeSubgrupo, 
         p.provlrmargen                                          AS Margem, 
         ( ( p.provlrpliq * m2.itemqtdade ) / 1000 )             AS Peso, 
         m2.itemqtdade                                           AS Qtdade, 
		 --
         cast(( m2.itemtotinf - 
		 m2.itemvlrdesc + m2.itemvlracres ) as decimal(15,2))    AS ValorBruto,
		 -- 
         m2.itemvlrdesc                                          AS Desconto, 
         m2.itemvlrpis                                           AS PIS, 
         m2.itemvlrcofins                                        AS COFINS, 
		 --
         cast(((m2.itempericms / 100) * 
		 (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) 
		 ) * ( (100 - m2.itemredicms) / 100 ) as decimal(15,2))  AS ICMS,
		 -- 
         m.nfvlrfrete                                            AS Frete, 
         m.nftranvlr                                             AS FreteAlternativo, 
         m.nfvenpercom                                           AS Comissao, 
         0                                                       AS Devolucao,
		 CASE when m.NfTranTipoFrete = 0 then 'NENHUM'			
			  when m.NfTranTipoFrete = 1 then 'EMITENTE'		 -- campos abaixo adicionados em 27-06-2017
			  when m.NfTranTipoFrete = 2 then 'DESTINATÁRIO'
		 else '' END	   										 AS TipoFrete,
		 --
		case when (( (m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 )) = 0 then 0
			 else round((( (m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 ) / (m2.itemtotinf)) * 100,0, 1)
		end														 AS Aliquota,		-- adicionado 28-07-2017
		--
		 cast((	(( m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres ) - ((m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 )) -
		 m2.itemvlrpis - m2.itemvlrcofins) as decimal(15,2))	 AS ValorLiquido,	-- adicionado 28-07-2017
		 m.NFNumCarga											 AS NumeroCarga,
		 m.NfPedCod												 AS NumeroPedido,
		 m.NfPedDatEmi											 AS DataPedido,
		 m.NfPedFilCod											 AS FilialPedido		 
  FROM   transacionadores AS t WITH(nolock) 
         INNER JOIN movestoque AS m WITH (nolock) 
                 ON m.nfforcod = t.tracod 
         LEFT OUTER JOIN transacionadores AS repre WITH (nolock) 
                 ON repre.tracod = m.nfventracod 
         INNER JOIN movestoquelevel1 AS m2 WITH (nolock) 
                 ON m2.nffilcod = m.nffilcod 
                    AND m2.nfdatemis = m.nfdatemis 
                    AND m2.nfnumero = m.nfnumero 
         INNER JOIN produtos AS p WITH(nolock) 
                 ON p.procod = m2.itemprocod 
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
  WHERE  m.nfecstat NOT IN (101, 102) 
         AND m.nfsituacao NOT IN (1, 4) 
         AND m.NfOpeEstCod in (3, 46)

GO


