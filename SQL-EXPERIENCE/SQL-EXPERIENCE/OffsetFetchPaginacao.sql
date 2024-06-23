USE GesCooper90
GO

declare @dataInicio datetime,
		@dataFim datetime
SET @dataInicio = '20170301'
SET @dataFim    = '20171231' 
			;with cte 
			as(
	            select 									
					 m.NfNumDoc														    as [NF-e]
					, m.NfDatEmis														as [Data Emissão]
				
					, case 
						when m.NfeChNfe = '' then ''
					  else isnull(m.NfeChNfe,'')			
					  END																as [Chave]
													
					, m.NfOpeEstCod														as [Operação]
					, op.OpeEstNom														as [Nome Operação]
					, ROW_NUMBER() over (partition by m.nfnumdoc order by m.nfnumdoc) as rn
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
				  and m.nfecstat not in (101, 102)
				  and m.NfSituacao not in (1, 4) 
				  and i.NfDatEmis between @dataInicio and @dataFim 				 	
			  	  and i.ItemProCod in (42312, 39580, 39621, 42311)
				)
				select 
				convert(varchar(30),t2.[Data Emissão], 103) as [Data]				
				, t2.[NF-e]
				, t2.Operação
				, t2.[Nome Operação]
				,  ROW_NUMBER() over (order by t2.[Data Emissão]) as Contagem
				, '' [Status]
				from cte as t2
				where t2.rn < 2	
				order by t2.[Data Emissão]
				offset 300 rows
				fetch next 100 rows only
			