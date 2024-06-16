------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- *************** Solicitado através do Ticket nº 15876 ***************
-- PARA TODO FILTRO DE DATA DE APURAÇÃO SE DEVE PASSAR PELO MENOS UMA DATA DE MESMO MÊS NOS FILTROS DE DATA BASE E DATAS DE ALTERAÇÃO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
use rhcravil
go
declare @dataAlteracao		datetime
		, @dataBaseInicio	datetime
		, @dataBaseFim		datetime
		, @inicioApuracao	datetime
		, @fimApuracao		datetime

set @inicioApuracao = '20170705'
set @fimApuracao	= '20170905'
set @dataBaseInicio = @inicioApuracao
set @dataBaseFim	= @fimApuracao
set @dataAlteracao	= @inicioApuracao

SELECT 
  R038HCC.CODCCU Cod_CC		-- código centro de custo 
, R018CCU.NOMCCU Nome_CC	-- nome de centro de custo 
, R010SIT.DesSit			-- 68 situações distintas
, sum(R066SIT.QTDHOR) as TempoTotalMinutos

FROM 
rhcravil.R034FUN,  -- ficha básica colaborador
rhcravil.R010SIT,  -- cadastro de situações 
rhcravil.R016HIE,  -- tabela dos organogramas 
rhcravil.R016ORN,  -- locais do organograma
rhcravil.R038HFI,  -- histórico filial
rhcravil.R030FIL,  -- filiais da empresa
rhcravil.R038HCA,  -- histórico cargos
rhcravil.R024CAR,  -- cargos
rhcravil.R038HCC,  -- histórico centro de custo
rhcravil.R018CCU,  -- centro de custo
rhcravil.R038HES,  -- histórico escalas
rhcravil.R006ESC,  -- escalas
rhcravil.R066SIT,  -- situações apuração colaborador
rhcravil.R038HLO   -- histórico local

WHERE R010SIT.CODSIT = R066SIT.CODSIT 
--
AND R016HIE.TABORG = R016ORN.TABORG 
AND R016HIE.NUMLOC = R016ORN.NUMLOC 
--
AND R016ORN.TABORG = R038HLO.TABORG 
AND R016ORN.NUMLOC = R038HLO.NUMLOC 
--
AND R038HLO.NUMEMP = R034FUN.NUMEMP 
AND R038HLO.TIPCOL = R034FUN.TIPCOL 
AND R038HLO.NUMCAD = R034FUN.NUMCAD 

AND R030FIL.NUMEMP = R038HFI.NUMEMP 
AND R030FIL.CODFIL = R038HFI.CODFIL 
--
AND R024CAR.ESTCAR = R038HCA.ESTCAR
AND R024CAR.CODCAR = R038HCA.CODCAR 
--
AND R018CCU.NUMEMP = R038HCC.NUMEMP 
AND R018CCU.CODCCU = R038HCC.CODCCU 
--
AND R006ESC.CODESC = R038HES.CODESC 
--
AND R066SIT.NUMEMP = R034FUN.NUMEMP 
AND R066SIT.TIPCOL = R034FUN.TIPCOL 
AND R066SIT.NUMCAD = R034FUN.NUMCAD 
--
AND R038HFI.NUMEMP = R034FUN.NUMEMP 
AND R038HFI.TIPCOL = R034FUN.TIPCOL 
AND R038HFI.NUMCAD = R034FUN.NUMCAD 
--
AND R038HCA.NUMEMP = R034FUN.NUMEMP 
AND R038HCA.TIPCOL = R034FUN.TIPCOL 
AND R038HCA.NUMCAD = R034FUN.NUMCAD 
--
AND R038HCC.NUMEMP = R034FUN.NUMEMP 
AND R038HCC.TIPCOL = R034FUN.TIPCOL 
AND R038HCC.NUMCAD = R034FUN.NUMCAD
-- 
AND R038HES.NUMEMP = R034FUN.NUMEMP 
AND R038HES.TIPCOL = R034FUN.TIPCOL 
AND R038HES.NUMCAD = R034FUN.NUMCAD 

-- Condições de data base para extração

-- última data de alterações de alguma coisa 
AND	R038HFI.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HFI TABELA001 
					   WHERE TABELA001.NUMEMP = R038HFI.NUMEMP
					   AND TABELA001.TIPCOL = R038HFI.TIPCOL
					   AND TABELA001.NUMCAD = R038HFI.NUMCAD
					   AND TABELA001.DATALT <= @dataAlteracao)
 
