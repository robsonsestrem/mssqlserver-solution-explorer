select 
x.Codigo,
x.NomeProduto,
x.CodFamilia,
x.CodGrupo,
x.CodSubgrupo,
x.FilialPromocao,
x.DataCDC,
convert(varchar(30),x.DataInicio, 105) as DataInicio,
convert(varchar(30),x.DataFinal, 105) as DataFinal,
x.Preco,
x.EstoqueAtual

from
	(select 
		p4.ProCod as Codigo,
		p.ProNom as NomeProduto,
		p.ProFamCod as CodFamilia,
		p.ProGrpCod as CodGrupo,
		p.ProSubCod as CodSubgrupo,
		f.FilCod as FilialPromocao,		
		convert(varchar(30),p4.ProDatAlteracao, 105) as DataCDC,
		P4.ProDatIni as DataInicio,
		P4.Final as DataFinal,		
		p4.ProVlrPreco as Preco,		
		(select dbo.getEstoque(f.FilCod, p4.ProCod, getdate())) as EstoqueAtual,
		GETDATE() as DataAtual
		
	 from PRODUTOSLEVEL4 as p4 inner join PRODUTOS as p
		on p.ProCod = p4.ProCod			
		cross join FILIAIS as f	-- maior precisão na junção
	 where  	    
		p4.ProDatIni <> '1753-01-01' -- elimina alguns
		AND p4.Final <> '1753-01-01' -- erros de registro
		AND P4.ProCodPreco = 2		 -- este código indica que a promoção é feita na sede(encarte)
		AND p.ProSituacao NOT LIKE '%n'						-- retirando produtos inativos
		AND f.FilFlag2 = 0									-- filiais ativas
		AND f.FilCod not in (1, 26, 50, 57, 61, 62, 64,     -- sem encarte	
		75, 78, 80, 82, 83, 90) 				
	) as x

where x.DataAtual between x.DataInicio and x.DataFinal
order by x.FilialPromocao














