select
t1.CEP from System.vw_FaltaCepMaps as t1

--select * from System.Logradouro
--where CEP = '88311601'

insert into CooperSystem.System.Maps
(
CEP
, Latitude
, Longitude
, Altitude
, DataInsercao
)
values
(
'88317902'
, '-26.887678'
, '-48.733784'
, 0
, getdate()
)


--88320990
--89261200
--89267000
--89270970
--89280301
--89291210
--89291220
--89291455
--89293899
--89294970

update CooperSystem.System.Maps set Latitude = '-26.2781476', Longitude = '-49.3658557'
where CEP = '89292335'

delete from CooperSystem.System.Maps
where CEP in 
(
'88320990',
'89261200',
'89267000',
'89270970',
'89280301',
'89291210',
'89291220',
'89291455',
'89293899',
'89294970'
)


