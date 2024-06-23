USE [IntegraTICravil]
GO
--select * from Bi.fn_MovimentoFinanceiro('20170920', '20170920')

ALTER function [Bi].[fn_MovimentoFinanceiro]( @datainicial DATETIME, @datafinal DATETIME )

RETURNS @Financeiro TABLE 
(
FilialCodigo smallint,
FilialNome varchar(80),
SetorCodigo integer,
SetorNome varchar(80),
SecaoCodigo integer,
SecaoNome varchar(80),
CentroCustoCodigo integer,
CentroCustoNome varchar(80),
NumeroControle integer,
NumeroDocumento integer,
Operacao smallint,
Emissao datetime,
Item int,
SequenciaItem int,
VendedorCodigo integer,
VendedorNome varchar(80),
ClienteCodigo integer,
ClienteNome varchar(80),
Cidade varchar(80),
CodigoPag smallint,      --adicional
TipoPagamento varchar(30),
Vencimento DateTime,
Valor money
)
AS
BEGIN
	INSERT INTO @Financeiro
	SELECT fun.FilialCodigo, 
		   fun.FilialNome, 
		   fun.SetorCodigo, 
		   fun.SetorNome, 
		   fun.SecaoCodigo, 
		   fun.SecaoNome, 
		   fun.CentroCustoCodigo, 
		   fun.CentroCustoNome, 
		   fun.NumeroControle, 
		   fun.NumeroDocumento, 
		   fun.Operacao, 
		   fun.Emissao,
		   fun.Item,
		   fun.SequenciaItem, 
		   fun.VendedorCodigo, 
		   fun.VendedorNome, 
		   fun.ClienteCodigo, 
		   fun.ClienteNome, 
		   fun.Cidade, 
		   fun.CodigoPag, 
		   fun.TipoPagamento, 
		   fun.Vencimento, 
		   fun.Valor	  
	FROM   GesCooper90.dbo.GetMovimentoFinanceiro(@datainicial, @datafinal) AS fun 
	-- Funcao desenvolvida para tratar valores de vencimentos diferentes 
	---------------------------------------------------------------------------------------------------------------------------------------------------------     
	UNION ALL
	--------------------------------------------------------------------------------------------------------------------------------------------------------- 
	SELECT cupons.filcod         AS Filial, 
		   cupons.filnomreduzido AS Nome_Filial, 
		   cupons.codsetor       AS Setor, 
		   cupons.nomesetor      AS Nome_Setor, 
		   cupons.codsecao       AS Secao, 
		   cupons.nomesecao      AS Nome_Secao, 
		   cupons.centro_custo   AS Centro_Custo, 
		   cupons.nome_centro    AS Nome_Centro, 
		   cupons.nfnumero       AS NumControle, 
		   cupons.nfnumdoc       AS NF, 
		   cupons.nfopeestcod    AS Op, 
		   cupons.cupdatmov      AS Emissao,
		   cupons.Item			 AS Item,
		   cupons.SequenciaItem  AS SequenciaItem,		   		    
		   cupons.codrepre       AS Vend_Repre, 
		   cupons.nomerepre      AS Nome_Repre, 
		   cupons.codcliente     AS Cliente, 
		   cupons.nomecliente    AS Nome_cliente, 
		   cupons.munnom         AS Cidade, 
		   cupons.cod_pag        AS CodigoPag, 
		   cupons.tipo_pagamento AS Tipo_Pag, 
		   cupons.vencimento     AS Vencimento, 
		   cupons.valor			 AS Valor
	FROM   (SELECT v.cupdatmov				AS cupdatmov,
				   v.filcod					AS filcod,
				   f.filnomreduzido			AS filnomreduzido,
				   nf.nfnumdoc				AS nfnumdoc,
				   nf.nfnumero				AS nfnumero,
				   nf.nfforcod              AS codcliente, 
				   t.tranom                 AS nomecliente, 
				   nf.nfventracod           AS codrepre, 
				   Isnull(repre.tranom, '') AS nomerepre, 
				   nf.nfsetcod              AS codsetor, 
				   setor.setnom             AS nomesetor, 
				   nf.nfseccod              AS codsecao, 
				   sec.secnom               AS nomesecao, 
				   nf.nfcencusdestino       AS centro_custo, 
				   ce.cennom                AS nome_centro, 
				   city.munnom				AS munnom,
				   v2.CupIteProCod			AS Item,
				   v2.CupIteNum				AS SequenciaItem,
				   nf.nfopeestcod			AS nfopeestcod,
				   vendas.cod_pag			AS cod_pag,
				   vendas.tipo_pagamento	AS tipo_pagamento,
				   vendas.vencimento		AS vencimento,
				   vendas.valor				AS valor
			FROM   GesCooper90.dbo.vw_MovCaixas AS vendas WITH(nolock) 
				   INNER JOIN GesCooper90.dbo.VENDASECF AS v WITH(nolock) 
						   ON v.filcod = vendas.filial 
							  AND v.caicod = vendas.caixa 
							  AND v.caiopecod = vendas.operador 
							  AND v.cupcodigo = vendas.codigo 
							  AND v.cupdatmov = vendas.data 
				   inner join GesCooper90.dbo.VENDASECFLEVEL1 as v2
						   on v2.FilCod = v.FilCod
						   and v2.CaiCod = v.CaiCod
						   and v2.CaiOpeCod = v.CaiOpeCod
						   and v2.CupCodigo = v.CupCodigo
						   and v2.CupDatMov = v.CupDatMov
				   INNER JOIN GesCooper90.dbo.MOVESTOQUE AS nf WITH(nolock) 
						   ON nf.nffilcod = v.filcod 
							  AND nf.nfnumdoc = v.cupcodigo 
							  AND nf.nfdatemis = v.cupdatmov 
							  AND nf.nfnumcab = v.caicod 
				   INNER JOIN GesCooper90.dbo.FILIAIS AS f WITH(nolock) 
						   ON nf.nffilcod = f.filcod 
				   INNER JOIN GesCooper90.dbo.TRANSACIONADORES AS t WITH(nolock) 
						   ON nf.nfforcod = t.tracod 
				   LEFT JOIN GesCooper90.dbo.TRANSACIONADORES AS repre WITH(nolock) 
						   ON repre.tracod = nf.nfventracod 
				   LEFT JOIN GesCooper90.dbo.CENTROCUSTO AS ce WITH(nolock) 
						   ON nf.nfcencusdestino = ce.cencod 
				   LEFT JOIN GesCooper90.dbo.SECAO AS setor WITH(nolock) 
						   ON nf.nfsetcod = setor.setcod 
				   LEFT JOIN GesCooper90.dbo.SECAOLEVEL1 AS sec WITH(nolock) 
						   ON nf.nfseccod = sec.seccod 
							  AND nf.nfsetcod = sec.setcod 
				   LEFT JOIN GesCooper90.dbo.MUNICIPIOS AS city WITH(nolock) 
						   ON city.muncod = t.tramuncod 
							  AND city.estcod = t.traestcod 
							  AND city.paicod = t.trapaicod 
			WHERE  v.cupdatmov BETWEEN @datainicial AND @datafinal 
				   AND v.CupSituac = 1 
				   AND v.CupGNF = 0		-- não fiscal
			) AS cupons 
	RETURN;
END			
GO


