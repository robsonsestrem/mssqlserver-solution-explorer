use rhcravil
go

select 
FicBasica.codcar																					as [Código Cargo]
, FicBasica.datadm																				    as [Admissão]
, FicBasica.numcpf																					as CPF
, FicBasica.nomfun																					as Nome
, FicBasica.numcra																					as [Nº Crachá]
, left(FicBasica.nomfun,charindex(' ', FicBasica.nomfun))											as [Crachá]
, FicBasica.tipsex																					as Sexo
, convert(varchar(20), FicBasica.datnas, 103)														as [Data Nascimento]
--
--, coalesce(case when FicBasica.estciv in(1, 9) then '4'           --'Solteiro'
--       when FicBasica.estciv = 2 then '1'		                  -- 'Casado'
--	   when FicBasica.estciv = 3 then '3'						  -- 'Divorciado'
--	   when FicBasica.estciv = 4 then '6'						  -- 'Viúvo'
--	   --when FicBasica.estciv = 5 then 'Concubinato'
--	   when FicBasica.estciv = 6 then '2'						  -- 'Separado'
--	   when FicBasica. in(7, 5) then '5'					  -- 'União Estável'	  
--	   --when FicBasica.estciv = 9 then 'Outros'
--  end, '')																							as [Estado Civil]
--
, coalesce((SELECT TOP 1  dependentes.nomdep FROM rhcravil.r036dep AS dependentes
	 WHERE  dependentes.numemp = FicBasica.numemp 
	 AND dependentes.tipcol = FicBasica.tipcol 
	 AND dependentes.numcad = FicBasica.numcad 
	 AND dependentes.grapar = 3
	 AND dependentes.tipsex = 'M'), '') AS Pai
--
, coalesce((SELECT TOP 1 dependentes.nomdep FROM rhcravil.r036dep AS dependentes
	WHERE dependentes.numemp = FicBasica.numemp 
	 AND dependentes.tipcol = FicBasica.tipcol 
	 AND dependentes.numcad = FicBasica.numcad 
	 AND dependentes.grapar = 3
	 AND dependentes.tipsex = 'F'), '') AS [Mãe]
, coalesce(FicComplementar.numcid, '')																as RG
--
, case when FicComplementar.emicid is null 
	   or FicComplementar.emicid in ('', ' ') then 'SSP'	
	   else FicComplementar.emicid
  end 																								as [Órgão Expedidor]
--
, GraInstr.GraIns																					as [Código Grau_Instrução]
, GraInstr.DesGra																					as [Descrição Grau_Instrução]

, FicBasica.coddef																					as [Código Deficiência]
--
, coalesce(deficiencia.DesDef, '')																	as [Descrição Deficiência]
, case 
	   when FicBasica.raccor = 1 then 'Branca' 
	   when FicBasica.raccor = 2 then 'Preta'
	   when FicBasica.raccor = 3 then 'Amarela' 
	   when FicBasica.raccor = 4 then 'Parda'
	   when FicBasica.raccor = 5 then 'Indígena'
	   when FicBasica.raccor = 6 then 'Mameluco'
	   when FicBasica.raccor = 7 then 'Mulato'
	   when FicBasica.raccor = 8 then 'Cafuzo'
	   else 'Não Informado'
  end																								as [Cor\Raça]
, FicBasica.cplsal																					as [Complemento Salarial]
, FicBasica.valsal																					as [Salário Bruto]
, situac.DesSit																						as [Situação Ocupacional]
--
, case when replace(coalesce(FicComplementar.numtel, ''), ' ', '') = '' 
       or FicComplementar.numtel is null then '35313000'
	   else replace(coalesce(FicComplementar.numtel, ''), ' ', '')
  end 																								as Fone
--
--
, case when FicBasica.codnac = 10 then 'Brasileira'
  else 'Outros'
  end																								as Nacionalidade
--
, coalesce(FicComplementar.codest, '')																as UF
, coalesce(FicComplementar.codcid, '')																as [Código IBGE Município]
, coalesce(FicComplementar.ccinas, '')																as [Código Cidade]
, cidades.NomCid																					as [Cidade]
, coalesce(FicComplementar.endcep, '')																as CEP
, FicComplementar.codbai																			as [Código Bairro]
, coalesce(bairros.NomBai, '')																		as Bairro
, coalesce(FicComplementar.endrua, '')																as [Endereço]
, coalesce(FicComplementar.endnum, '')																as [Número]

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

WHERE 
--FicBasica.sitafa <> 7  
FicBasica.datnas <> '1900-12-31'
and FicBasica.numcpf <> 0
and FicComplementar.numcid is not null		-- RG
and FicComplementar.numcid not in (' ','')  -- RG
and FicBasica.tipcol = 1					-- [1] empregado, [2] terceiro, [3] parceiro
--and FicBasica.numcpf = 04980134998
and FicBasica.nomfun like '%robson sestrem%'
--and FicBasica.numcra = 88369



