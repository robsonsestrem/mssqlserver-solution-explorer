SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRY
  BEGIN TRANSACTION

    -- seu código aqui

  COMMIT TRANSACTION
END TRY
BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber
   ,ERROR_SEVERITY() AS ErrorSeverity
   ,ERROR_STATE() AS ErrorState
   ,ERROR_LINE() AS ErrorLine
   ,ERROR_MESSAGE() AS ErrorMessage;

  IF (XACT_STATE()) = -1
  BEGIN
    PRINT 'A transação está em um estado incompatível. Retrocedendo transação.'
    ROLLBACK TRANSACTION;
  END;

  IF (XACT_STATE()) = 1
  BEGIN
    PRINT 'A transação é compatível. Transação completada.'
    COMMIT TRANSACTION;
  END;
END CATCH

SET NOCOUNT OFF
SET XACT_ABORT OFF