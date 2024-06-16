use GesCooper90
go
-- cálculo aqui concorda que foi realizado desfazimento total do item,
-- sem informar quantidade errada, como exemplo de itens que aparecem mais
-- de uma vez numa NF mas é só feito um lançamento no desfazimento
-- teste -> soma dos totais do iten é que da 2900
-- item = 35170
-- controle desfazimento = 563813


declare @dataini datetime = '2016-01-01'
       ,@datafim datetime = '2018-08-31'

select 
--  deriva.Filial
--, deriva.NomeFilial
--, deriva.Setor
--, deriva.NomeSetor
--, deriva.Secao
--, deriva.NomeSecao
--, deriva.CentroCusto
--, deriva.NomeCentro
--, deriva.NumControle
--, deriva.NF
--, deriva.Op
--, deriva.[NF Principal]
--, deriva.Situacao
--, deriva.Item
--, deriva.NomeItem
--, deriva.SequenciaItem
--, deriva.Emissao
--, deriva.Qtdade
--, deriva.VlrUnitario
--, deriva.TotalVlrBruto
sum (case when deriva.SitDesfaz = 2 and deriva.NrCtrlDesfaz <> 0 
       then 0.00
   else deriva.SaldoVlrBruto_Itens
  end) as SaldoVlrTotal
--, deriva.ItemDesfaz							
--, deriva.VlrUnitDesfaz							
--, deriva.QtdadeDesfaz							
--, deriva.DataDesfaz								
--, deriva.NrCtrlDesfaz								
--, deriva.SitDesfaz

