/*
 *
	OBJETIVO: Template padrão para Stored Procedures com controle transacional
			  explícito (BEGIN TRAN, COMMIT TRAN, ROLLBACK TRAN) e tratamento
			  de exceções via TRY...CATCH com verificação de XACT_STATE().
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Template de Stored Procedure com Controle Transacional Avançado
-- ============================================================

CREATE OR ALTER PROCEDURE [dbo].MINHA_PROCEDURE_E_MELHOR
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        -- Início da transação explícita
        BEGIN TRANSACTION;

        -- CONTEÚDO PROGRAMADO

        -- Confirmação das alterações da transação
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Declaração das variáveis para tratamento do erro
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;

        -- Captura e montagem da mensagem detalhada do erro
        SELECT
            @ErrorMessage = N'PROCEDURE: MINHA_PROCEDURE_E_MELHOR; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10))
                + ' - ' + ERROR_PROCEDURE()
                + ' - ' + CAST(ERROR_STATE() AS VARCHAR(10))
                + ' - ' + ERROR_MESSAGE()
                + ' - ' + CAST(ERROR_NUMBER() AS VARCHAR(10))
          , @ErrorSeverity = ERROR_SEVERITY();

        -- Notificação do erro acionado
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);

        -- Avaliação do estado da transação para desfazer (Rollback) caso esteja não comitável
        IF (XACT_STATE()) = -1
        BEGIN
            PRINT N'A transação está em um estado incompatível. Retrocedendo transação.';
            ROLLBACK TRANSACTION;
        END;

        -- Avaliação do estado da transação para confirmar (Commit) caso continue válida
        IF (XACT_STATE()) = 1
        BEGIN
            PRINT N'A transação é compatível. Transação completada.';
            COMMIT TRANSACTION;
        END;
    END CATCH

    SET NOCOUNT OFF;
    SET XACT_ABORT OFF;
END
GO