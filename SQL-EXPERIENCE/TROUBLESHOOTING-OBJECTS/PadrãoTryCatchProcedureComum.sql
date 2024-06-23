CREATE OR ALTER PROCEDURE dbo.NOME_PROCEDURE
AS
  BEGIN
    BEGIN TRY
    
        -- codigo
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT;      
        SELECT @ErrorMessage = 'PROCEDURE: NOME_PROCEDURE; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) 
        + ' - ' + ERROR_PROCEDURE()
        + ' - ' + CAST(ERROR_STATE() AS VARCHAR(10))
        + ' - ' + ERROR_MESSAGE()
        + ' - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)), @ErrorSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);        
    END CATCH
  END 
GO