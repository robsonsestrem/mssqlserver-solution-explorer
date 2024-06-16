use [gescooper90]
go

create or alter view [dbo].[vw_movimentacaoreceita] 
as 
  select m.nffilcod                                              as filial, 
         f.filnomreduzido                                        as nomefilial, 
         m.nfsetcod                                              as setor, 
         setor.setnom                                            as nomesetor, 
         m.nfseccod                                              as secao, 
         sec.secnom                                              as nomesecao, 
         m.nfcencusdestino                                       as centrocusto, 
         ce.cennom                                               as nomecentro, 
         m.nfnumero                                              as numcontrole, 
         m.nfnumdoc                                              as nf, 
         m.nfopeestcod                                           as op, 
		 m.nfsituacao											 as situacao,			-- adicionado 26-04-2017
         m.nfventracod                                           as vendrepre, 
         repre.tranom                                            as nomerepre, 
         m.nfforcod                                              as clientefornecedor, 
         t.tranom                                                as nomecliente, 
         city.munnom                                             as cidade, 
         city.estcod                                             as estado, 
         m2.itemprocod                                           as item, 
         p.pronom                                                as nomeitem,
		 m2.itemnumseq											 as sequenciaitem,		-- adicionado 28-02-2017 
         m.nfdatemis                                             as emissao, 
         p.profamcod                                             as codfamilia, 
         fa.famnom                                               as nomefamilia, 
         p.progrpcod                                             as codgrupo, 
         gr.grpnom                                               as nomegrupo, 
         p.prosubcod                                             as codsubgrupo, 
         sub.subnom                                              as nomesubgrupo,
		 p.pronomembestoque										 as embalagem, 
         p.provlrmargen                                          as margem, 
         ( ( p.provlrpliq * m2.itemqtdade ) / 1000 )             as peso, 
         m2.itemqtdade                                           as qtdade, 
		 --
         cast(( m2.itemtotinf - 
		 m2.itemvlrdesc + m2.itemvlracres ) as decimal(15,2))    as valorbruto,
		 cast(m2.itemvlrunitario as decimal(9,2))				 as valorunitario,
		 --sum(m2.itemtotinf)									 as valortotalitem,
		 -- 
         m2.itemvlrdesc                                          as desconto, 
         m2.itemvlrpis                                           as pis, 
         m2.itemvlrcofins                                        as cofins, 
		 --
         cast(((m2.itempericms / 100) * 
		 (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) 
		 ) * ( (100 - m2.itemredicms) / 100 ) as decimal(15,2))  as icms,
		 -- 
         m.nfvlrfrete                                            as frete, 
         m.nftranvlr                                             as fretealternativo, 
         m.nfvenpercom                                           as comissao, 
         0                                                       as devolucao,
		 case when m.nftrantipofrete = 0 then 'nenhum'			
			  when m.nftrantipofrete = 1 then 'emitente'		 -- campos abaixo adicionados em 27-06-2017
			  when m.nftrantipofrete = 2 then 'destinatário'
		 else '' end	   										 as tipofrete,
		 --
		case when (( (m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 )) = 0 then 0
			 else round((( (m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 ) / (m2.itemtotinf)) * 100,0, 1)
		end														 as aliquota,		-- adicionado 28-07-2017
		--
		 cast((	(( m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres ) - ((m2.itempericms / 100) * (m2.itemtotinf - m2.itemvlrdesc + m2.itemvlracres) ) * ( (100 - m2.itemredicms) / 100 )) -
		 m2.itemvlrpis - m2.itemvlrcofins) as decimal(15,2))	 as valorliquido,	-- adicionado 28-07-2017
		 m.nfnumcarga											 as numerocarga,
		 m.nfpedcod												 as numeropedido,
		 m.nfpeddatemi											 as datapedido,
		 m.nfpedfilcod											 as filialpedido		 
  from   TRANSACIONADORES as t with(nolock) 
         inner join MOVESTOQUE as m with (nolock) 
                 on m.nfforcod = t.tracod 
         left outer join TRANSACIONADORES as repre with (nolock) 
                 on repre.tracod = m.nfventracod 
         inner join MOVESTOQUELEVEL1 as m2 with (nolock) 
                 on m2.nffilcod = m.nffilcod 
                    and m2.nfdatemis = m.nfdatemis 
                    and m2.nfnumero = m.nfnumero 
         inner join PRODUTOS as p with(nolock) 
                 on p.procod = m2.itemprocod 
         inner join FAMILIAS as fa with(nolock) 
                 on p.profamcod = fa.famcod 
         inner join GRUPOS gr with(nolock) 
                 on p.progrpcod = gr.grpcod 
                    and p.profamcod = gr.famcod 
         inner join SUBGRUPOS sub with(nolock) 
                 on p.prosubcod = sub.subcod 
                    and p.progrpcod = sub.grpcod 
                    and p.profamcod = sub.famcod 
         left join MUNICIPIOS as city with(nolock) 
                 on city.muncod = t.tramuncod 
                    and city.estcod = t.traestcod 
                    and city.paicod = t.trapaicod 
         inner join FILIAIS as f with(nolock) 
                 on m.nffilcod = f.filcod 
         left join CENTROCUSTO as ce with(nolock) 
                 on m.nfcencusdestino = ce.cencod 
         left join SECAO as setor with(nolock) 
                 on m.nfsetcod = setor.setcod 
         left join SECAOLEVEL1 as sec with(nolock) 
                 on m.nfseccod = sec.seccod 
					and m.nfsetcod = sec.setcod 
		 inner join OPERACAO as op
				 on op.opeestcod = m.nfopeestcod				
  where  m.nfecstat not in (101, 102) 
         and m.nfsituacao not in (1, 4) 
         --and m.nfopeestcod in (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204, 5, 236, 275)
		 and op.opeestmovcod = 5	-- adicionado 22-11-2018

go



