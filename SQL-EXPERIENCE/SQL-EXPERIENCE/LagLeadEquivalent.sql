-------------------------------------------------------------------------------------------------
-- https://sqlscope.wordpress.com/2014/05/26/lag-and-lead-for-sql-server-2008/
-------------------------------------------------------------------------------------------------
WITH balance_details
AS
(
SELECT * FROM (
VALUES
('Tom','20140101',100),
('Tom','20140102',120),
('Tom','20140103',150),
('Tom','20140104',140),
('Tom','20140105',160),
('Tom','20140106',180),
('Jerry','20140101',210),
('Jerry','20140102',240),
('Jerry','20140103',230),
('Jerry','20140104',270),
('Jerry','20140105',190),
('Jerry','20140106',200),
('David','20140101',170),
('David','20140102',230),
('David','20140103',240),
('David','20140104',210),
('David','20140105',160),
('David','20140106',200)
) AS t (customer, balancedate,balance)
),

balance_cte AS
(
SELECT
 ROW_NUMBER() OVER (PARTITION BY customer ORDER BY balancedate) rn
,(ROW_NUMBER() OVER (PARTITION BY customer ORDER BY balancedate))/2 rndiv2
,(ROW_NUMBER() OVER (PARTITION BY customer ORDER BY balancedate) + 1)/2 rnplus1div2

/*
,COUNT(*) OVER (PARTITION BY customer) partitioncount
*/
,customer
,balancedate
,balance
FROM balance_details
)

SELECT
rn
,rndiv2
,rnplus1div2
,customer,balancedate,balance
--
,CASE WHEN rn%2=1 
	THEN MAX(CASE WHEN rn%2=0 THEN balance END) OVER (PARTITION BY customer, rndiv2) 
	ELSE MAX(CASE WHEN rn%2=1 THEN balance END) OVER (PARTITION BY customer,rnplus1div2)
 END AS balance_lag
--
,CASE WHEN rn%2=1 
	THEN MAX(CASE WHEN rn%2=0 THEN balance END) OVER (PARTITION BY customer,rnplus1div2) 
	ELSE MAX(CASE WHEN rn%2=1 THEN balance END) OVER (PARTITION BY customer,rndiv2)
 END AS balance_lead

/*
,MAX(CASE WHEN rn=1 THEN balance END) OVER (PARTITION BY customer) AS first_value
,MAX(CASE WHEN rn=partitioncount THEN balance END) OVER (PARTITION BY customer) AS last_value
,MAX(CASE WHEN rn=4 THEN balance END) OVER (PARTITION BY customer) AS fourth_value
*/
FROM balance_cte
ORDER BY customer,balancedate



-- O código comentado mostra como obter o equivalente ao SQL 2012 FIRST_VALUE e LAST_VALUE. 
-- Também mostro como obter o valor Nth onde eu indiquei N como 4)
-- Em relação ao código LAG, ele depende do fato de que a divisão inteira por 2 do ROW_NUMBER pode ser usada na função de particionamento. 
-- Por exemplo, 2 e 3 div 2 dão 1. Quando a linha atual é 3 (ou seja, rn mod 2 é 1) 
-- examinamos as linhas da moldura da janela onde rndiv2 é 1 e escolhe o valor do saldo onde a linha do quadro é igual (ou seja, rn Mod 2 é 0). Ou seja, o valor para a linha 2. 
-- Quando a linha atual é 2 (ou seja, rn mod 2 é 0), examinamos as linhas da moldura da janela onde rnplus1div2 é 1 
-- e escolha o valor do saldo onde a linha do quadro é ímpar (ou seja, rn mod 2 is 1). Ou seja, o valor da linha 1.
-- Para LEAD, o priniciple é o mesmo, apenas usamos a expressão divisão por 2 oposta na cláusula de partição.




declare @testeLag table
(
nome varchar(50)
, dataRef datetime
, valor int
)
insert into @testeLag 
values('paulo', '2017-07-10', 100)
insert into @testeLag 
values('paulo', '2017-07-11', 220)
insert into @testeLag 
values('paulo', '2017-07-12', 333)
insert into @testeLag 
values('paulo', '2017-07-13', 444)
insert into @testeLag 
values('paulo', '2017-07-14 10:22:07.877', 110)
insert into @testeLag 
values('paulo', '2017-07-15', 880)
insert into @testeLag 
values('paulo', '2017-07-16', 560)
insert into @testeLag 
values('paulo', '2017-07-17', 560)


;with origem
as
(
select t.nome, t.dataRef, t.valor, (select MAX(dataRef) from @testeLag) as LastDate, max(dataRef) as LastDate2 from @testeLag as t group by t.nome, t.dataRef, t.valor
)
, calculaOrigem
as
	(
	select
	o.nome
	, o.dataRef
	, o.valor
	, o.LastDate
	, o.LastDate2
	, ROW_NUMBER() OVER (PARTITION BY o.nome order by o.dataRef)		AS rn
	, (ROW_NUMBER() OVER (PARTITION BY o.nome order by o.dataRef)) /2	AS rndiv2
	, (ROW_NUMBER() OVER (PARTITION BY o.nome order by o.dataRef)+1) /2 AS rnMais1Div2
	from origem as o
	)

-- agora trata os resultados
select
c.rn, c.rndiv2, c.rnMais1Div2
, c.nome, c.dataRef, c.valor
, CASE WHEN c.rn % 2 = 1
	THEN MAX(CASE WHEN rn%2=0 THEN c.valor END) OVER (PARTITION BY c.nome, c.rndiv2) 
	ELSE MAX(CASE WHEN rn%2=1 THEN c.valor END) OVER (PARTITION BY c.nome, c.rnMais1Div2)
  END AS LAG
, CASE WHEN c.rn % 2 = 1 
	THEN MAX(CASE WHEN rn%2=0 THEN c.valor END) OVER (PARTITION BY c.nome, c.rnMais1Div2) 
	ELSE MAX(CASE WHEN rn%2=1 THEN c.valor END) OVER (PARTITION BY c.nome, c.rndiv2)
  END AS LEAD
, (select valor from calculaOrigem where dataRef = DATEADD(DAY, -5, c.LastDate)) as DiasAtrasLastDate
, (select valor from calculaOrigem where dataRef = DATEADD(DAY, -5, c.LastDate2)) as DiasAtrasLastDate2
, c.LastDate
, c.LastDate2

from calculaOrigem as c