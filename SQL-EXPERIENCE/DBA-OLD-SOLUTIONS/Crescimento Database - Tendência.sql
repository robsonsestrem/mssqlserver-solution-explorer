-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Linha de tendência mostrará aumento semanal das base de dados
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
set @limite = (select DATEDIFF(WEEK, '2017-01-02', GETDATE()) * -1)  -- a data setada é a primerira registrada na rotina de coleta
set @decremento = 1

WHILE (@limite <= @decremento)
	BEGIN			
		set @dia = (select dateadd(WEEK,@decremento, cast(floor(cast(getdate() as float)) as datetime)	))

		INSERT INTO ##semanas
		SELECT 
		v.NmDatabase
		, v.DtReferencia
		, REPLACE(CAST(CAST(sum(v.NrTamanhoTotal /1024) AS MONEY) AS VARCHAR(20)),'.',',') as Tamanho
	    FROM Maintenance.Management.vw_SizeTables as v 
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
-- Para o PowerBI não será necessário colocar limites de data já que terá controle de massa de dados em uma Job
-- no caso dessas coletas serão preservados os dados de no máximo um ano.
-----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
v.NmDatabase as [Nome Database]
,v.DtReferencia [Data de Referência]
, cast(sum(v.NrTamanhoTotal / 1024) as decimal(9,2)) as Tamanho_Gb
FROM Maintenance.Management.vw_SizeTables as v 
group by v.NmDatabase, v.DtReferencia