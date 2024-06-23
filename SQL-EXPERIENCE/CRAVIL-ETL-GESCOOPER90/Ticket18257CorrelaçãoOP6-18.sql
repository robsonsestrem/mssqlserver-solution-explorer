use GesCooper90
go

declare @dataini datetime = '2018-08-10'
       ,@datafim datetime = '2018-08-31'


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
			 , t3.pronom																						as Nomeitem
			 , t2.ItemNumSeq																					as SequenciaItem	
			 , convert(varchar(30), t1.nfdatemis, 103)															as Emissao 
			 , cast(( t2.itemtotinf - 
			 t2.itemvlrdesc + t2.itemvlracres ) as decimal(15,2))												as [ValorBruto Unitário] 
			 --, sum(cast(( t2.itemtotinf - t2.itemvlrdesc + t2.itemvlracres ) as decimal(15,2))) 
			 --over (partition by t1.nfnumero, t1.nfnumdoc, t1.nfopeestcod)										as [SomaPorDoc]		  
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
	  where t1.nfecstat NOT IN (101, 102) 
			 AND t1.nfsituacao NOT IN (1, 4) 
			 AND t1.NfOpeEstCod in (6, 18)
			 and t1.NfDatEmis between @dataini and @datafim
			 and t1.NfNumDoc in (40788, 41923)

