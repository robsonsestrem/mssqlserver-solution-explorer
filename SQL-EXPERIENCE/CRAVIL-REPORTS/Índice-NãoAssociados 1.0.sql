	/*
	   case T.TraNatSocial
            when 1 then 'Associado'
            when 3 then 'Não Associado'
       end as 'Nat. Social'
    */
-- RANK() over(partition by day(t.DateDML) order by t.DateDML) as RankingByDay -- ranqueamento de desligamento por dia

use GesCooper90
go
select 
	x.Código,
	x.Nome,
	x.Data_Alteracao,
	x.Filial,
	x.[Natureza-Social]
from 
	(select
		t.Tracod as Código, 
		tra.TraNom as Nome,
		convert(varchar(12),t.DateDML,103) as Data_Alteracao,
		f.FilNomReduzido as Filial,
		case t.ValueNew 
			when '3' then 'Não Associado'
			end as Natureza-Social
		
	from TransacionadorLogDML as t inner join TRANSACIONADORES as tra
				on tra.TraCod = t.Tracod inner join FILIAIS as f
					on f.FilCod = tra.TraFilCod
	WHERE t.ColumnUpdate = 'tranatsocial'
	and t.ValueOld = '1'
	and t.ValueNew <> '1'

	union

	select 
		t2.Tracod as Código,
		tra2.TraNom as Nome,
		convert(varchar(12),t2.DateDML,103) as Data_Alteracao,
		f2.FilNomReduzido as Filial,
		case t2.ValueNew 
			when '1' then 'Associado'
			end as Natureza-Social
	from TransacionadorLogDML as t2 inner join TRANSACIONADORES as tra2
							on tra2.TraCod = t2.Tracod inner join FILIAIS as f2
								on f2.FilCod = tra2.TraFilCod
	where t2.ColumnUpdate = 'tranatsocial'
	and t2.ValueOld = '3'
	and t2.ValueNew <> '3'
	) as x
order by x.Nome