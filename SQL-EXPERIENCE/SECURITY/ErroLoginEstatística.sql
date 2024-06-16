-----------------------------------------------------------------------------------------------------------------------
-- Ranqueamento e estatística percentual
-----------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select y.Data, y.HostName, y.[Numero de Ocorrências]
, DENSE_RANK() over (order by y.[Numero de Ocorrências] desc) as [Rank]
, cast(100. * y.[Numero de Ocorrências] / LAST_VALUE(y.Somatoria) over (order by y.Somatoria rows between unbounded preceding and unbounded following) as decimal(18,2)) AS PercentualDoTotal
from
(
select 
x.DataEvent as [Data]
, count(x.DataEvent) as [Numero de Ocorrências]
, HostName
, SUM(count(x.DataEvent)) OVER (ORDER BY count(x.DataEvent) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Somatoria
from
(
select cast(t1.DateError as date) as DataEvent, t1.HostName from Management.HistoryErrorLogin as t1
where t1.TextData like '%network error code%'
) as x
group by x.DataEvent, x.HostName
) as y
group by y.Data, y.HostName, y.[Numero de Ocorrências], y.Somatoria

order by y.[Numero de Ocorrências] desc


-----------------------------------------------------------------------------------------------------------------------
-- Total
-----------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select x.DataEvent as [Data], count(x.DataEvent) as [Numero de Ocorrências]
from
(
select cast(t1.DateError as date) as DataEvent from Management.HistoryErrorLogin as t1
where DateError >= '20180315'
and TextData like '%network error code%'
) as x
group by x.DataEvent
order by x.DataEvent desc


-----------------------------------------------------------------------------------------------------------------------
-- Por Login
-----------------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select x.DataEvent as [Data], count(x.DataEvent) as [Numero de Ocorrências], x.LoginName
from
(
select cast(t1.DateError as date) as DataEvent, t1.LoginName from Management.HistoryErrorLogin as t1
where --DateError < '20180224'
 TextData like '%network error code%'
) as x
group by x.DataEvent, x.LoginName
order by x.DataEvent desc



