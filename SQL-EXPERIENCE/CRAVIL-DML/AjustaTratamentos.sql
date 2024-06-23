USE GesCooper90
GO
/***********VER SQL DO TICKET 18985************/

--select * from UnidadeMedidaSIGA AS t1
--WHERE t1.UniSIGANom LIKE '%l/ha%'
-----------------------------------------------------------------------------------------------------------
-- 1ª alteração
-----------------------------------------------------------------------------------------------------------
select 
t1.ProCod
, t1.CulCod
, t1.PrbCod
, t1.TraSIGATipoAplicacao
, t1.TraSIGACalda					-- ALTERAR PARA 1000
, t1.TraSIGACaldaMaxima				-- ALTERAR PARA 1200
, t1.TraSIGAProSit
, t1.TraSIGAUniSIGACod				-- ALTERAR PARA 1
from PROBTRATSIGA AS t1 
--INNER JOIN TECAPLICACAO AS t2
--ON t1.TraSIGATecAplicacao = t2.TecApliSequencial
where t1.TraSIGAProSit = 0  -- tratamentos ativos
-- condições solicitadas
AND t1.ProCod IN (24624, 44294, 15172)
AND t1.TraSIGACalda = 0				
-- 32 REGISTROS

BEGIN TRAN 
UPDATE dbo.PROBTRATSIGA
SET TraSIGACalda = 1000, TraSIGACaldaMaxima = 1200, TraSIGAUniSIGACod = 1
WHERE ProCod IN (24624, 44294, 15172)
AND TraSIGAProSit = 0
AND TraSIGACalda = 0

COMMIT TRAN


-----------------------------------------------------------------------------------------------------------
-- 2ª alteração
-----------------------------------------------------------------------------------------------------------
select 
t1.ProCod
, t1.CulCod
, t1.PrbCod
, t1.TraSIGATipoAplicacao
, t1.TraSIGACalda					-- ALTERAR PARA 500
, t1.TraSIGACaldaMaxima				-- ALTERAR PARA 1000
, t1.TraSIGAProSit
, t1.TraSIGAUniSIGACod				-- ALTERAR PARA 1
from PROBTRATSIGA AS t1 
WHERE t1.TraSIGAProSit = 0  -- tratamentos ativos
AND t1.ProCod IN (807 , 33002, 34188, 6842, 129350, 43493, 47234, 15172)
AND t1.TraSIGACalda = 0		
-- 261 REGISTROS

BEGIN TRAN 
UPDATE dbo.PROBTRATSIGA
SET TraSIGACalda = 500, TraSIGACaldaMaxima = 1000, TraSIGAUniSIGACod = 1
WHERE ProCod IN (807, 33002, 34188, 6842, 129350, 43493, 47234, 15172)
AND TraSIGAProSit = 0
AND TraSIGACalda = 0

COMMIT TRAN


-----------------------------------------------------------------------------------------------------------
-- 3ª alteração
-----------------------------------------------------------------------------------------------------------
select 
t1.ProCod
, t1.CulCod
, t1.PrbCod
, t1.TraSIGATipoAplicacao
, t1.TraSIGACalda					-- ALTERAR PARA 300
, t1.TraSIGACaldaMaxima				-- ALTERAR PARA 700
, t1.TraSIGAProSit
, t1.TraSIGAUniSIGACod				-- ALTERAR PARA 1
from PROBTRATSIGA AS t1 
WHERE t1.TraSIGAProSit = 0  -- tratamentos ativos
AND t1.ProCod IN (2247, 36971, 11639, 46649, 55955)
AND t1.TraSIGACalda = 0
-- 240 REGISTROS

BEGIN TRAN 
UPDATE dbo.PROBTRATSIGA
SET TraSIGACalda = 300, TraSIGACaldaMaxima = 700, TraSIGAUniSIGACod = 1
WHERE ProCod IN (2247, 36971, 11639, 46649, 55955)
AND TraSIGAProSit = 0
AND TraSIGACalda = 0

COMMIT TRAN


-----------------------------------------------------------------------------------------------------------
-- 4ª alteração
-----------------------------------------------------------------------------------------------------------
select 
t1.ProCod
, t1.CulCod
, t1.PrbCod
, t1.TraSIGATipoAplicacao
, t1.TraSIGACalda					-- ALTERAR PARA 200
, t1.TraSIGACaldaMaxima				-- ALTERAR PARA 300
, t1.TraSIGAProSit
, t1.TraSIGAUniSIGACod				-- ALTERAR PARA 1
from PROBTRATSIGA AS t1 
WHERE t1.TraSIGAProSit = 0  -- tratamentos ativos
AND t1.ProCod IN (2181, 15240)
-- 264 REGISTROS


BEGIN TRAN 
UPDATE dbo.PROBTRATSIGA
SET TraSIGACalda = 200, TraSIGACaldaMaxima = 300, TraSIGAUniSIGACod = 1
WHERE ProCod IN (2181, 15240)
AND TraSIGAProSit = 0

COMMIT TRAN


