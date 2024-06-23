CREATE OR ALTER PROCEDURE [dbo].MINHA_PROCEDURE_E_MELHOR
AS
BEGIN
    SET NOCOUNT ON
    SET XACT_ABORT ON 	  
                  
    BEGIN TRY
		BEGIN TRANSACTION


        --  CONTEÚDO PROGRAMADO


		COMMIT TRANSACTION
    END TRY
    BEGIN CATCH                                                              
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT;      
        SELECT @ErrorMessage = N'PROCEDURE: MINHA_PROCEDURE_E_MELHOR; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) 
        + ' - ' + ERROR_PROCEDURE()
        + ' - ' + CAST(ERROR_STATE() AS VARCHAR(10))
        + ' - ' + ERROR_MESSAGE()
        + ' - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)), @ErrorSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
		
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
    END CATCH

    SET NOCOUNT OFF
	SET XACT_ABORT OFF

END
GO