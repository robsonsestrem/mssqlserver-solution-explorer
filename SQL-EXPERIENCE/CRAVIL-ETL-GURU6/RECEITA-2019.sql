use GesCooper90
go

DECLARE @datainicio datetime = '20190416' 
DECLARE @datafinal datetime = '20190416'

SELECT
	x.cd_Filial 
	, x.ds_Filial
	, x.cd_Setor
	, x.ds_Setor
	, x.cd_familia
	, x.ds_familia
	, x.cd_grupo 
	, x.ds_grupo
	, x.cd_subgrupo 
	, x.ds_subgrupo
	, x.NumControle
	, x.SequenciaItem
	, convert(VARCHAR(8), x.emissao, 112) AS DATA_EMISSAO	
	, SUM(X.Qtdade) QTD 
	, SUM(X.VLR_BRUTO) AS vlr_bruto
	, SUM(X.DESCONTO) AS DESCONTO
	, SUM(X.PIS + X.COFINS + X.ICMS ) AS IMPOSTOS
	, SUM(X.PIS + X.COFINS + X.ICMS + X.DEVOLUCAO) DEDUCOES
	, (SUM(X.VLR_BRUTO) - SUM(X.PIS + X.COFINS + X.ICMS + X.DEVOLUCAO)) ROL
	, SUM(X.Qtdade) QTD
	, SUM(X.QTD_DEVOLVIDA) QTD_DEV
	, SUM(cmv.CustoMercadoriaVendida * X.QTD_DEVOLVIDA) AS CMV_devol
	, SUM(cmv.CustoMercadoriaVendida * X.Qtdade) AS CMV_semDevol
	, ((SUM(X.VLR_Bruto) - SUM(X.PIS + X.COFINS + X.ICMS + DEVOLUCAO)) - SUM(cmv.CustoMercadoriaVendida * (X.Qtdade - X.QTD_DEVOLVIDA))) MARGEM
	, SUM((x.margemPercentual/100)*x.vlr_bruto) MARGEMEMREAIS
	, AVG(x.margemPercentual)  PERMARGEM
	, SUM(X.Peso)  /  x.fatorconversao AS PESO
	, SUM(X.Peso) AS PESOant
	, SUM(x.frete + x.frete_alternativo + x.comissaoPercentual) AS DESPESAS
	, SUM(DEVOLUCAO) AS DEVOLUCAO
	, SUM(x.frete + x.frete_alternativo) AS FRETE
	, SUM(X.VLR_BRUTO * (x.comissaoPercentual/100)) AS COMISSAO
	, x.fatorconversao