-----------------------------------------------------------------------------------------------------------
-- 5ª alteração
-----------------------------------------------------------------------------------------------------------
select 
t1.ProCod
, t1.CulCod
, t1.PrbCod
, t1.TraSIGATipoAplicacao
, t1.TraSIGACalda					
, t1.TraSIGACaldaMaxima				
, t1.TraSIGAProSit
, t1.TraSIGAUniSIGACod				
, t1.TraSIGAEpocaAplic		-- MUDAR TEXTO DA APLICAÇÃO
from PROBTRATSIGA AS t1 
WHERE t1.ProCod IN (12683, 11204)
-- 160 REGISTROS

BEGIN TRAN

UPDATE PROBTRATSIGA SET TraSIGAEpocaAplic = 
'
Adição de Adjuvante: Recomenda-se o acréscimo de Assist® na dose de 1,0 L/ha nas aplicações terrestres, e de 0,3 L/ha nas aplicações aéreas. NÚMERO, ÉPOCA E INTERVALO DE APLICAÇÃO: A aplicação de Basagran® 600 deve ser feita quando as plantas infestantes atingirem os estágios indicados. Passados esses estágios a eficiência se reduz ou desaparece. Normalmente uma única aplicação é indicada. Para a cultura de arroz, pode-se efetuar duas aplicação, com intervalo de 3 a 4 dias, dividindo-se a dose total, quando algumas infestantes já estão atingindo o estágio indicado, mas outras continuam emergindo.  No caso de Cyperáceas, o manejo permite que consigamos redução de alta dose devido à dificuldade de controle quando as ervas atingem estágios mais avançados. MODO DE APLICAÇÃO: Basagran® 600 deve ser diluído em água e aplicado por pulverização, em pós-emergência, sobre a folhagem das plantas infestantes. Efetuar uma boa distribuição do produto. Equipamentos de aplicação • Pulverizadores, motorizados ou acoplados, de barra, com bicos uniformes de um dos seguintes tipos: - jato em leque, 80.02, 80.03, 110.02, 110.03, APG 110 R (vermelho), APG 110 D (laranja), VisiFlo amarelo, VisiFIo azul, que produzem gotículas entre 300 e 400 micra e permitem uma deposição de cerca de 20 gotículas/cm2. - jato cônico, D2-13 ou D2-25, que produzem gotículas entre 120 e 150 micra e permitem uma deposição de 40 a 50 gotículas/cm2. Pressão entre 60 e 100 Iibras/pol2 (40 libras/pol2 no bico). A altura da barra deve ser tal que permita pequena sobreposição dos jatos dos diversos bicos, no topo das plantas infestantes. Volume de água: 250 litros/ha; estando a folhagem molhada por orvalho ou neblina, reduzir o volume de água para 150 litros/ha. INTERVALO DE SEGURANÇA: Feijão 35 dias Soja 90 dias Arroz e Trigo 60 dias Milho 110 dias.
'
WHERE ProCod IN (12683, 11204)

COMMIT


-----------------------------------------------------------------------------------------------------------
-- 6ª alteração
-----------------------------------------------------------------------------------------------------------
select 
t1.ProCod
, t1.CulCod
, t1.PrbCod
, t1.TraSIGATipoAplicacao
, t1.TraSIGACalda					
, t1.TraSIGACaldaMaxima				
, t1.TraSIGAProSit
, t1.TraSIGAUniSIGACod				
, t1.TraSIGAEpocaAplic		-- MUDAR TEXTO DA APLICAÇÃO
from PROBTRATSIGA AS t1 
WHERE t1.ProCod IN (11877, 11884)
-- 522 registros

begin tran

update PROBTRATSIGA set TraSIGAEpocaAplic = 'Tratar logo no início da infestação. Reaplicar se necessário. Pulverizadores terrestres: Costais manuais e tratorizados: Bicos: Recomenda-se a utilização de bicos de jato cônico vazio, que geram um melhor espectro de gotas finas.  Volume de aplicação: Recomenda-se utilizar de 80 a 200 L/ha. Costais motorizados: Bicos: Nestes equipamentos, pelo uso de bicos do tipo rotativos, manter sempre em operação a rotação do motor em aceleração total, permitindo um fluxo de vento bastante forte e alta rotação do bico rotativo gerando gotas finas.  Volume de aplicação: Volumes altos determinam um excesso de fluxo sobre os bicos, reduzindo sua eficiência e geração das gotas. Utilizar volumes de 10 a 20 litros de calda por hectare Pulverização com aeronaves agrícolas: Bicos: Utilizar bicos de jato cônico vazio da série D ou similar, com a combinação adequada de ponta e difusor (core) ou bicos rotativos tipo MICRONAIR, que permitam a geração e deposição de um mínimo de 40 gotas/cm2 com um DMV (VMD) de 110 a 150 micrômetros. Volume de aplicação: Nas aplicações com diluição do produto em água, utilizar vazões de 10 a 20 litros/ha.'
WHERE ProCod IN (11877, 11884)

commit tran