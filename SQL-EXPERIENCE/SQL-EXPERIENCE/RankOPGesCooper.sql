use GesCooper90
go

select 
y.DataEmissao
, y.OP
, y.NomeOP
, y.TotalPorDia
, DENSE_RANK() over (order by y.TotalPorDia desc) as [Rank]
, cast(100. * y.TotalPorDia / LAST_VALUE(y.Somatoria) over 
  (order by y.Somatoria rows between unbounded preceding and unbounded following) as decimal(18,2)) AS Percentual
from
(
	select
	x.DataEmissao
	, count(x.DataEmissao) as TotalPorDia
	, x.OP
	, x.NomeOP
	, SUM(count(x.DataEmissao)) OVER (ORDER BY count(x.DataEmissao) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Somatoria

	from
	(
		select 
		 --t1.NfFilCod													as Filial
		 cast(t1.NfDatEmis as date)									    as DataEmissao	-- convertido para contar
		, t1.NfOpeEstCod												as OP
		, t2.OpeEstNom													as NomeOP
		from MOVESTOQUE as t1 with(nolock) 
		inner join OPERACAO as t2
			on t1.NfOpeEstCod = t2.OpeEstCod	
		where t1.NfDatEmis >= '20181003'
		--and t1.NfeCStat not in (101,102)
		--and t1.NfSituacao not in (1,4)
	) as x
	group by x.DataEmissao, x.OP, x.NomeOP
) as y
order by y.TotalPorDia desc



--select count(t1.NfNumDoc) from MOVESTOQUE as t1
--where t1.NfOpeEstCod = 5
--and t1.NfeCStat not in (101,102)
--and t1.NfSituacao not in (1,4) 
--and t1.NfDatEmis = '20181003'























