USE IntegraTICravil
GO
SET STATISTICS TIME ON 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

BEGIN TRY 
    DECLARE @dataChave DATETIME = '2018-07-31' 
    DECLARE @datalimite DATETIME, 
            @limite     SMALLINT = 20 -- dias para avançar
    DECLARE @intervalo  DATETIME, 
            @iterarDias SMALLINT = 1 -- iterador incremental para o datetime

    SET @datalimite = Dateadd(day, @limite, @dataChave) 

    WHILE( @dataChave < @datalimite ) 
      BEGIN 
          SET @intervalo = Dateadd(day, @iterarDias, @dataChave) 

		  -- condição para intervalo do datetime
          DELETE FROM bi.historicoposicaoestoque 
          WHERE  dataemissao >= @dataChave 
                 AND dataemissao < @intervalo 

		  -- incrementa + 1 dia
          SET @dataChave = Dateadd(day, @iterarDias, @dataChave) 
		  -- tratamento modo simple
          -- DBCC shrinkfile(integraticravil_log, 60000)
		  -- BACKUP LOG IntegraTICravil TO DISK = 'G:\Backup\IntegraTICravil_log.TRN' WITH INIT;

      END 
	-- BACKUP LOG IntegraTICravil TO DISK = 'G:\Backup\IntegraTICravil_log.TRN' WITH INIT;

END TRY 

BEGIN CATCH 
    SELECT Error_number()    AS ErrorNumber, 
           Error_severity()  AS ErrorSeverity, 
           Error_state()     AS ErrorState, 
           Error_procedure() AS ErrorProcedure, 
           Error_line()      AS ErrorLine, 
           Error_message()   AS ErrorMessage 
END CATCH 

SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
SET STATISTICS TIME OFF 

--dbcc shrinkfile(IntegraTICravil_log,40000)
--ErrorNumber	ErrorSeverity	ErrorState	ErrorProcedure	ErrorLine	ErrorMessage
--9002	17	4	NULL	18	The transaction log for database 'IntegraTICravil' is full due to 'ACTIVE_TRANSACTION'.
--BACKUP database IntegraTICravil TO DISK = 'G:\Backup\IntegraTICravil_log.BAK' WITH INIT;


use IntegraTICravil
go
select 
x.Data
, COUNT(*) as DadosTotais
from
(
select cast(t1.DataEmissao as date) as [Data]
from bi.HistoricoPosicaoEstoque as t1
WHERE t1.DataEmissao >= '20180101' AND t1.DataEmissao < '20180912'
) as x
group by x.Data
order by x.Data DESC


select min(t1.DataEmissao) from Bi.HistoricoPosicaoEstoque as t1

--SELECT min(t1.DataRotina) 
--FROM Bi.Execucao AS t1
--WHERE t1.Descricao LIKE '%INSERT TABELA HistoricoPosicaoEstoque%'
--AND t1.datarotina >= '20180101' AND t1.datarotina < '20180906'


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Outra forma com if (mais engessado)
----------------------------------------------------------------------------------------------------------------------------------------------------------
--SET STATISTICS TIME ON
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--BEGIN TRY
--	declare @dataChave datetime = '20170501'
--	declare @datalimite datetime	
--	DECLARE @delete1 smallint = 20
--	, @delete2 smallint = 15
--	, @delete3 smallint = 10
--	, @delete4 smallint = 5

--	set @datalimite = dateadd(day, @delete1, @dataChave)	

--	IF( datediff(day, @dataChave, @datalimite ) = @delete1 )		
--	BEGIN	
--			DECLARE @intervalo1 datetime = dateadd(day, 5, @dataChave)

--			DELETE FROM Bi.HistoricoPosicaoEstoque
--			WHERE DataEmissao >= @dataChave AND DataEmissao < @intervalo1			
--			SET @dataChave = dateadd(day, 5, @dataChave)	-- incremento da data de movimentação		
			
--			DBCC SHRINKFILE(IntegraTICravil_log, 60000)	
--	END
--	IF( datediff(day, @dataChave, @datalimite ) = @delete2 )		
--	BEGIN	
--			DECLARE @intervalo2 datetime = dateadd(day, 5, @dataChave)

--			DELETE FROM Bi.HistoricoPosicaoEstoque
--			WHERE DataEmissao >= @dataChave AND DataEmissao < @intervalo2		
--			SET @dataChave = dateadd(day, 5, @dataChave)	-- incremento da data de movimentação			

--			DBCC SHRINKFILE(IntegraTICravil_log, 60000)
--	END			
--END TRY
--BEGIN CATCH
--	rollback TRAN
--		SELECT
--			ERROR_NUMBER() AS ErrorNumber,
--			ERROR_SEVERITY() AS ErrorSeverity,
--			ERROR_STATE() AS ErrorState,
--			ERROR_PROCEDURE() AS ErrorProcedure,
--			ERROR_LINE() AS ErrorLine,
--			ERROR_MESSAGE() AS ErrorMessage	
--END CATCH
--SET TRANSACTION ISOLATION LEVEL READ COMMITTED
--SET STATISTICS TIME OFF