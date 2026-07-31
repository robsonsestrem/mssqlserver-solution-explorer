/*
 *
	OBJETIVO: Template / Modelo padrão de Trigger DML com bloco de tratamento de exceções
			  utilizando TRY...CATCH e captura detalhada de erro via RAISERROR.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Template Padrão de Trigger DML com Captura de Erros
-- ============================================================

CREATE OR ALTER TRIGGER [dbo].[NOME_TRIGGER]
ON [dbo].[NOME_TABELA]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Insira aqui o código e a lógica principal da Trigger
    END TRY
    BEGIN CATCH
        -- Declaração das variáveis para captura e formatação da mensagem de erro
        DECLARE @ErrorMessage NVARCHAR(4000);
        DECLARE @ErrorSeverity INT;

        -- Captura dos detalhes da exceção ocorrida na execução
        SELECT
            @ErrorMessage = 'TRIGGER: NOME_TRIGGER; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10))
                + ' - ' + CAST(ERROR_STATE() AS VARCHAR(10))
                + ' - ' + ERROR_MESSAGE()
                + ' - ' + CAST(ERROR_NUMBER() AS VARCHAR(10))
          , @ErrorSeverity = ERROR_SEVERITY();

        -- Propagação do erro capturado
        RAISERROR(@ErrorMessage, @ErrorSeverity, 1);
    END CATCH
END
GO
