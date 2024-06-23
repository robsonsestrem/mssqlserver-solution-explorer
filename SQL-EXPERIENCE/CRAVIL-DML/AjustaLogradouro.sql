use GesCooper90
go

select t1.tracod, t1.ImoCod, t1.ImoLogCod, t1.ImoLogSIGACod
, * 
from IMOVEIS as t1
where tracod = 102974 
and ImoCod = 1
and ImoLogCod = 24 		-- logradouro
and ImoLogSIGACod = 13	-- tipo logradouro no caso estrada

---------------------------------------------------------------------------------------------------------------------------------
-- Exemplo de Adriana
---------------------------------------------------------------------------------------------------------------------------------
update IMOVEIS
set ImoLogCod = 24,			
    ImoLogSIGACod = 13		
where tracod = 71886 
and ImoCod = 1


---------------------------------------------------------------------------------------------------------------------------------
-- Ticket 19174, lembrando que teve e-mail do Adami autorizando...
---------------------------------------------------------------------------------------------------------------------------------
use GesCooper90
go

insert into LOGRADOUROS 
values
(
'BRA',
'PR',
53821,			-- município de Antonina
500,			-- LogCod uma sequência de códigos para cada estado, o próximo nesse caso é 500
'Rio Pequeno',	-- nome do logradouro, existe logcod para este nome mas é para cidades diferentes
0,				-- LogCodMapeamento pode ser zero
48930			-- LogCodLocalidade - entede-se que são localidades dentro de logradouros pois tem código de logradouro com várias localidades
)


select * from MUNICIPIOS as t1
where t1.MunNom like '%antonina%'


SELECT * FROM LOGRADOUROS as t1
where t1.LogNom = 'rio pequeno'

order by t1.LogCod asc


