-----------------------------------------------------------------------------------------------------------------------------------
-- Altera��o em massa entre duas base de dados (UPDATE COM SELECT)
-----------------------------------------------------------------------------------------------------------------------------------
begin tran

update YOUR_DATABASE.dbo.PRODUTOS set ProUndReferencial = deriva.ProUnidReferencial, ProFatConversao = deriva.ProFatConversao

from (
select pn.ProCod,pn.ProUnidReferencial, pn.ProFatConversao from TICRAVIL.dbo.ProdutosNew as pn

) as deriva
where deriva.ProCod = PRODUTOS.ProCod


commit

rollback