AND R038HCA.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HCA TABELA002 
					   WHERE TABELA002.NUMEMP = R038HCA.NUMEMP
					   AND TABELA002.TIPCOL = R038HCA.TIPCOL
					   AND TABELA002.NUMCAD = R038HCA.NUMCAD
					   AND TABELA002.DATALT <= @dataAlteracao)

AND R038HCC.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HCC TABELA003 
					   WHERE TABELA003.NUMEMP = R038HCC.NUMEMP
					   AND TABELA003.TIPCOL = R038HCC.TIPCOL
					   AND TABELA003.NUMCAD = R038HCC.NUMCAD 
					   AND TABELA003.DATALT <= @dataAlteracao)
AND R038HES.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HES TABELA004 
					   WHERE TABELA004.NUMEMP = R038HES.NUMEMP
					   AND TABELA004.TIPCOL = R038HES.TIPCOL
					   AND TABELA004.NUMCAD = R038HES.NUMCAD
					   AND TABELA004.DATALT <= @dataAlteracao)

AND R038HLO.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HLO TABELA005 
					   WHERE TABELA005.NUMEMP = R038HLO.NUMEMP
					   AND TABELA005.TIPCOL = R038HLO.TIPCOL
					   AND TABELA005.NUMCAD = R038HLO.NUMCAD
					   AND TABELA005.DATALT <= @dataAlteracao) 
-- Condicionais/Filtros 
and R066SIT.NumEmp = 1	-- codigo empresa
AND R034FUN.NUMEMP = 1  -- codigo empresa
AND R038HES.NUMEMP = 1  -- codigo empresa
AND R066SIT.TIPCOL = 1  -- tipo colaborador(1 = empregado; 2 = terceiro; 3 = parceiro);
and R034FUN.TIPCOL = 1  -- tipo colaborador(1 = empregado; 2 = terceiro; 3 = parceiro); 
AND R016HIE.DATINI <= @dataBaseInicio
AND ((R016HIE.DATFIM >= @dataBaseFim) OR (R016HIE.DATFIM = '19001231')) 

and  R066SIT.DatApu >= @inicioApuracao and R066SIT.DatApu <= @fimApuracao	-- datas de apuração
and R038HCC.CODCCU = 1010101	-- centro de custo
--AND R034FUN.NUMCAD = 74779	-- código funcionoário
--AND R066SIT.CODSIT = 1		-- código da situação (trabalhando)

group by R038HCC.CODCCU, R018CCU.NOMCCU, R010SIT.DesSit

ORDER BY R018CCU.NOMCCU


--select 
-- cast(( 12701 / 60) as varchar) +':'+ cast(( 12701 % 60)/100 as varchar) as [hhh:mm]
--, (select replace(right(convert(varchar(25), dateadd(ss,  (12701*60), cast('20181231' as datetime)),  20), 11), ' ', ':')) as [dd hh:mm:ss]



/************************************************* EXTRAÇÃO COMPLETADA PELO CUBO *************************************************/

--SET DATEFORMAT DMY

