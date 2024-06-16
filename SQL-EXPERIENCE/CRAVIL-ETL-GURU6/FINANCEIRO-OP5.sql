USE GesCooper90
GO

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
                        FROM   vendasecflevel2 v2 WITH (nolock) 
                               INNER JOIN vendasecf v WITH (nolock) 
                                       ON v.filcod = v2.filcod 
                                          AND v.caicod = v2.caicod 
                                          AND v.caiopecod = v2.caiopecod 
                                          AND v.cupcodigo = v2.cupcodigo 
                                          AND v.cupdatmov = v2.cupdatmov 
                        WHERE  v2.filcod = 73 
                               AND v2.cupdatmov = CONVERT(DATETIME, '10/03/2015', 103) 
                               AND v.cupsituac = 1	-- não cancelado 
							   --and not (v.CupGNF = 0 or v.CupGNF  is null) 
                        GROUP  BY cuptottiprec, 
                                  cupgnf) AS cupons 
                GROUP  BY tipo_cupom, 
                          tipo_pagamento) AS liquido 
        GROUP  BY liquido.tipo_cupom, 
                  liquido.tipo_pagamento) AS totLiq 