/*
 *
	OBJETIVO: Template padrão de Stored Procedure com tratamento de exceções
			  utilizando blocos TRY...CATCH e captura detalhada de erro via RAISERROR.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Estrutura Padrão para Stored Procedure com Captura de Erros
-- ============================================================

CREATE OR ALTER PROCEDURE dbo.NOME_PROCEDURE
AS
BEGIN
    BEGIN TRY
        -- Inserção do código e lógica principal do procedimento
    END TRY
    BEGIN CATCH
        -- Declaração das variáveis para tratamento e relato do erro
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;

        -- Captura das informações da exceção gerada no bloco TRY
        SELECT
            @ErrorMessage = 'PROCEDURE: NOME_PROCEDURE; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10))
                + ' - ' + ERROR_PROCEDURE()
                + ' - ' + CAST(ERROR_STATE() AS VARCHAR(10))
                + ' - ' + ERROR_MESSAGE()
                + ' - ' + CAST(ERROR_NUMBER() AS VARCHAR(10))
          , @ErrorSeverity = ERROR_SEVERITY();

        -- Lançamento do erro capturado para a aplicação/chamador
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH
END
GO