--SELECT 
----  R034FUN.NUMCAD Cod_Colaborador -- código colaborador 
----, R034FUN.NOMFUN Nome_Colaborador  --nome fúncionário 
----, R066SIT.CODSIT Cod_Situacao  --código da situação
----, R010SIT.DESSIT Nome_Situacao  --descrição da situação
----, R034FUN.TIPCOL Tipo_Colaborador  -- tipo colaborador(1 = empregado; 2 = terceiro; 3 = parceiro);
----, R034FUN.SITAFA Situacao_Afastamento  -- situação de afastamento
----, R034FUN.TIPSEX Sexo  --sexo do funcionário   
----, R034FUN.DATADM Admissao  -- data admissão do funcionário 
----, R006ESC.CODESC Cod_Escala  --código escala 
----, R006ESC.NOMESC Periodo_Escala  --nome da escala 
----, R024CAR.ESTCAR Cod_EstruturaCargos  -- código da estrutura de cargos
----, R024CAR.CODCAR Cod_Cargo  -- código do cargo 
----, R024CAR.TITRED Nome_Cargo  -- títulos reduzido do cargo
--  R038HCC.CODCCU Cod_CC  -- código centro de custo 
--, R018CCU.NOMCCU Nome_CC  -- nome de centro de custo 
--, sum(R066SIT.QTDHOR) as TotalTrabalhado
----, (R066SIT.QTDHOR) as tota
----, R038HFI.CODFIL Cod_Filial  -- código da filial 
----, R034FUN.NUMEMP Cod_Empresa  -- codigo empresa 
----, R030FIL.RAZSOC Razao_Social   -- razão social     
----, R006ESC.HORMES HoraMes  -- horas do mes (hhh:mm) 
----, R006ESC.HORDSR Horadsr  -- total de horas de descanso 
----, R066SIT.QTDHOR Qtdade_Horas   -- quantidade de horas apuradas p/ situação (hhh:mm)
----, sum(R066SIT.QTDHOR) over (PARTITION by R018CCU.NOMCCU) as TotalTrabalhado
----, IntegraTICravil.Management.fn_IntToTime( sum(R066SIT.QTDHOR) over (PARTITION by R018CCU.NOMCCU)) as TotalFormatado
----, r070acc.datacc Data_Acesso -- data do acesso (dd/mm/yyyy)
----, r070acc.horacc Hora_Acesso -- hora do acesso (hh:mm) dados em minutos, é quando bate o ponto
----, r070acc.oriacc Origem_Marcacao -- origem da marcação:E = eletronica; D = Digitada; G = Gerada; R = Regularizada; I = Inserida pela regra; W = inserida via webservice acesso
----, r070acc.usomar Uso_Marcacao -- Uso da marcação: 22 opções
----, r070acc.diracc EntradaSaida -- direção do acesso: E = entrada; S = saída; N = Não identificada

--FROM 
--rhcravil.R034FUN,  -- ficha básica colaborador
--rhcravil.R010SIT,  -- cadastro de situações 
--rhcravil.R016HIE,  -- tabela dos organogramas 
--rhcravil.R016ORN,  -- locais do organograma
--rhcravil.R038HFI,  -- histórico filial
--rhcravil.R030FIL,  -- filiais da empresa
--rhcravil.R038HCA,  -- histórico cargos
--rhcravil.R024CAR,  -- cargos
--rhcravil.R038HCC,  -- histórico centro de custo
--rhcravil.R018CCU,  -- centro de custo
--rhcravil.R038HES,  -- histórico escalas
--rhcravil.R006ESC,  -- escalas
--rhcravil.R066SIT,  -- situações apuração colaborador
--rhcravil.R038HLO   -- histórico local
----
----rhcravil.r070acc   registro de acesso - com esta tabela no relacionamento traz mais 
---- registros por dia para cada funcionário
----
--WHERE R010SIT.CODSIT = R066SIT.CODSIT 
----
--AND R016HIE.TABORG = R016ORN.TABORG 
--AND R016HIE.NUMLOC = R016ORN.NUMLOC 
----
--AND R016ORN.TABORG = R038HLO.TABORG 
--AND R016ORN.NUMLOC = R038HLO.NUMLOC 
----
--AND R038HLO.NUMEMP = R034FUN.NUMEMP 
--AND R038HLO.TIPCOL = R034FUN.TIPCOL 
--AND R038HLO.NUMCAD = R034FUN.NUMCAD 

--AND R030FIL.NUMEMP = R038HFI.NUMEMP 
--AND R030FIL.CODFIL = R038HFI.CODFIL 
----
--AND R024CAR.ESTCAR = R038HCA.ESTCAR
--AND R024CAR.CODCAR = R038HCA.CODCAR 
----
--AND R018CCU.NUMEMP = R038HCC.NUMEMP 
--AND R018CCU.CODCCU = R038HCC.CODCCU 
----
--AND R006ESC.CODESC = R038HES.CODESC 
----
--AND R066SIT.NUMEMP = R034FUN.NUMEMP 
--AND R066SIT.TIPCOL = R034FUN.TIPCOL 
--AND R066SIT.NUMCAD = R034FUN.NUMCAD 
----
--AND R038HFI.NUMEMP = R034FUN.NUMEMP 
--AND R038HFI.TIPCOL = R034FUN.TIPCOL 
--AND R038HFI.NUMCAD = R034FUN.NUMCAD 
----
--AND R038HCA.NUMEMP = R034FUN.NUMEMP 
--AND R038HCA.TIPCOL = R034FUN.TIPCOL 
--AND R038HCA.NUMCAD = R034FUN.NUMCAD 
----
--AND R038HCC.NUMEMP = R034FUN.NUMEMP 
--AND R038HCC.TIPCOL = R034FUN.TIPCOL 
--AND R038HCC.NUMCAD = R034FUN.NUMCAD
---- 
--AND R038HES.NUMEMP = R034FUN.NUMEMP 
--AND R038HES.TIPCOL = R034FUN.TIPCOL 
--AND R038HES.NUMCAD = R034FUN.NUMCAD 
--/*
--and r070acc.datapu = R066SIT.DatApu
--and r070acc.numemp = R034FUN.NUMEMP 
--AND r070acc.tipcol = R034FUN.TIPCOL 
--AND r070acc.numcad = R034FUN.NUMCAD 
--*/
---- Condições de data base para extração

