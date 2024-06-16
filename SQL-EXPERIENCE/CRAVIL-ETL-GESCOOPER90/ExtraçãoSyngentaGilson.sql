USE GesCooper90
GO
DECLARE @dataInicio DATETIME,
		@dataFim DATETIME
SET @dataInicio = '2017-05-01'
SET @dataFim    = '2018-04-30'

SELECT 	   
	   pf.ProForCod								 as FORNECEDOR,
	   pf.ProCod								 as CÓDIGO PRODUTO, 
	   p.ProNom									 as NOME PRODUTO, 
	   p.ProFamCod								 as FAMÍLIA,
	   vendas.NfNumDoc							 as NF,
	   CONVERT(VARCHAR(20),vendas.NfDatEmis,105) as DATA EMISSÃO,
	   vendas.NfOpeEstCod						 as CÓDIGO OPERAÇÃO,	
	   UPPER(vendas.OpeEstNom)					 as NOME OPERAÇÃO,   	   
	   vendas.TraNom							 as CLIENTE,
	   vendas.NatJuridica						 as NATUREZA JURÍDICA,
	   vendas.Fone								 as FONE CLIENTE,	   	  	   
	   vendas.MunNom							 as MUNICÍPIO,	
	   vendas.Qtdade							 as QUANTIDADE, 
	   (vendas.Valor / vendas.Qtdade)			 as PREÇO UNITÁRIO (R$),
	   CAST(vendas.Valor AS MONEY)			     as VALOR TOTAL (R$)

FROM PRODUTOSLEVEL2 as pf with (NoLock) left join PRODUTOS as p with (NoLock) 
on p.ProCod = pf.ProCod 	

	CROSS APPLY (SELECT	
					m.NfFilCod,					
					m.NfOpeEstCod,
					m.NfNumDoc,
					m.NfDatEmis,
					op.OpeEstNom,					
					i.ItemProCod,
					t.TraNom,
					case when (t.TraCelular is null or t.TraCelular = '') 
						 then isnull(t.TraFone, '')
					else t.TraCelular
					end														as Fone,
					city.MunNom,
					case when t.TraNatJuridica = 1 then 'FÍSICA' 
					     when t.TraNatJuridica = 2 then 'JURÍDICA'
					else ''
					end														as NatJuridica,
					Sum(i.ItemQtdade)										as Qtdade, 
					Sum(i.ItemTotInf)										as Valor 
				 FROM MOVESTOQUELEVEL1 as i with (NoLock) Left Join MOVESTOQUE as m with (NoLock) 
						on m.NfFilCod = i.NfFilCod 
						and m.NfDatEmis = i.NfDatEmis 
						and m.NfNumero = i.NfNumero inner join TRANSACIONADORES as t with(nolock)
							on t.TraCod = m.NfForCod left join MUNICIPIOS as city WITH(nolock) 
								on city.muncod = t.tramuncod 
								and city.estcod = t.traestcod 
								and city.paicod = t.trapaicod inner join OPERACAO AS op
									ON op.OpeEstCod = m.NfOpeEstCod

				 WHERE m.NfOpeEstCod in (60, 18, 5, 10, 17, 1, 64, 78, 4) 
				  and m.NfSituacao not in (1, 4) 
				  and i.NfDatEmis BETWEEN @dataInicio AND @dataFim 
				  and i.ItemProCod = pf.ProCod 	
			  		  
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
						  t.TraNatJuridica
			   ) as vendas

WHERE p.ProFamCod IN (2,3)	
	  and pf.ProForCod = 33636