from(
		select t1.nffilcod																						as Filial 
			 , t7.filnomreduzido																				as NomeFilial
			 , t1.nfsetcod																						as Setor 
			 , t9.setnom																						as NomeSetor 
			 , t1.nfseccod																						as Secao 
			 , t10.secnom																						as NomeSecao
			 , t1.nfcencusdestino																				as CentroCusto
			 , t8.cennom																						as NomeCentro
			 , t1.nfnumero																						as NumControle 
			 , t1.nfnumdoc																						as NF 
			 , t1.nfopeestcod																					as Op 
			 , isnull(t1.NfPrincipal, 0)																		as [NF Principal]
			 , t1.NfSituacao																					as Situacao			
			 , t2.itemprocod																					as Item
			 , t3.pronom																						as NomeItem
			 , t2.ItemNumSeq																					as SequenciaItem	
			 , convert(varchar(30), t1.nfdatemis, 103)															as Emissao 
			 , t2.ItemQtdade																					as Qtdade
			 , cast(t2.ItemVlrUnitario as decimal(15,2))                                                        as VlrUnitario
			 , cast((t2.itemtotinf - t2.itemvlrdesc + t2.itemvlracres ) as decimal(15,2))		     			as [TotalVlrBruto] 			
		     			 	  			
			 --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			 ,
			  (isnull((select 
			  (cast(( y.itemtotinf - y.itemvlrdesc + y.itemvlracres ) as decimal(15,2))) as VlrBruto_OP18 from
				 MOVESTOQUE AS x WITH (nolock)                      
				 INNER JOIN MOVESTOQUELEVEL1 AS y WITH (nolock) 
						 ON y.nffilcod = x.nffilcod 
							AND y.nfdatemis = x.nfdatemis 
							AND y.nfnumero = x.nfnumero 
				  where x.NfNumDoc = t1.NfNumDoc
				  and x.NfNumero = t1.NfNumero
				  and x.NfFilCod = t1.NfFilCod
				  and y.ItemNumSeq = t2.ItemNumSeq
				  and x.NfOpeEstCod = 18
				), 0.00) --as OP18
			    -
				isnull((select 
				(cast(( w.itemtotinf - w.itemvlrdesc + w.itemvlracres ) as decimal(15,2))) as VlrBruto_OP06 from
				 MOVESTOQUE AS z WITH (nolock)                      
				 INNER JOIN MOVESTOQUELEVEL1 AS w WITH (nolock) 
						 ON w.nffilcod = z.nffilcod 
							AND w.nfdatemis = z.nfdatemis 
							AND w.nfnumero = z.nfnumero 
				  where z.NfNumDoc = t1.NfNumDoc
				  and z.NfNumero = t1.NfNumero
				  and z.NfFilCod = t1.NfFilCod
				  and w.ItemNumSeq = t2.ItemNumSeq
				  and z.NfOpeEstCod = 6		
				 ), 0.00) --as OP06	
				 )																								  as SaldoVlrBruto_Itens
			  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			  , coalesce(t12.TerDesProCod, 0)																	  as ItemDesfaz
			  , coalesce(t12.TerDesQtd, 0)									                                      as QtdadeDesfaz
			  , cast(coalesce(t12.TerDesVlrUnit, 0) as decimal(15,2))		                                      as VlrUnitDesfaz
			  , coalesce(convert(varchar(20), t12.TerDesData, 103), '')										      as DataDesfaz
			  , coalesce(t12.TerDesNumControle, 0)																  as NrCtrlDesfaz
			  , coalesce(t11.TerDesSituacao, 0)															          as SitDesfaz	  			 		  
						  	   		   		 
	  from   MOVESTOQUE AS t1 WITH (nolock)                      
			 INNER JOIN MOVESTOQUELEVEL1 AS t2 WITH (nolock) 
					 ON t2.nffilcod = t1.nffilcod 
						AND t2.nfdatemis = t1.nfdatemis 
						AND t2.nfnumero = t1.nfnumero 
			 INNER JOIN PRODUTOS AS t3 WITH(nolock) 
					 ON t3.procod = t2.itemprocod 
			 INNER JOIN FAMILIAS AS t4 WITH(nolock) 
					 ON t3.profamcod = t4.famcod 
			 INNER JOIN GRUPOS t5 WITH(nolock) 
					 ON t3.progrpcod = t5.grpcod 
						AND t3.profamcod = t5.famcod 
			 INNER JOIN SUBGRUPOS t6 WITH(nolock) 
					 ON t3.prosubcod = t6.subcod 
						AND t3.progrpcod = t6.grpcod 
						AND t3.profamcod = t6.famcod 
			 INNER JOIN FILIAIS AS t7 WITH(nolock) 
					 ON t1.nffilcod = t7.filcod 
			 LEFT JOIN CENTROCUSTO AS t8 WITH(nolock) 
					 ON t1.nfcencusdestino = t8.cencod 
			 LEFT JOIN SECAO AS t9 WITH(nolock) 
					 ON t1.nfsetcod = t9.setcod 
			 LEFT JOIN SECAOLEVEL1 AS t10 WITH(nolock) 
					 ON t1.nfseccod = t10.seccod 
						AND t1.nfsetcod = t10.setcod 	
			 left join TERDESFAZIMENTO as t11				
			         on t11.TerDesFilCod = t2.NfFilCod
					 and t11.TerDesNfDatEmis = t2.NfDatEmis
					 and t11.TerDesNfNumDoc = t1.NfNumDoc
					 and t11.TerDesNfNumero = t2.NfNumero					 
			 left join TERDESFAZIMENTOLEVEL1 as t12
			         on t11.TerDesFilCod = t12.TerDesFilCod
					 and t11.TerDesNumControle = t12.TerDesNumControle
					 and t11.TerDesData = t12.TerDesData
					 and t2.ItemProCod = t12.TerDesProCod	-- com isso traz somente o produto que tem relação
					 		 	
	  where t1.nfecstat NOT IN (101, 102) 
			 and t1.nfsituacao NOT IN (1, 4) 
			 and t1.NfOpeEstCod in (6, 18)
			 and t1.NfDatEmis between @dataini and @datafim
			 --and t1.NfNumDoc in (40788, 41923)
			 --and t12.TerDesNumControle = 563813
 ) as deriva


			 

