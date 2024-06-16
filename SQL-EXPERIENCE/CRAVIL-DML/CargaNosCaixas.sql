--------------------------------------------------------------------------------------------------------
-- quando for necessário realizar UPDATE para zerar uma carga de clientes ou produtos
-- ATENÇÃO - lembrando que se deve filtrar filial e seus devidos caixas
--------------------------------------------------------------------------------------------------------
use GesCooper90
go
-- tabela onde se encontra a integração de transacionadores
-- TEM A LETRA I no campo CaiIntTraSit -> NÃO INTEGRADO
-- TEM A LETRA A no campo CaiIntTraSit -> INTEGRADO
SELECT * FROM CAIXASINTTRA


--------------------------------------------------------------------------------------------------------
-- tabela de integração de produtos
-- TEM A LETRA I no campo CaiIntProSit -> NÃO INTEGRADO
-- TEM A LETRA A no campo CaiIntProSit -> INTEGRADO
SELECT * FROM CAIXASINTPRO as c
where c.CaiIntFilCod = 3
and c.CaiIntProCod = 8490
and c.CaiIntProUltImp >= '20170427 00:00:00.000'