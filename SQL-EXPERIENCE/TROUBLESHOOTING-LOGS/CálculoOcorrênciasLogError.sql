use YOUR_DATABASE
go

select y.Data, y.HostName, y.[Numero de Ocorr�ncias]
, DENSE_RANK() over (order by y.[Numero de Ocorr�ncias] desc) as [Rank]
, cast(100. * y.[Numero de Ocorr�ncias] / LAST_VALUE(y.Somatoria) over (order by y.Somatoria rows between unbounded preceding and unbounded following) as decimal(18,2)) AS PercentualDoTotal
from
(
select 
x.DataEvent as [Data]
, count(x.DataEvent) as [Numero de Ocorr�ncias]
, HostName
, SUM(count(x.DataEvent)) OVER (ORDER BY count(x.DataEvent) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as Somatoria
from
(
select cast(t1.DateError as date) as DataEvent, t1.HostName from Management.HistoryErrorLogin as t1
where t1.TextData like '%network error code%'
) as x
group by x.DataEvent, x.HostName
) as y
group by y.Data, y.HostName, y.[Numero de Ocorr�ncias], y.Somatoria

order by y.[Numero de Ocorr�ncias] desc
