USE GesCooper90
GO

set nocount on

SELECT rec.*
, coalesce(ped.ValorFrete, 0)															as ValorFrete
, coalesce(cast(((rec.ValorBruto - ped.ValorFrete) / rec.Qtdade) as decimal(9,2)), 0)	as ValorLiquidoSemFrete
, coalesce(ped.ValorFrete, 1) / rec.Qtdade												as ValorFretePorFardo

FROM GesCooper90.dbo.vw_MovimentacaoPedidoVenda AS ped with (nolock) right join GesCooper90.dbo.vw_MovimentacaoReceita AS rec with (nolock) 
			ON rec.NumControle = ped.NumeroControle
				and rec.Item = ped.CodigoProduto
				and rec.NumeroPedido = ped.NumeroPedido
				and rec.NumeroCarga = ped.NumeroCarga
				and rec.ClienteFornecedor = ped.Transacionador
				and rec.Op = ped.Operacao
								
WHERE rec.Emissao between '20171101' and '20171130'
and rec.CodFamilia in (80,81)

set nocount off






