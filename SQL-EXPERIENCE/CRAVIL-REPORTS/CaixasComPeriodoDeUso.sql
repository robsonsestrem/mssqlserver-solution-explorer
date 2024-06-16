use GesCooper90
go

select 
t1.EscFilCod as Filial
, t1.EscCaiCod as Caixa
, convert(varchar(20), min(t1.escdatmov), 103) as PrimeiroDia
, convert(varchar(20), max(t1.escdatmov), 103) as UltimaVenda
, t2.CaiSerFab as SerieECF
from escecf as t1
inner join CAIXAS as t2 on t1.EscFilCod = t2.FilCod and t2.caicod = t1.EscCaiCod
group by CaiSerFab, EscFilCod, EscCaiCod