---------------------------------------------------------------------------------------------------------------------------------------------
-- Crescimento do dia � dia das tabelas (top 100)
---------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO

select top 100			
			B2.NmServidor, 
			A2.NmDrive, 
			C2.NmDatabase,
			D2.NmTabela,				 
(SELECT Management.fn_FormatIntToMoney(A2.NrTamanhoDados / 1024))	as TamDadosAtual_Gb,
(SELECT Management.fn_FormatIntToMoney(A2.NrTamanhoTotal / 1024))	as TamAlocado_Gb,
(SELECT Management.fn_FormatIntToMoney(A2.NrTamanhoIndice))			as NrTamanhoIndice_Mb, 
(A2.NrTamanhoDados - A.NrTamanhoDados)								as DifTamDados_Mb,
convert(varchar(20),A2.DtReferencia,3) as DataAtual,			
(select Management.fn_FormatIntToThousands(A2.QtLinhas, 2))			as Qt_LinhasAtual,
(select Management.fn_FormatIntToThousands(A.QtLinhas, 2))			as Qt_LinhasDiaAnterior,
convert(varchar(20), A.DtReferencia,3) as DataAnterior
	from Management.HistorySizeTables as A inner join Management.InstanceServer as B 
			on A.IdServidor = B.IdServidor inner join Management.InstanceDatabases as C 
				on A.IdBaseDados = C.IdBaseDados inner join Management.InstanceTables as D 
					on A.IdTabela = D.IdTabela inner join Management.HistorySizeTables as A2 
						on A2.IdServidor = A.IdServidor
						and A2.IdBaseDados = A.IdBaseDados
						and A2.IdTabela = A.IdTabela inner join Management.InstanceServer as B2
							on A2.IdServidor = B2.IdServidor inner join Management.InstanceDatabases as C2
								on A2.IdBaseDados = C2.IdBaseDados inner join Management.InstanceTables as D2
									on A2.IdTabela = D2.IdTabela
where A2.DtReferencia = CAST(GETDATE() as date)	-- DADOS ATUAIS
  and A.DtReferencia =  CAST(GETDATE()-1 as date)  -- DADOS ANTERIORES
  and C2.NmDatabase = 'YOUR_DATABASE'
  and C.NmDatabase = 'YOUR_DATABASE'
order by A2.NrTamanhoDados desc


-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Este � o Espa�o usado em disco, ou seja, sem contar os Logs e sem o espa�o alocado nos datafiles.	
-----------------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO
DECLARE @dateOld date = '2018-03-28',
		@dateCurrent date = (CAST(GETDATE() AS DATE)), -- �ltimo dia rodado pela Job
		@database varchar(20) = 'YOUR_DATABASE'

SELECT
CONVERT(varchar, x.DATE_OLD, 103)														AS DATE_OLD,

(CAST(x.SIZE_OLD AS VARCHAR)+ ' Mb' + ' -> ' 
+ CAST(CAST(x.SIZE_OLD / 1024 AS DECIMAL(15,2)) AS VARCHAR) + ' Gb')					AS SIZE_OLD,

CONVERT(varchar, @dateCurrent, 103)														AS DATE_CURRENT,

(CAST(x.SIZE_CURRENT AS VARCHAR)+ ' Mb' + ' -> ' 
+ CAST(CAST(x.SIZE_CURRENT / 1024 AS DECIMAL(15,2)) AS VARCHAR) + ' Gb')				AS SIZE_CURRENT,

(CAST((x.SIZE_CURRENT - x.SIZE_OLD) AS VARCHAR) + ' Mb' + ' -> ' 
+ CAST(CAST((x.SIZE_CURRENT - x.SIZE_OLD)/1024 AS DECIMAL(15,2)) AS VARCHAR) + ' Gb')	AS CRESCIMENTO,

