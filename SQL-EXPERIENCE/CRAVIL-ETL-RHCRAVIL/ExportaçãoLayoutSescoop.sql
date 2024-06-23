use rhcravil
go

select 
  FicBasica.numcpf																					as CPF
, FicBasica.nomfun																					as Nome
--, FicBasica.numcra as [Nº Crachá]
, left(FicBasica.nomfun,charindex(' ', FicBasica.nomfun))											as [Crachá]
, case when FicComplementar.emapar is null 
       or replace(coalesce(FicComplementar.emapar, ''), ' ', '') = ''
       then 'rh@cravil.com.br'
       else coalesce(FicComplementar.emapar, '')
  end 																								as [E-mail]
--
, case when FicBasica.tipsex = 'M' then '1'
       when FicBasica.tipsex = 'F' then '2'
  end																								as Sexo
--
, convert(varchar(20), FicBasica.datnas, 103)														as [Data Nascimento]
--
, coalesce(case when FicBasica.estciv in(1, 9) then '4'           --'Solteiro'
       when FicBasica.estciv = 2 then '1'		                  -- 'Casado'
	   when FicBasica.estciv = 3 then '3'						  -- 'Divorciado'
	   when FicBasica.estciv = 4 then '6'						  -- 'Viúvo'
	   --when FicBasica.estciv = 5 then 'Concubinato'
	   when FicBasica.estciv = 6 then '2'						  -- 'Separado'
	   when FicBasica.estciv in(7, 5) then '5'					  -- 'União Estável'	  
	   --when FicBasica.estciv = 9 then 'Outros'
  end, '')																							as [Estado Civil]
--
--, coalesce((SELECT TOP 1  dependentes.nomdep FROM rhcravil.r036dep AS dependentes
--	 WHERE  dependentes.numemp = FicBasica.numemp 
--	 AND dependentes.tipcol = FicBasica.tipcol 
--	 AND dependentes.numcad = FicBasica.numcad 
--	 AND dependentes.grapar = 3
--	 AND dependentes.tipsex = 'M'), '') AS Pai
----
--, coalesce((SELECT TOP 1 dependentes.nomdep FROM rhcravil.r036dep AS dependentes
--	WHERE dependentes.numemp = FicBasica.numemp 
--	 AND dependentes.tipcol = FicBasica.tipcol 
--	 AND dependentes.numcad = FicBasica.numcad 
--	 AND dependentes.grapar = 3
--	 AND dependentes.tipsex = 'F'), '') AS [Mãe]
--
, case when FicBasica.codnac = 10 then 'Brasileira'
  else 'Outros'
  end																								as Nacionalidade
--
, cidades.NomCid																					as [Naturalidade Cidade]
--, coalesce(FicComplementar.ccinas, '') as [Naturalidade Cidade]
--, coalesce(FicComplementar.estnas, '') as [Naturalidade UF]
, coalesce(FicComplementar.numcid, '')																as RG
, case when FicComplementar.emicid is null 
	   or FicComplementar.emicid in ('', ' ') then 'SSP'	
	   else FicComplementar.emicid
  end 																								as [Órgão Expedidor]
--
, case when GraInstr.GraIns = 1 then '1'						-- sem escolaridade
	   when GraInstr.GraIns in(2, 3, 4) then '2'				-- fundamental incompleto
	   when GraInstr.GraIns = 5 then '3'						-- fundamental completo
	   when GraInstr.GraIns = 6 then '4'						-- ensino médio incompleto
	   when GraInstr.GraIns = 7 then '5'						-- ensino médio completo
	   when GraInstr.GraIns = 8 then '6'						-- ensino superior incompleto
	   when GraInstr.GraIns = 9 then '7'						-- ensino superior completo
	   when GraInstr.GraIns in(10, 11, 12, 13) then '8'			-- pós ou especialização completo
  end																								as [Grau de Instrução]
