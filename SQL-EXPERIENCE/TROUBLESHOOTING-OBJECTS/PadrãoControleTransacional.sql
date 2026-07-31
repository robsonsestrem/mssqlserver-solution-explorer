/*
 * OBJETIVO: Padrão de controle transacional com tratamento de erros (TRY...CATCH)
 *           e validação de estado da transação (XACT_STATE) para garantir atomicidade.
 * PROJETO: mssqlserver-solution-explorer
 * 
 * REFERÊNCIAS DE URL:
 * https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/try-catch-transact-sql
 */
-- ============================================================
-- Padrão de Controle Transacional
-- ============================================================

SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRY
    BEGIN TRANSACTION

    -- seu código aqui

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    -- Recuperação detalhada das informações do erro ocorrido
    SELECT
        ERROR_NUMBER()      AS ErrorNumber
        ,ERROR_SEVERITY()   AS ErrorSeverity
        ,ERROR_STATE()      AS ErrorState
        ,ERROR_LINE()       AS ErrorLine
        ,ERROR_MESSAGE()    AS ErrorMessage;

    -- Validação do estado da transação para rollback em caso de estado incompatível
    IF (XACT_STATE()) = -1
    BEGIN
        PRINT 'A transação está em um estado incompatível. Retrocedendo transação.'
        ROLLBACK TRANSACTION;
    END;

    -- Validação do estado da transação para commit em caso de estado compatível
    IF (XACT_STATE()) = 1
    BEGIN
        PRINT 'A transação é compatível. Transação completada.'
        COMMIT TRANSACTION;
    END;
END CATCH

SET NOCOUNT OFF
SET XACT_ABORT OFF
