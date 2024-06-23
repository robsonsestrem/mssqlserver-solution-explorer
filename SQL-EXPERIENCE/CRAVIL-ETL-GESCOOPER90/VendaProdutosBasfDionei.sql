USE GesCooper90
GO

declare @dataInicio datetime,
		@dataFim datetime
SET @dataInicio = '20170301'
SET @dataFim    = '20171231'

declare @Upper int
declare @Lower int
SET @Lower = 200  -- The lowest random number
SET @Upper = 1300 -- The highest random number
 
	            select	
					t.TraNom															as [Nome Cliente Final]
					--
					, case when t.TraNatJuridica = 1 then t.TraCpf
					     when t.TraNatJuridica = 2 then t.TraCnpj
						 else ''
					  end																as [Documento]	
					--	
					, city.EstCod														as [UF]
					, city.MunNom														as [Município]
					, m.NfNumDoc														as [NF-e]
					, m.NfDatEmis														as [Data Emissão]
					--
					, case 
						when m.NfeChNfe = '' then ''
					  else isnull(m.NfeChNfe,'')			
					  END																as [Chave]
					--
					, p.ProNom															as [Variedade]	
					, p.ProNomEmbEstoque												as [Embalagem]					
					-- left(replace(checksum(newid()),'-',''),3)
					,  case when i.ItemNumLote is null or i.ItemNumLote = '' 
								 then Cast((@Upper - @Lower -1) * 
								 rand(cast( NEWID() AS varbinary )) + @Lower as Int)
					        else i.ItemNumLote
					   end																as [Lote NF-e]
					--				
					, case when p.ProNomEmbEstoque = 'KG' 
								then i.ItemQtdade
						   when p.ProNomEmbEstoque = 'SC' 
								then (p.ProVlrPLiq * i.ItemQtdade) / 1000
						   else ''
					  end																as [Peso Kg]
					--																																																															
					, i.ItemQtdade													    as [Quantidade]
					, cast(i.ItemVlrUnitario as decimal(9,2))							as [Valor Unitário]
					, Sum(i.ItemTotInf)													as [Valor Total Item]
					--
					, cast(case when p.ProNomEmbEstoque = 'KG' 
								then (i.ItemQtdade * 0.25)
						   when p.ProNomEmbEstoque = 'SC' 
								then (0.25 * ((p.ProVlrPLiq * i.ItemQtdade) / 1000))
						   else ''
					  end as decimal (9,2))												as [Royalties]
					--
					, m.NfOpeEstCod														as [Operação]
					, op.OpeEstNom														as [Nome Operação]
					
				 FROM MOVESTOQUE as m with (NoLock) inner Join  MOVESTOQUELEVEL1 as i with (NoLock) 				 
						on m.NfFilCod = i.NfFilCod 
						and m.NfDatEmis = i.NfDatEmis 
						and m.NfNumero = i.NfNumero inner join TRANSACIONADORES as t with(nolock)
							on t.TraCod = m.NfForCod left join MUNICIPIOS as city WITH(nolock) 
								on city.muncod = t.tramuncod 
								and city.estcod = t.traestcod 
								and city.paicod = t.trapaicod inner join OPERACAO as op
									on op.OpeEstCod = m.NfOpeEstCod inner join  PRODUTOS as p
										on p.ProCod = i.ItemProCod
				 WHERE m.NfOpeEstCod in (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204, 5, 236)
				 -- (60, 18, 5, 10, 17, 1, 64, 78, 4)
				  and m.nfecstat not in (101, 102)
				  and m.NfSituacao not in (1, 4) 
				  and i.NfDatEmis between @dataInicio and @dataFim 				 	
			  	  and i.ItemProCod in (42312, 39580, 39621, 42311)
				 GROUP BY m.NfOpeEstCod,
						  m.NfNumDoc,
						  m.NfDatEmis,
						  i.ItemProCod,
						  t.TraNom,
						  city.MunNom,
						  m.NfFilCod,
						  op.OpeEstNom,
						  t.TraCelular,
						  t.TraFone,
						  t.TraNatJuridica,
						  m.NfeChNfe,
						  city.EstCod,
						  t.TraCpf,
						  t.TraCnpj,
						  p.ProNom,
						  p.ProNomEmbEstoque,						  
						  i.ItemNumLote, 						
						  i.ItemVlrUnitario,
						  p.ProVlrPLiq,
						  i.ItemQtdade
			