--
--, GraInstr.DesGra as [Grau de Instrução]
--, coalesce(deficiencia.DesDef, '') as [Deficiência]
, case when FicBasica.coddef = 1 then '2'
       when FicBasica.coddef = 2 then '1'
	   when FicBasica.coddef = 3 then '6'
	   when FicBasica.coddef = 4 then '3'
	   when FicBasica.coddef = 5 then '4'
	   when FicBasica.coddef = 0 then '5'
  end																								as [Deficiência]
--
, case when FicBasica.raccor in (0, 6, 7, 8) then '4' -- 'Não Informado'
	   when FicBasica.raccor = 1 then '2' -- 'Branca'
	   when FicBasica.raccor = 2 then '6' -- 'Preta'
	   when FicBasica.raccor = 3 then '1' -- 'Amarela'
	   when FicBasica.raccor = 4 then '5' -- 'Parda'
	   when FicBasica.raccor = 5 then '3' -- 'Indígena'
	   --when FicBasica.raccor = 6 then 'Mameluco'
	   --when FicBasica.raccor = 7 then 'Mulato'
	   --when FicBasica.raccor = 8 then 'Cafuzo'
  end																								as [Cor\Raça]
--
, case when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) = 0.00 then '7'
       when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) <= 0.5 then '1'

	   when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) > 0.5 
	   and cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) <= 1.00  then '2'

	   when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) > 1.00 
	   and cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) <= 3.00  then '3'

	   when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) > 3.00 
	   and cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) <= 5.00  then '4'

	   when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) > 5.00 
	   and cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) <= 10.00  then '5'

	   when cast((FicBasica.valsal + FicBasica.cplsal) / 954.00 as decimal(9,2)) > 10.00 then '6'
  end																								as [Renda Familiar]
--
, case when FicBasica.sitafa = 1 then '1' -- 'trabalando'
       when FicBasica.sitafa = 22 then '2' -- 'Aposentadoria'
	   else '1'
  end																								as [Situação Ocupacional]
--
--, situac.DesSit as [Situação]
, case when replace(coalesce(FicComplementar.numtel, ''), ' ', '') = '' 
       or FicComplementar.numtel is null then '35313000'
	   else replace(coalesce(FicComplementar.numtel, ''), ' ', '')
  end 																								as Fone
--
, coalesce(FicComplementar.codest, '')																as UF
, coalesce(FicComplementar.codcid, '')																as [Código IBGE Município]
, coalesce(FicComplementar.endrua, '')																as [Endereço]
, coalesce(FicComplementar.endnum, '')																as [Número]
--, FicComplementar.codbai
, coalesce(bairros.NomBai, '')																		as Bairro
, coalesce(FicComplementar.endcep, '')																as CEP

from rhcravil.r034fun  as FicBasica
left join rhcravil.r034cpl as FicComplementar 
  on FicComplementar.numemp = FicBasica.numemp 
  and FicComplementar.tipcol = FicBasica.tipcol 
  and FicComplementar.numcad = FicBasica.numcad 
left join rhcravil.R022GRA as GraInstr
  on FicBasica.grains = GraInstr.GraIns 
left join rhcravil.R022def deficiencia
  on  FicBasica.coddef = deficiencia.CodDef   
inner join rhcravil.R074BAI as bairros 
  on FicComplementar.codcid = bairros.CodCid
  and FicComplementar.codbai = bairros.CodBai	
inner join rhcravil.R010SIT as situac
  on FicBasica.sitafa = situac.CodSit
inner join rhcravil.R074CID as cidades
  on cidades.CodCid = FicComplementar.codcid

WHERE FicBasica.sitafa <> 7  
and FicBasica.datnas <> '1900-12-31'
and FicBasica.numcpf <> 0
and FicComplementar.numcid is not null		-- RG
and FicComplementar.numcid not in (' ','')  -- RG
and FicBasica.tipcol = 1					-- [1] empregado, [2] terceiro, [3] parceiro




