--------------------------------------------------------------------------------------------------------------------------------------------------------
-- GLPI 1105 - Rotina plano parcial: Otimização de código - Crise Careplus
--------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://gavindraper.com/2018/05/20/SQL-Server-Error-Handling/
-- https://stackoverflow.com/questions/59364251/question-with-xact-state-value-inside-a-catch-block
-- https://learn.microsoft.com/pt-br/sql/t-sql/functions/xact-state-transact-sql?view=sql-server-ver16
-- https://sqlenlight.com/support/help/sa0152/
--------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE [dbo].[SP_PLANO_PARCIAL]
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; 	  
    SET DEADLOCK_PRIORITY 5;   
                
    BEGIN TRY
		BEGIN TRANSACTION


        SELECT 100/20 -- teste pra erro: 100/0


		COMMIT TRANSACTION
    END TRY
    BEGIN CATCH                                                                      		
        IF (XACT_STATE()) = -1  
  			BEGIN  
  				PRINT N'A transação está em um estado incompatível. Retrocedendo transação.'  					  
  				ROLLBACK TRANSACTION;  
  			END;  
  			
  		IF (XACT_STATE()) = 1  
  			BEGIN  
  				PRINT N'A transação e compatível. Transação completada.'  					  
  				COMMIT TRANSACTION;     
  			END;

        DECLARE @ErrorMessage NVARCHAR(4000)     
        DECLARE @ErrorNumber INT = 50000 + ERROR_NUMBER()
        DECLARE @ErrorState INT = ERROR_STATE()
        SELECT @ErrorMessage = N'PROCEDURE: SP_PLANO_PARCIAL; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE()        
             
        ;THROW @ErrorNumber, @ErrorMessage, @ErrorState;
    END CATCH

    SET NOCOUNT OFF
	SET XACT_ABORT OFF

END
GO