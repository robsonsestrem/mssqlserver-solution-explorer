use IntegraTICravil
go

--execute Erp.sp_ReportLayoutSecoop

create or alter procedure Erp.sp_ReportLayoutSecoop
(
	@ExibirApenasHtml BIT = 0
)
as
begin 
	DECLARE @vSubject NVARCHAR(255) = 'Relação de dados RH CRAVIL'
	DECLARE @vBody AS NVARCHAR(MAX) = '';
	DECLARE @Query NVARCHAR(max);
	DECLARE @tab char(1) = CHAR(9);

	if(OBJECT_ID('tempdb..##dadosRHsescoop') is not null)
		drop table ##dadosRHsescoop

	create table ##dadosRHsescoop
	(
	 cpf bigint
	 , nome varchar(max)
	 , cracha varchar(max)
	 , email varchar(max)
	 , sexo varchar(3)
	 , datanasc varchar(max)
	 , estadoCivil varchar(3)
	 , nacionalidade varchar(max)
	 , naturalidade varchar(max)
	 , rg varchar(max)
	 , orgao varchar(20)
	 , grauInstru varchar(3)
	 , deficiencia varchar(max)
	 , cor varchar(10)
	 , renda varchar(10)
	 , situacao varchar(10)
	 , fone varchar(max)
	 , uf varchar(4)
	 , ibge int
	 , endereco varchar(max)
	 , numero varchar(max)
	 , bairro varchar(max)
	 , cep int
	)

	insert into ##dadosRHsescoop
	select 
	  FicBasica.numcpf																					
	, FicBasica.nomfun																					
	, left(FicBasica.nomfun, charindex(' ', FicBasica.nomfun))								
	, case when FicComplementar.emapar is null 
		   or replace(coalesce(FicComplementar.emapar, ''), ' ', '') = ''
		   then 'rh@cravil.com.br'
		   else coalesce(FicComplementar.emapar, '')
	  end 																								
	, case when FicBasica.tipsex = 'M' then '1'
		   when FicBasica.tipsex = 'F' then '2'
	  end																								
	, convert(varchar(20), FicBasica.datnas, 103)															
	, coalesce(case when FicBasica.estciv in(1, 9) then '4'           
		   when FicBasica.estciv = 2 then '1'		               
		   when FicBasica.estciv = 3 then '3'						
		   when FicBasica.estciv = 4 then '6'							  
		   when FicBasica.estciv = 6 then '2'						 
		   when FicBasica.estciv in(7, 5) then '5'				 		  
	  end, '')																								
	, case when FicBasica.codnac = 10 then 'Brasileira'
	  else 'Outros'
	  end																					
	, cidades.NomCid																						
	, coalesce(FicComplementar.numcid, '')															
	, case when FicComplementar.emicid is null 
		   or FicComplementar.emicid in ('', ' ') then 'SSP'	
		   else FicComplementar.emicid
	  end 																									
	, case when GraInstr.GraIns = 1 then '1'						
		   when GraInstr.GraIns in(2, 3, 4) then '2'				
		   when GraInstr.GraIns = 5 then '3'						
		   when GraInstr.GraIns = 6 then '4'						
		   when GraInstr.GraIns = 7 then '5'						
		   when GraInstr.GraIns = 8 then '6'						
		   when GraInstr.GraIns = 9 then '7'						
		   when GraInstr.GraIns in(10, 11, 12, 13) then '8'			
	  end																								
	, case when FicBasica.coddef = 1 then '2'
		   when FicBasica.coddef = 2 then '1'
		   when FicBasica.coddef = 3 then '6'
		   when FicBasica.coddef = 4 then '3'
		   when FicBasica.coddef = 5 then '4'
		   when FicBasica.coddef = 0 then '5'
	  end																								
	, case when FicBasica.raccor in (0, 6, 7, 8) then '4' 
		   when FicBasica.raccor = 1 then '2' 
		   when FicBasica.raccor = 2 then '6'
		   when FicBasica.raccor = 3 then '1' 
		   when FicBasica.raccor = 4 then '5' 
		   when FicBasica.raccor = 5 then '3' 	  
	  end																								
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
	  end																							
	, case when FicBasica.sitafa = 1 then '1' 
		   when FicBasica.sitafa = 22 then '2' 
		   else '1'
	  end																								
	, case when replace(coalesce(FicComplementar.numtel, ''), ' ', '') = '' 
		   or FicComplementar.numtel is null then '35313000'
		   else replace(coalesce(FicComplementar.numtel, ''), ' ', '')
	  end 																							
	, coalesce(FicComplementar.codest, '')																
	, coalesce(FicComplementar.codcid, '')																
	, coalesce(FicComplementar.endrua, '')																
	, coalesce(FicComplementar.endnum, '')																
	, coalesce(bairros.NomBai, '')																		
	, coalesce(FicComplementar.endcep, '')																

	from rhcravil.rhcravil.r034fun  as FicBasica
	left join rhcravil.rhcravil.r034cpl as FicComplementar 
	  on FicComplementar.numemp = FicBasica.numemp 
	  and FicComplementar.tipcol = FicBasica.tipcol 
	  and FicComplementar.numcad = FicBasica.numcad 
	left join rhcravil.rhcravil.R022GRA as GraInstr
	  on FicBasica.grains = GraInstr.GraIns 
	left join rhcravil.rhcravil.R022def deficiencia
	  on  FicBasica.coddef = deficiencia.CodDef   
	inner join rhcravil.rhcravil.R074BAI as bairros 
	  on FicComplementar.codcid = bairros.CodCid
	  and FicComplementar.codbai = bairros.CodBai	
	inner join rhcravil.rhcravil.R010SIT as situac
	  on FicBasica.sitafa = situac.CodSit
	inner join rhcravil.rhcravil.R074CID as cidades
	  on cidades.CodCid = FicComplementar.codcid

	WHERE FicBasica.sitafa <> 7  
	and FicBasica.datnas <> '1900-12-31'
	and FicBasica.numcpf <> 0
	and FicComplementar.numcid is not null		
	and FicComplementar.numcid not in (' ','')  
	and FicBasica.tipcol = 1	
	

	SET @vBody = '<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
														<tr height=20  style=color:black;>
															<td width=300 style=height:20.0pt>Anexo dados para exportação do cadastro de participantes SESCOOP.																																								
																							<br>Data de Extração: '+CONVERT(VARCHAR(12),GETDATE(),103)+'																						
															</td>
														</tr>
														</table>
														<br><br>								
										 '		

	set @Query = 
	'
	set nocount on;	

	select 
	t1.cpf, t1.nome, t1.cracha, t1.email, t1.sexo, t1.datanasc, t1.estadoCivil, t1.nacionalidade, t1.naturalidade, t1.rg, t1.orgao, t1.grauInstru, t1.deficiencia
	, t1.cor, t1.renda, t1.situacao, t1.fone, t1.uf, t1.ibge, t1.endereco, t1.numero, t1.bairro, t1.cep
	from ##dadosRHsescoop as t1		
	'
									IF @ExibirApenasHtml = 0
									   begin
										EXEC msdb.dbo.sp_send_dbmail
												@profile_name =		'CRAVIL',
												@recipients =		'suporte@cravil.com.br', 								
												@subject =			@vSubject,
												@body =				@vBody,
												@body_format =		'HTML',

												@query	= @Query,
												@attach_query_result_as_file = 1
												,@query_attachment_filename ='ColaboradoresCravil.csv'
												,@query_result_header = 0		-- 0 fica sem coluna
												,@query_result_separator= @tab	-- enforce csv
												,@query_result_no_padding= 1	-- trim
												,@query_result_width = 32767	-- stop wordwrap
									    end
									-- *** Exibe como HTML ao invés de enviar por e-mail
									ELSE 
									SELECT @vBody;
end