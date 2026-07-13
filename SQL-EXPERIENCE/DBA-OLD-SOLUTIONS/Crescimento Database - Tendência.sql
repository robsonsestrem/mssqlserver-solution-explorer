-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Linha de tend�ncia mostrar� aumento semanal das base de dados
-----------------------------------------------------------------------------------------------------------------------------------------------------------
declare  @decremento smallint
		,@limite smallint		
		,@dia datetime
IF(OBJECT_ID('tempdb.dbo.##semanas')IS NOT NULL) 
	BEGIN
		drop table ##semanas
	END
create table ##semanas
(
DatabaseName varchar(80),
DataReferencia date,
TotalSize_Gb varchar(30)
)
set @limite = (select DATEDIFF(WEEK, '2017-01-02', GETDATE()) * -1)  -- a data setada � a primerira registrada na rotina de coleta
set @decremento = 1

WHILE (@limite <= @decremento)
	BEGIN			
		set @dia = (select dateadd(WEEK,@decremento, cast(floor(cast(getdate() as float)) as datetime)	))

		INSERT INTO ##semanas
		SELECT 
		v.NmDatabase
		, v.DtReferencia
		, REPLACE(CAST(CAST(sum(v.NrTamanhoTotal /1024) AS MONEY) AS VARCHAR(20)),'.',',') as Tamanho
	    FROM YOUR_DATABASE.Management.vw_SizeTables as v 
	    WHERE v.DtReferencia = @dia	
		group by v.NmDatabase, v.DtReferencia		

		set @decremento = @decremento -1
	END
select 
s.DatabaseName
, convert(varchar(12),s.DataReferencia,103) as DateReference
, s.TotalSize_Gb
from ##semanas as s
order by s.DataReferencia

IF(OBJECT_ID('temdb.dbo.##semanas') IS NOT NULL)
	BEGIN
		drop table ##semanas
	END


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Para o PowerBI n�o ser� necess�rio colocar limites de data j� que ter� controle de massa de dados em uma Job
-- no caso dessas coletas ser�o preservados os dados de no m�ximo um ano.
-----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
v.NmDatabase as [Nome Database]
,v.DtReferencia [Data de Refer�ncia]
, cast(sum(v.NrTamanhoTotal / 1024) as decimal(9,2)) as Tamanho_Gb
FROM YOUR_DATABASE.Management.vw_SizeTables as v 
group by v.NmDatabase, v.DtReferencia