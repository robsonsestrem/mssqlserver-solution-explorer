-- tipo 1 = calculo de faturamento
-- tipo 2 = calculo de cmv do faturamento
-- tipo 3 = calculo de cupons não integrados
-- tipo 4 = calculo de transferências
-- tipo 5 = calculo de cmv das transferências

USE IntegraTICravil
GO
ALTER FUNCTION Bi.fn_TotaisEmailBi
(
	 @datainicio  datetime
	,@datafinal   datetime
	,@tipoCalc    smallint
)
RETURNS MONEY
WITH ENCRYPTION
AS
	BEGIN
	 
	DECLARE @totalCalc money

	IF(@tipoCalc = 1) -- total de faturamento (receita)
		BEGIN 
			declare @ultimaFilial int = (select Max(f.FilCod) from GesCooper90.dbo.FILIAIS as f WITH (nolock) where f.FilFlag2 = 0) 
			declare @incrementa int = 1
			DECLARE @valor money = 0

			WHILE (@incrementa <= @ultimaFilial)
			BEGIN
				SET @valor = ((SELECT ISNULL(SUM((m2.ItemTotInf - m2.ItemVlrDesc + m2.ItemVlrAcres)), 0)
								FROM GesCooper90.dbo.MOVESTOQUE AS m WITH (nolock)
								INNER JOIN GesCooper90.dbo.MOVESTOQUELEVEL1 AS m2 WITH (nolock) 
												ON m2.NfFilCod = m.NfFilCod
												   AND m2.NfDatEmis = m.NfDatEmis
												   AND m2.NfNumero = m.NfNumero
								   WHERE m.NfDatEmis BETWEEN @datainicio AND @datafinal   	 	
									 AND m.NfeCStat NOT IN (101,102)
									 AND m.NfSituacao NOT IN (1,4)	 
									 AND m.NfOpeEstCod IN (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204, 5, 236)
									 AND m.NfFilCod = @incrementa)
								+ @valor)
				SET @incrementa = @incrementa + 1	
			END
			SET @totalCalc = @valor
		END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		ELSE IF(@tipoCalc = 2) -- Total de custo de mercadoria vendida
			BEGIN
				SET @totalCalc = (select SUM(x.TotalCusto)
								  from(
										select (cast(c.CustoMercadoriaVendida as money) * sum(c.Quantidade) ) as TotalCusto
										from Bi.HistoricoCMV as c
										WHERE DataEmissao BETWEEN @datainicio AND @datafinal
										GROUP BY c.Quantidade, c.CustoMercadoriaVendida
										) as x
								  )
			END
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			ELSE IF(@tipoCalc = 3) -- Total de cupons não integrados
				BEGIN
					SET @totalCalc =
					(
					SELECT Sum(totLiq.totliquido) - Sum(totLiq.troco) AS Total_OP5 
					FROM   (SELECT CASE 
									 WHEN liquido.tipo_cupom = 'fiscal' 
										  AND liquido.tipo_pagamento <> 'troco' THEN 
									 Sum(liquido.totais) 
								   END AS TotLiquido, 
								   CASE 
									 WHEN liquido.tipo_cupom = 'fiscal' 
										  AND liquido.tipo_pagamento = 'troco' THEN 
									 Sum(liquido.totais) 
								   END AS troco 
							FROM   (SELECT cupons.tipo_cupom, 
										   cupons.tipo_pagamento, 
										   Sum(cupons.valor) AS totais 
									FROM   (SELECT CASE Isnull(cupgnf, 0) 
													 WHEN 0 THEN 'Fiscal' 
													 ELSE 'Não Fiscal' 
												   END            AS tipo_cupom, 
												   CASE cuptottiprec 
													 WHEN 1 THEN 'Dinheiro' 
													 WHEN 2 THEN 'Cheque' 
													 WHEN 3 THEN 'Crediário' 
													 WHEN 4 THEN 'Vasilhame' 
													 WHEN 5 THEN 'Desconto' 
													 WHEN 6 THEN 'Ticket' 
													 WHEN 7 THEN 'Milho' 
													 WHEN 8 THEN 'leite' 
													 WHEN 9 THEN 'Arroz' 
													 WHEN 10 THEN 'Cartão Crédito' 
													 WHEN 11 THEN 'Cartão Débito' 
													 WHEN 12 THEN 'Troco' 
												   END            AS tipo_pagamento, 
												   Sum(cuptotvlr) AS valor 
											FROM   GesCooper90.dbo.vendasecflevel2 v2 WITH (nolock) 
												   INNER JOIN GesCooper90.dbo.vendasecf v WITH (nolock) 
														   ON v.filcod = v2.filcod 
															  AND v.caicod = v2.caicod 
															  AND v.caiopecod = v2.caiopecod 
															  AND v.cupcodigo = v2.cupcodigo 
															  AND v.cupdatmov = v2.cupdatmov 
											WHERE  v2.cupdatmov between @dataInicio and @datafinal
												   AND (v.CupGNF is null or v.CupGNF = 0)	-- Trazer apenas tipo fiscal, não fiscal sempre traz um valor válido
												   AND v.CupSitIntegracao = 0				-- trazer os não integrados
												   AND v.cupsituac = 1						-- trazer os não cancelados									   																		  				  				  					  
											GROUP  BY cuptottiprec, 
													  cupgnf) AS cupons 
									GROUP  BY tipo_cupom, 
											  tipo_pagamento) AS liquido 
							GROUP  BY liquido.tipo_cupom, 
									  liquido.tipo_pagamento) AS totLiq 
					)
				END	-- fim da opção 3
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				ELSE IF(@tipoCalc = 4) -- total de faturamento (receita)
					BEGIN 
						declare @ultimaFilialTransf int = (select Max(f.FilCod) from GesCooper90.dbo.FILIAIS as f WITH (nolock) where f.FilFlag2 = 0) 
						declare @incrementaTransf int = 1
						DECLARE @valorTransf money = 0

						WHILE (@incrementaTransf <= @ultimaFilialTransf)
						BEGIN
							SET @valorTransf = ((SELECT ISNULL(SUM((m2.ItemTotInf - m2.ItemVlrDesc + m2.ItemVlrAcres)), 0)
											FROM GesCooper90.dbo.MOVESTOQUE AS m WITH (nolock)
											INNER JOIN GesCooper90.dbo.MOVESTOQUELEVEL1 AS m2 WITH (nolock) 
															ON m2.NfFilCod = m.NfFilCod
															   AND m2.NfDatEmis = m.NfDatEmis
															   AND m2.NfNumero = m.NfNumero
											   WHERE m.NfDatEmis BETWEEN @datainicio AND @datafinal   	 	
												 AND m.NfeCStat NOT IN (101,102)
												 AND m.NfSituacao NOT IN (1,4)	 
												 AND m.NfOpeEstCod IN (2, 46)
												 AND m.NfFilCod = @incrementaTransf)
											+ @valorTransf)
							SET @incrementaTransf = @incrementaTransf + 1	
						END
						SET @totalCalc = @valorTransf						
					END
					ELSE IF(@tipoCalc = 5) -- Total de custo de mercadoria vendida nas transferências
						BEGIN
							SET @totalCalc = (select SUM(x.TotalCusto)
											  from(
													select (cast(c.CustoMercadoriaVendida as money) * sum(c.Quantidade) ) as TotalCusto
													from Bi.HistoricoCMVTransf as c
													WHERE DataEmissao BETWEEN @datainicio AND @datafinal
													GROUP BY c.Quantidade, c.CustoMercadoriaVendida
													) as x
											  )
						END
					
	RETURN @totalCalc
END


