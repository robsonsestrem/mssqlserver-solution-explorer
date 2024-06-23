use GesCooper90
go

select  replace(', '+''''+ t1.UsuCod + '''', ' ', '') from PROGUSULEVEL1 as t1
where t1.PrgCod1 = 'TXTRANSPRECAD'

select * from PROGUSULEVEL1 as t1
where t1.PrgCod1 = 'TXTRANSPRECAD'

select * from IntegraTICravil.LogErp.ProgUsuLevel1LogDML -- acesso à programas
where DateDML >= '20181001'
and PrgCod1 = 'wpelotevencimento'



insert into GesCooper90.dbo.PROGUSULEVEL1 (UsuCod, PrgCod1, PrgNom1, PrgIncluir, PrgAlterar, PrgConsultar, PrgExcluir, PrgFlag1, PrgFlag2, PrgFlag3)
select t1.UsuCod, 'TXTRANSPRECAD', 'TRANSACIONADORES - CADASTRO RAPIDO', 0,0,0,0,1,0,0 
from GesCooper90.dbo.CADUSUARIOS as t1
where t1.UsuFilCod not in (1,57,50,62,75,76,78,82,83,90)
and t1.UsuInativo not in ( 'S', 'NULL', 's')
and t1.UsuCod not in(
'ADRIANA'
,'ALESSANDROS'
,'INFOGEN'
,'ITL-ESCRIT'
,'ITL-FINANC'
,'ITL-FINANC2'
,'ITL-GERENCIA'
,'ITL-LOJAO1'
,'ITL-LOJAO2'
,'ITL-LOJAO3'
,'ITL-LOJAO4'
,'ITL-LOJAO5'
,'ITL-RECEBIMENTO'
,'ITL-TECNICO'
,'RENAN'
,'ROBSON'
,'ROGERIO'
)

-- wpelotevencimento
--delete from GesCooper90.dbo.PROGUSULEVEL1
--where UsuCod in ('ALINE', 'FLAVIO', 'ACYR')
--and PrgCod1 = 'wpelotevencimento'