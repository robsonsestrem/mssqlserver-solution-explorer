--select top 20 t1.Latitude, t1.Longitude
--,cast(round((t1.Latitude * 1.000001),10) as decimal(18,8)), cast(round((t1.Longitude * 1.000001),10) as decimal(18,8))
-- from System.vw_MapsAssociados as t1 where t1.Latitude <> '' or t1.Longitude <> ''


--select (-27.1688554 * 1.000001), (-49.5355337 * 1.000001)

--,cast((-27.1688554 * 1.000001) as decimal(18,8)), cast((-49.5355337 * 1.000001) as decimal(18,8))

--, -27.1688554, -49.5355337


;with coord
as
(
select t1.Latitude
, t1.Longitude
, t1.NomeRazaoSocial
, ROW_NUMBER() over (partition by t1.Latitude order by t1.Latitude) as Contador
from System.vw_MapsAssociados as t1
where t1.Latitude is not null
and t1.Latitude <> ''
)
select 
t2.NomeRazaoSocial
--
, case when t2.Contador > 1 and len(t2.Latitude) < 10 then (t2.Latitude + cast(t2.Contador as varchar(5)))				-- concatenar Strings
	   when t2.Contador > 1 and len(t2.Latitude) >= 10  then stuff(t2.Latitude, 10, 5, cast(t2.Contador as varchar(5))) -- substituição inteligente
  else t2.Latitude
  end as Latitude
--
, case when t2.Contador > 1 and len(t2.Longitude) < 10 then (t2.Longitude + cast(t2.Contador as varchar(5)))				-- concatenar Strings
       when t2.Contador > 1 and len(t2.Longitude) >= 10  then stuff(t2.Longitude, 10, 5, cast(t2.Contador as varchar(5)))   -- substituição inteligente
  else t2.Longitude
  end as Longitude
from coord as t2