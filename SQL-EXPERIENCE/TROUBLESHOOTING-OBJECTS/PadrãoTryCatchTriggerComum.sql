CREATE OR ALTER TRIGGER [dbo].[NOME_TRIGGER]
ON [dbo].[NOME_TABELA]
AFTER INSERT, UPDATE, DELETE
AS
  BEGIN
    BEGIN TRY
    
        -- seu codigo
        
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT;      
        SELECT @ErrorMessage = 'TRIGGER: NOME_TRIGGER; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10))         
        + ' - ' + CAST(ERROR_STATE() AS VARCHAR(10))
        + ' - ' + ERROR_MESSAGE()
        + ' - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)), @ErrorSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);        
    END CATCH
  END 
GO

