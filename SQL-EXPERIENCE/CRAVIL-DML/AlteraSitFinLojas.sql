-----------------------------------------------------------------------------------------------------------------------------------
-- Dar permição para usuário das filiais para acessar situação financeira
-- No caso as flags correspondem à Transacionadores/Produtos -> setado permissão individual (UsuFlag9 = 4)
-- Outra é Permissão Cadastro Transacionadores -> setado permissão p/ alterar (UsuFlag23 = 3)
-----------------------------------------------------------------------------------------------------------------------------------

-- teste para filtragem
select * from CADUSUARIOS as c
where c.UsuCod like '%finan%'


-- update
begin tran
update CADUSUARIOS set UsuFlag9 = 4, UsuFlag23 = 3
where UsuCod like '%finan%'

commit -- ou rollback
