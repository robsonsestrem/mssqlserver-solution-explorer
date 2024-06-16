use GesCooper90
go
DECLARE @datainicial DATETIME = '2017-09-20'; 
DECLARE @datafinal DATETIME = '2017-09-20';	  
------------------------------------------------------------------------- 
DECLARE @naoFiscal INT = 0; 
DECLARE @situacao SMALLINT = 1; 

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
       fun.VendedorCodigo, 
       fun.VendedorNome, 
       fun.ClienteCodigo, 
       fun.ClienteNome, 
       fun.Cidade, 
       fun.CodigoPag, 
       fun.TipoPagamento, 
       fun.Vencimento, 
       fun.Valor 
FROM   GetMovimentoFinanceiro(@datainicial, @datafinal) AS fun 
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
               nf.nfopeestcod			AS nfopeestcod,
               vendas.cod_pag			AS cod_pag,
               vendas.tipo_pagamento	AS tipo_pagamento,
               vendas.vencimento		AS vencimento,
               vendas.valor				AS valor
        FROM   vw_MovCaixas AS vendas WITH(nolock) 
               INNER JOIN vendasecf AS v WITH(nolock) 
                       ON v.filcod = vendas.filial 
                          AND v.caicod = vendas.caixa 
                          AND v.caiopecod = vendas.operador 
                          AND v.cupcodigo = vendas.codigo 
                          AND v.cupdatmov = vendas.data 
               INNER JOIN movestoque AS nf WITH(nolock) 
                       ON nf.nffilcod = v.filcod 
                          AND nf.nfnumdoc = v.cupcodigo 
                          AND nf.nfdatemis = v.cupdatmov 
                          AND nf.nfnumcab = v.caicod 
               INNER JOIN filiais AS f WITH(nolock) 
                       ON nf.nffilcod = f.filcod 
               INNER JOIN transacionadores AS t WITH(nolock) 
                       ON nf.nfforcod = t.tracod 
               LEFT JOIN transacionadores AS repre WITH(nolock) 
                       ON repre.tracod = nf.nfventracod 
               LEFT JOIN centrocusto AS ce WITH(nolock) 
                       ON nf.nfcencusdestino = ce.cencod 
               LEFT JOIN secao AS setor WITH(nolock) 
                       ON nf.nfsetcod = setor.setcod 
               LEFT JOIN secaolevel1 AS sec WITH(nolock) 
                       ON nf.nfseccod = sec.seccod 
                          AND nf.nfsetcod = sec.setcod 
               LEFT JOIN municipios AS city WITH(nolock) 
                       ON city.muncod = t.tramuncod 
                          AND city.estcod = t.traestcod 
                          AND city.paicod = t.trapaicod 
        WHERE  v.cupdatmov BETWEEN @datainicial AND @datafinal 
               AND v.cupsituac = @situacao 
               AND v.cupgnf = @naoFiscal) AS cupons 
			
		