---- última data de alteração da filial 
--AND	R038HFI.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HFI TABELA001 
--					   WHERE TABELA001.NUMEMP = R038HFI.NUMEMP
--					   AND TABELA001.TIPCOL = R038HFI.TIPCOL
--					   AND TABELA001.NUMCAD = R038HFI.NUMCAD
--					   AND TABELA001.DATALT <= '01/09/2017')
 
--AND R038HCA.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HCA TABELA002 
--					   WHERE TABELA002.NUMEMP = R038HCA.NUMEMP
--					   AND TABELA002.TIPCOL = R038HCA.TIPCOL
--					   AND TABELA002.NUMCAD = R038HCA.NUMCAD
--					   AND TABELA002.DATALT <= '01/09/2017')

--AND R038HCC.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HCC TABELA003 
--					   WHERE TABELA003.NUMEMP = R038HCC.NUMEMP
--					   AND TABELA003.TIPCOL = R038HCC.TIPCOL
--					   AND TABELA003.NUMCAD = R038HCC.NUMCAD 
--					   AND TABELA003.DATALT <= '01/09/2017')
--AND R038HES.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HES TABELA004 
--					   WHERE TABELA004.NUMEMP = R038HES.NUMEMP
--					   AND TABELA004.TIPCOL = R038HES.TIPCOL
--					   AND TABELA004.NUMCAD = R038HES.NUMCAD
--					   AND TABELA004.DATALT <= '01/09/2017')

--AND R038HLO.DATALT = (SELECT MAX (DATALT) FROM rhcravil.R038HLO TABELA005 
--					   WHERE TABELA005.NUMEMP = R038HLO.NUMEMP
--					   AND TABELA005.TIPCOL = R038HLO.TIPCOL
--					   AND TABELA005.NUMCAD = R038HLO.NUMCAD
--					   AND TABELA005.DATALT <= '01/09/2017') 
---- Condicionais/Filtros 
--/*
--AND r070acc.usomar IN ( 2, 4, 5, 6, 7, 8, 10, 12, 13, 14, 15, 18, 20, 21, 22 )	-- tipo de marcação
--AND r070acc.datapu >= '05/09/2017' 
--AND r070acc.datapu <= 
--*/
--and R066SIT.NumEmp = 1	-- codigo empresa
--AND R034FUN.NUMEMP = 1  -- codigo empresa
--AND R038HES.NUMEMP = 1  -- codigo empresa
--AND R066SIT.TIPCOL = 1  -- tipo colaborador(1 = empregado; 2 = terceiro; 3 = parceiro);
--AND R066SIT.CODSIT = 1  -- código da situação (trabalhando)
--and R034FUN.TIPCOL = 1  -- tipo colaborador(1 = empregado; 2 = terceiro; 3 = parceiro); 
--AND R016HIE.DATINI <= '01/09/2017'
--AND ((R016HIE.DATFIM >= '01/09/2017') OR (R016HIE.DATFIM = '31/12/1900')) 
--and  R066SIT.DatApu >= '05/09/2017' and R066SIT.DatApu <= '05/09/2017'	-- datas de apuração
--and R038HCC.CODCCU = 1010101	-- centro de custo
----AND R034FUN.NUMCAD = 74779	-- código funcionoário

--group by R038HCC.CODCCU, R018CCU.NOMCCU

--ORDER BY R018CCU.NOMCCU