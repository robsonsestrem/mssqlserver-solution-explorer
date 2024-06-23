use IntegraTICravil
go
SELECT *
FROM   LogErp.CadusuariosLogDML
where DateDML >= '20181218'
and ColumnUpdate = 'UsuVerCodigo'
and ValueNew = 144


-----------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select * from LogErp.TransacionadorLogDML as t
where DateDML >= '20180823'
--and t.Tracod = 91867
and t.ColumnUpdate = 'TraCep'


-----------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select * from LogErp.ProgUsuLevel1LogDML -- acesso à programas
where DateDML >= '20190104'

-----------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select * from LogErp.Produtoslevel4LogDML -- alterações de preços
where DateDML >= '20180823'

-----------------------------------------------------------------------------------------------------------------
use IntegraTICravil
go
select * from LogErp.ProdutosLogDML
where DateDML >= '20180820'
--and Procod = 51524

-----------------------------------------------------------------------------------------------------------------
select * from GesCooper90.dbo.LOG_CONTROLE_ZERADO	-- grava eventos de notas com nº de controle zerado
where NfDatEmis >= '20180115' --and NfDatEmis <= '20170731'
--order by NfDatEmis


-----------------------------------------------------------------------------------------------------------------
select * from GesCooper90.dbo.LOG_CRUD  -- log feito pelo Joabel, DML na MOVBAN vinda de uma trigger
where LCRD_DATAHORA >= '20180905'


-----------------------------------------------------------------------------------------------------------------
select * from GesCooper90.dbo.LogAcesso  -- log de acessos ao gescooper WEB - 192.1.1.144/GesCooperERP/


-----------------------------------------------------------------------------------------------------------------
select * from GesCooper90.dbo.CADUSUARIOSLOG as t1 -- registra cada programa acessado por usuário
where t1.UsuEntrada >= '20180503'


-----------------------------------------------------------------------------------------------------------------
select * from GesCooper90.dbo.LOGALTPRODUTOS as t1  -- Log de alterações nos produtos
where t1.LogAltProDatAlt >= '20171011'
--and ProCod = 51524