FROM	
    (								
	  SELECT
			t1.filial as cd_Filial
			, t1.nomefilial as ds_Filial
			, t1.setor as cd_Setor
			, t1.nomesetor as ds_Setor
			, t1.secao as cd_Secao
			, t1.nomesecao as ds_Secao
			, t1.centrocusto as cd_centrocusto
			, t1.nomecentro as ds_centrocusto
			, t1.numcontrole as NumControle
			, t1.nf as NF
			, t1.sequenciaitem as SequenciaItem
			, t1.op as Op
			, t1.vendrepre as cd_representante
			, t1.nomerepre as ds_representante
			, t1.clientefornecedor as cd_cliente
			, t1.nomecliente as ds_cliente
			, t1.cidade as ds_cidade
			, t1.item as cd_Item
			, t1.nomeitem as ds_item
			, t1.emissao as emissao
			, t1.codfamilia as cd_familia
			, t1.nomefamilia as ds_familia
			, t1.codgrupo as cd_GRUPO
			, t1.nomegrupo as ds_grupo
			, t1.codsubgrupo as cd_subgrupo
			, t1.nomesubgrupo as ds_subgrupo
			, t1.margem as margemPercentual
			, t1.peso as Peso
			, t1.qtdade as Qtdade
			, t1.desconto as desconto
			, t1.valorbruto as vlr_bruto
			, t1.pis as PIS
			, t1.cofins as COFINS
			, t1.icms as ICMS
			, t1.frete as frete
			, t1.fretealternativo as frete_alternativo
			, t1.comissao as comissaoPercentual
			, 0 AS QTD_DEVOLVIDA
			, 0 AS DEVOLUCAO
			, CASE
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0801' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0802' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0803' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0804' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0805' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0806' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0807' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0808' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0809' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '1001' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8001' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8002' THEN 60
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8007' THEN 30
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8008' THEN 30
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8011' THEN 60
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8013' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8014' THEN 30
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0305' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '0401' THEN 1
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8003' THEN 60
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8012' THEN 40
				  WHEN substring(convert(varchar,t1.codfamilia+100,2),2,2) + substring(convert(varchar,t1.codgrupo+100,2),2,2) = '8015' THEN 1
				  ELSE 1
			   END as fatorconversao

		FROM vw_MovimentacaoReceita as t1 with(nolock)			
		where t1.emissao BETWEEN @datainicio AND @datafinal
		

		UNION ALL
						-- ********************** devoluções *********************
	    SELECT
		 m.nffilcod as cd_Filial
		,f.FilNomReduzido as ds_Filial
		,m.NfSetCod as cd_Setor
		,setor.SetNom as ds_Setor
		,m.NfSecCod as cd_Secao
		,sec.SecNom as ds_Secao
		,m.NfCenCusDestino as cd_centrocusto
		,ce.CenNom as ds_centrocusto
		,m.NfNumero as NumControle
		,m.NfNumDoc as NF
		,mum.ItemNumSeq as SequenciaItem
		,m.NfOpeEstCod as Op
		,m.NfVenTraCod as cd_representante
		,repre.TraNom as ds_representante
		,m.NfForCod as cd_cliente
		,t.TraNom as ds_cliente
		,city.MunNom as ds_cidade
		,mum.ItemProCod as cd_Item
		,p.ProNom as ds_item
		,m.NfDatEmis as emissao
		,p.ProFamCod as cd_familia
		,fa.FamNom as ds_familia
		,p.ProGrpCod as cd_GRUPO
		,gr.GrpNom as ds_grupo
		,p.ProSubCod as cd_subgrupo
		,sub.SubNom as ds_subgrupo
		,p.ProVlrMargen as margemPercentual
		,(p.ProVlrPLiq * mum.ItemQtdade)/1000 as Peso
		,0 as Qtdade
		,mum.ItemVlrDesc as desconto
		,0 as vlr_bruto
		,mum.ItemVlrPis*-1 as PIS
		,mum.ItemVlrCofins*-1 as COFINS
		,((mum.ItemPerIcms / 100) * (mum.ItemTotInf-mum.ItemVlrDesc+mum.ItemVlrAcres)) * ((100-mum.ItemRedIcms)/100)*-1 as ICMS
		,m.nfvlrfrete as frete
		,m.NfTranVlr as frete_alternativo
		,m.NfVenPerCom as comissaoPercentual
		,mum.ItemQtdade AS QTD_DEVOLVIDA
		,(mum.ItemTotInf) AS DEVOLUCAO
		,CASE
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0801' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0802' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0803' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0804' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0805' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0806' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0807' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0808' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0809' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '1001' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8001' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8002' THEN 60
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8007' THEN 30
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8008' THEN 30
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8011' THEN 60
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8013' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8014' THEN 30
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0305' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '0401' THEN 1
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8003' THEN 60
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8012' THEN 40
			  WHEN substring(convert(varchar,p.ProFamCod+100,2),2,2) + substring(convert(varchar,p.ProGrpCod+100,2),2,2) = '8015' THEN 1
			  ELSE 1
		  END as fatorconversao

	    FROM TRANSACIONADORES as t with(nolock)
		inner join MOVESTOQUE as m with (nolock) 
		on m.NfForCod = t.tracod
		left outer join TRANSACIONADORES as repre with (nolock) 
		on repre.TraCod = m.NfVenTraCod
		inner join MOVESTOQUELEVEL1 as mum with (nolock) 
		on mum.NfFilCod = m.NfFilCod
		and mum.NfDatEmis = m.NfDatEmis
		and mum.nfnumero = m.nfnumero
		inner join produtos as p with(nolock) 
		on p.ProCod = mum.ItemProCod
		inner join FAMILIAS as fa with(nolock) 
		on p.ProFamCod = fa.FamCod
		inner join GRUPOS  gr with(nolock) 
		on p.ProFamCod = gr.FamCod
		and p.ProGrpCod = gr.GrpCod
		inner join SUBGRUPOS sub with(nolock) 
		on p.ProFamCod = sub.FamCod
		and p.ProGrpCod = sub.GrpCod
		and p.ProSubCod = sub.SubCod
		inner join MUNICIPIOS as city with(nolock) 
		on city.MunCod = t.TraMunCod
		and city.EstCod = t.TraEstCod
		and city.PaiCod = t.TraPaiCod
		inner join FILIAIS as f with(nolock) 
		on m.NfFilCod = f.FilCod
		inner join CENTROCUSTO as ce with(nolock) 
		on m.NfCenCusDestino = ce.CenCod
		inner join SECAO as setor with(nolock) 		--SETOR
		on m.NfSetCod = setor.SetCod
		inner join SECAOLEVEL1 as sec with(nolock) 	--SEÇÃO
		on m.NfSecCod = sec.SecCod
		and	m.NfSetCod = sec.SetCod

		where m.nfecstat not in ( 101, 102 )
		and	m.NfSituacao not in (1,4)    --desconsidera notas canceladas
		and	m.NfOpeEstCod in (84, 10)    --operação de devolução
		and convert(VARCHAR(8),m.NfDatEmis, 112) BETWEEN @datainicio AND @datafinal  								        
             			                        										
	) as x
		inner join IntegraTICravil.Bi.HistoricoCMV as cmv with(nolock)		-- tabela de integração contendo 
			   ON cmv.CodigoFilial = x.cd_Filial							-- histórico do CMV
			   and cmv.DataEmissao = x.Emissao
			   and cmv.NumeroControle = x.NumControle
			   and cmv.SequenciaItemNota = x.SequenciaItem					-- campo adicionado na view para fazer relacionamento

		--where x.cd_Filial = 89

	    GROUP BY x.cd_Filial, x.ds_Filial
		, x.cd_Setor, x.ds_Setor		
		, x.cd_familia, x.ds_familia
		, x.cd_grupo, x.ds_grupo
		, x.cd_subgrupo, x.ds_subgrupo	
		, convert(VARCHAR(8), x.emissao, 112)
		, x.NumControle
		, x.SequenciaItem 
		, x.fatorconversao


		