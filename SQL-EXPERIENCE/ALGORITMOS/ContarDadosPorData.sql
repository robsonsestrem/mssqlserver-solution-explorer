------------------------------------------------------------------------------------------------------------------------------
-- Opção 01 - zera o time convertendo para date
------------------------------------------------------------------------------------------------------------------------------
select x.Data, COUNT(*) as DadosTotais
from
(
select cast(t1.DateReference as date) as [Data]
from Management.HistoryIndexFragmentation as t1
) as x
group by x.Data
order by x.Data desc


------------------------------------------------------------------------------------------------------------------------------
-- Opção 01 - zera o time com floor e agrupamento otimizado com substring
------------------------------------------------------------------------------------------------------------------------------
select x.TimeZerado, COUNT(*)
from
(
 select cast(floor(cast(t1.DateReference as float)) as datetime) as TimeZerado from IntegraTICravil.Management.HistoryIndexFragmentation as t1
 ) as x
group by substring(CONVERT(varchar(10), x.TimeZerado, 103),4,2), x.TimeZerado
order by x.TimeZerado desc

