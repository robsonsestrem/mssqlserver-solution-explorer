use GesCooper90
go

-- Fixando dia anterior
DECLARE @datainicio datetime = dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))
DECLARE @datafinal datetime = dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(DAY,-1,cast(floor(cast(getdate()as float))as datetime))))))

SELECT 
v.FilCod								AS Filial,
v.CupCodigo								AS Cupom,
CONVERT(VARCHAR(12),v.CupDatMov,105)	AS Data,
v.CaiCod								AS Caixa,
v.CupCliCod								AS Cliente,
v.CupSituac								AS Situação,		-- -1 é cancelado, 1 é normal 
v.CupSitIntegracao						AS Integração,		-- 0 não integrado, 1 integrado
case when ISNULL(v.CupGNF, 0) = 0 
	THEN 'FISCAL' 
else 'NÃO FISCAL'
end										AS TipoCupom
,v.CupGNF

FROM VENDASECF as v 
where v.CupDatMov between @datainicio and @datafinal 
and v.CupSituac = 1						-- trazer os não cancelados
and v.CupSitIntegracao = 0				-- trazer os não integrados
and (v.CupGNF is null or v.CupGNF = 0)	-- Trazer apenas tipo fiscal,
										-- não fiscal sempre traz um valor válido

/***
Obs.: Os cupons não fiscais (recarga de celular, sigacred, pagt de NF, etc...) 
      serão integrados somente depois de algumas rotinas
	  para o fechamento dos caixas.
	  Cupom não integrado não aparece na tela de documentos,
	  Menu - Comercial > Movimentação > Documentos	
***/