DATEDIFF(DAY, @dateOld, @dateCurrent) AS DIF_DAYS
FROM
	(	SELECT	
			v2.DtReferencia								AS DATE_OLD,	 
			sum(v2.NrTamanhoTotal)						AS SIZE_OLD,			  
			(SELECT sum(v.NrTamanhoTotal) 
			 FROM Management.vw_SizeTables as v 
			 WHERE v.DtReferencia = @dateCurrent	-- soma c/ data atual
			 AND v.NmDatabase = @database
			 )												AS SIZE_CURRENT	
		 			  	  	  		  			 			  
		FROM Management.vw_SizeTables v2
		WHERE v2.DtReferencia = @dateOld		-- soma c/ data antiga
		AND v2.NmDatabase = @database
		group by v2.DtReferencia
	) AS x


/**************************************************************** Totalizando por semana com o tamanho ******************************************************************/
declare  @decremento smallint
		,@limite smallint		
		,@dia datetime
IF(OBJECT_ID('tempdb.dbo.##semanas')IS NOT NULL) 
	BEGIN
		drop table ##semanas
	END
create table ##semanas
(
DatabaseName varchar(50),
DataReferencia date,
TotalSize_Gb varchar(20)
)

set @limite = (select DATEDIFF(WEEK, '2016-05-02', GETDATE()) * -1)  -- a data setada � a primerira registrada na rotina de coleta
set @decremento = -1

WHILE (@limite <= @decremento)
	BEGIN			

		set @dia = (select  dateadd(WEEK,@decremento,	cast(floor(cast(getdate() as float)) as datetime)	))

		INSERT INTO ##semanas
		SELECT 
		v.NmDatabase
		, v.DtReferencia
		, REPLACE(CAST(CAST(sum(v.NrTamanhoTotal /1024) AS MONEY) AS VARCHAR(20)),'.',',')
	    FROM integraTICravil.Management.vw_SizeTables as v 
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

/**************************************************************** Refer�ncia de Vitor Fava - Baseado nos Backups ******************************************************************/


DECLARE @endDate datetime, @months smallint;
SET @endDate = GetDate();  -- Include in the statistic all backups from today
SET @months = 6;           -- back to the last 6 months.

;WITH HIST AS
   (SELECT BS.database_name AS DatabaseName
          ,YEAR(BS.backup_start_date) * 100
           + MONTH(BS.backup_start_date) AS YearMonth
          ,CONVERT(numeric(10, 1), MIN(BF.file_size / 1048576.0)) AS MinSizeMB
          ,CONVERT(numeric(10, 1), MAX(BF.file_size / 1048576.0)) AS MaxSizeMB
          ,CONVERT(numeric(10, 1), AVG(BF.file_size / 1048576.0)) AS AvgSizeMB
    FROM msdb.dbo.backupset as BS
         INNER JOIN
         msdb.dbo.backupfile AS BF
             ON BS.backup_set_id = BF.backup_set_id
    WHERE NOT BS.database_name IN
              ('master', 'msdb', 'model', 'tempdb')
          AND BF.file_type = 'D'
          AND BS.backup_start_date BETWEEN DATEADD(mm, - @months, @endDate) AND @endDate
    GROUP BY BS.database_name
            ,YEAR(BS.backup_start_date)
            ,MONTH(BS.backup_start_date))
SELECT MAIN.DatabaseName
      ,MAIN.YearMonth
      ,MAIN.MinSizeMB
      ,MAIN.MaxSizeMB
      ,MAIN.AvgSizeMB
      ,MAIN.AvgSizeMB 
       - (SELECT TOP 1 SUB.AvgSizeMB
          FROM HIST AS SUB
          WHERE SUB.DatabaseName = MAIN.DatabaseName
                AND SUB.YearMonth < MAIN.YearMonth
          ORDER BY SUB.YearMonth DESC) AS GrowthMB
FROM HIST AS MAIN
ORDER BY MAIN.DatabaseName
        ,MAIN.YearMonth


