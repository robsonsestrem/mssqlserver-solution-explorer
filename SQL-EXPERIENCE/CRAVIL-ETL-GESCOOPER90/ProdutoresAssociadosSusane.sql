--use CooperSystem
--go


--select
--t1.MatriculaERP
--, t1.NomeRazaoSocial
--, t1.CpfCnpj
--, t1.Cidade
--from System.vw_AssociadoERP as t1
--where t1.Situacao = 1
--and t1.MatriculaERP = 52449

-- 52449


select 
distinct	-- view contém mais de um contato por pessoa, por isso duplica
t1.MatriculaERP as [Matrícula]
, t1.NomeRazaoSocial as [Nome\RazaoSocial]
, t1.CpfCnpj as [CPF\CNPJ]
, t2.Cidade
, t1.NatJuridica as [Nat.Jurídica]
from System.vw_MatriculaERP as t1
inner join System.vw_AssociadoERP as t2
on t1.IdPessoa = t2.IdPessoa
where t1.Situacao = 1
and t1.TipoPessoa_ERP = 'PRODUTOR-ASSOCIADO'



--select 
--*
--from System.vw_MatriculaERP as t1
--where t1.Situacao = 1
--and t1.TipoPessoa_ERP = 'PRODUTOR-ASSOCIADO'