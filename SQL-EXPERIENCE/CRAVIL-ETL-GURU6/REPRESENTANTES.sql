use GesCooper90
go
declare @inicio datetime = '20170920'
	  , @fim datetime	 = '20170920'

		SELECT     
		   t1.NfFilCod														as Filial 		   
		   , t9.FilNomReduzido												as NomeFilial   
		   , convert(varchar(20), t1.NfDatEmis, 103)						as DataEmissao
		   , t2.NfNumDoc													as NFe
           , t1.NfNumero													as NumeroControle 
		   , t2.NfOpeEstCod													as OP 
		   --
		   , case t2.NfSituacao
							when 1 then 'Digitada'
							when 2 then 'Atualizado'
							when 3 then 'NFListada'
							when 4 then 'Cancelado'
							when 5 then 'O.C.Listada'
							when 6 then 'Ordem Atendida'
							when 7 then 'Ordem Atualizada'
							when 8 then 'NF-e à Cancelar'
							when 9 then 'Ag. Conferência'
							when 10 then 'Aguardando Armazenagem'
							when 11 then 'Aguardando Autorização'
							when 12 then 'Aguardando Liberação'
							when 13 then 'Aguardando Processamento'
			 else 'Indefinida'
		     end															as Situacao
		   --
		   , t4.OpeEstMovCod												as TipoMovimento
		   , t1.ItemVlrDesc													as Desconto 
		   , t2.NfVenPerCom													as [Comissao_%]
           , t2.NfVenTraCod													as Representante
		   , t3.TraNom														as NomeRepresentante
		   -- 
		   , case t3.TraNatSocial
				when 1 then 'Associado'
				when 3 then 'Não Associado'
		     end															as NaturezaSocial
		   --
		   , case t3.TraNatComercial
				when 1 then 'Produtor Rural'  
				when 2 then 'Funcionário'  
				when 3 then 'Cliente'     
				when 4 then 'Fornecedor'    
				when 5 then 'Transportador'     
				when 6 then 'Motorista'          
				when 7 then 'Vendedor'         
				when 8 then 'Banco'    
				when 9 then 'Conveniado'
		     end															as NaturezaComercial
		   --
		   , case t3.TraNatFiscal
				when 1 then 'Trabalhador urbano'
				when 2 then 'Trabalhador rural'
				when 3 then 'Empresa rural'
				when 4 then 'Empresa rural não contribuinte'
				when 5 then 'Empresa rural contribuinte'
				when 6 then 'Empresa urbana contribuinte'
				when 7 then 'Entidade filantrópica'
				when 8 then 'Associação'    
				when 9 then 'Orgão Público'
				when 10 then 'Cooperativa'
				when 11 then 'Empresa urbana não contribuinte'  
		     end															as NaturezaFiscal
		   --
		   , t3.TraEstCod													as UF 		             		   
		   , t1.ItemNumSeq													as SequenciaItem
		   --
		   , case when t2.NfTranTipoFrete = 0 then 'Nenhum'			
				when t2.NfTranTipoFrete = 1 then 'Emitente'		 
				when t2.NfTranTipoFrete = 2 then 'Destinatário'
		     else '' 
		     end	   														as TipoFrete
		   --                       
           , t1.ItemProCod													as CodigoProduto
           , t5.ProNom														as NomeProduto
		   , t5.ProFamCod													as CodigoFamilia
		   , t6.FamNom														as NomeFamilia 		   
		   , t5.ProGrpCod													as CodigoGrupo
		   , t7.GrpNom														as NomeGrupo
           , t5.ProSubCod													as CodigoSubgrupo 
		   , t8.SubNom														as NomeSubgrupo
           , t5.ProNomEmbEstoque											as Embalagem
           , t1.ItemQtdade													as Qtdade 		   
           , ( ( t5.ProVlrPLiq * t1.ItemQtdade ) / 1000 )					as Peso
           , t1.ItemVlrUnitario												as ValorUnitario 		
		   --                                                                                
           , cast(( (( t1.ItemTotInf - t1.ItemVlrDesc + t1.ItemVlrAcres ) 
				- ((t1.ItemPerIcms / 100) * 
				(t1.ItemTotInf - t1.ItemVlrDesc + t1.ItemVlrAcres) ) 
				* ( (100 - t1.ItemRedIcms) / 100 )) -
				t1.ItemVlrPis - t1.ItemVlrCofins) as decimal(15,2))			as ValorLiquido
		   --
		   , cast(( t1.ItemTotInf - 
				t1.ItemVlrDesc + t1.ItemVlrAcres ) as decimal(15,2))		as ValorBruto
		   --   
		   , t10.CodigoPag													as CodigoPagamento
		   , t10.TipoPagamento												as TipoPagamento
		   , DATEDIFF(day, t1.NfDatEmis, t10.Vencimento)					as PrazoDias		   
		   , convert(varchar(20), t10.Vencimento, 103)						as Vencimento
		  
		   --, t10.Valor														as ValorParcela  
		                                                  
FROM MOVESTOQUELEVEL1 t1 WITH (nolock) 
INNER JOIN MOVESTOQUE t2 WITH (nolock) 
	on t2.NfFilCod = t1.[NfFilCod] 
	AND t2.NfDatEmis = t1.NfDatEmis 
	AND t2.NfNumero = t1.NfNumero
LEFT JOIN  TRANSACIONADORES t3 WITH (nolock) 
	on t3.TraCod = t2.NfVenTraCod
INNER JOIN OPERACAO t4 WITH (nolock) 
	on t4.OpeEstCod = t2.NfOpeEstCod
LEFT JOIN  PRODUTOS t5 WITH (nolock) 
	on t5.ProCod = t1.ItemProCod
INNER JOIN FAMILIAS AS t6 WITH(nolock) 
    on t5.ProFamCod = t6.FamCod 
INNER JOIN GRUPOS as t7 WITH(nolock) 
    on t5.ProGrpCod = t7.GrpCod 
    AND t5.ProFamCod = t7.FamCod 
INNER JOIN SUBGRUPOS as t8 WITH(nolock) 
    on t5.ProSubCod = t8.SubCod
    AND t5.ProGrpCod = t8.GrpCod
    AND t5.ProFamCod = t8.FamCod
INNER JOIN FILIAIS as t9
	on t9.FilCod = t2.NfFilCod
INNER JOIN IntegraTICravil.Bi.fn_MovimentoFinanceiro(@inicio, @fim) as t10
	on t10.FilialCodigo = t1.NfFilCod
	and t10.Emissao = t1.NfDatEmis
	and t10.NumeroControle = t1.NfNumero
	and t10.SequenciaItem = t1.ItemNumSeq

WHERE t4.OpeEstMovCod = 5					-- operações de venda        
AND T1.NfDatEmis between @inicio AND @fim           
AND t2.NfSituacao not in (1, 4)
AND t5.ProFamCod in (80, 81)          
AND t2.NfVenTraCod > 0						-- representante existente na nota


--análise
and t2.NfFilCod = 1
and t2.NfNumDoc = 421481


ORDER BY t2.NfFilCod



--select * from IntegraTICravil.Bi.fn_MovimentoFinanceiro('20170920', '20170920') as t1
--where t1.


