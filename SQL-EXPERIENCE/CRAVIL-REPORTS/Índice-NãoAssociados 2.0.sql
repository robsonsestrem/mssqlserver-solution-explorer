select 
x.Codigo, x.Nome, x.Natureza_Social, x.Filial, x.Data_Alteracao, x.Usuario
from
	( select
		t.Tracod					as Codigo, 
		tra.TraNom					as Nome,
		'Não Associado'				as Natureza_Social,
		f.FilNomReduzido			as Filial,
		max(t.DateDML)				as Data_Alteracao,				-- última data em que foi setado como não-associado
		t.LoginUserSQLTransaction	as Usuario
						
	   from TransacionadorLogDML as t inner join TRANSACIONADORES as tra
					on tra.TraCod = t.Tracod inner join FILIAIS as f
						on f.FilCod = tra.TraFilCod
	   WHERE t.ColumnUpdate = 'tranatsocial'
		and t.ValueOld = '1'
		and t.ValueNew not in (1,2)
		and t.Tracod not in (select t2.TraCod				-- não trazer o código de desligamento														
							 from TRANSACIONADORES as t2	-- sendo igual ao de associado
							 where t2.TraNatSocial = 1
							 and t2.TraCod = t.Tracod		
							 )
		group by t.Tracod, tra.TraNom, f.FilNomReduzido, t.LoginUserSQLTransaction

	union all

	select
		tra.TraCod,
		tra.TraNom			as Nome,	
		'Associado'			as Natureza_Social,
		f.FilNomReduzido	as Filial,	
		tra.TraDatAdmissao  as Data_Alteracao,
		tra.TraUsuCod		as Usuario
						
	from TRANSACIONADORES as tra inner join FILIAIS as f -- estado atual de transacionadores
					on f.FilCod = tra.TraFilCod
	WHERE tra.TraNatSocial = 1		
	) as x
order by x.Data_Alteracao
