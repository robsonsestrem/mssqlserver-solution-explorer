/*
 *
    OBJETIVO: Rotina de limpeza e manutenção da tabela de contadores do PerfMon,
              preservando apenas os últimos X dias de registros (padrão 60 dias).
    PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Refatoração estética e documental de sp_DeleteCountersPerfMon
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_DeleteCountersPerfMon
(
    @qtdadeManterDias INT = 60
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        -- =================================================================
        -- Bloco 01: Busca quantidade de dias distintos registrados
        -- =================================================================
        DECLARE @qtdade INT =
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT x.[Date] AS Dia
                FROM
                (
                    SELECT CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) AS [Date]
                    FROM dbo.CounterData
                ) AS x
                GROUP BY x.[Date]
            ) AS x2
        )

        DECLARE @dataMin DATETIME

        -- =================================================================
        -- Bloco 02: Loop para tratamento e exclusão dos dias excedentes
        -- =================================================================
        WHILE (@qtdade > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT MIN(x2.Dia)
                FROM
                (
                    SELECT x.Date AS Dia
                    FROM
                    (
                        SELECT CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) AS [Date]
                        FROM dbo.CounterData
                    ) AS x
                    GROUP BY x.Date
                ) AS x2
            )

            PRINT 'Deletando dados do dia -> ' + CAST(@dataMin AS VARCHAR(20))

            -- =================================================================
            -- Bloco 03: Exclusão física dos registros do dia mínimo
            -- Nota: A cláusula WHERE original estava truncada no arquivo fonte.
            --       A integridade sintática (= @dataMin) foi restaurada.
            -- =================================================================
            DELETE FROM dbo.CounterData
            WHERE CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) = @dataMin

            SET @qtdade = @qtdade - 1
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- =================================================================
        -- Bloco 04: Captura de exceção e montagem do e-mail de falha
        -- Nota: O bloco original continha linhas HTML duplicadas por erro 
        --       de copy-paste. A estrutura foi limpa para um único bloco de erro.
        -- =================================================================
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'
        
        SET @corpoFalha = '
        | Falha na procedure [sp_DeleteCountersPerfMon]:
        |
        | ---|---|---|
        |    [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
        |      [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
        |      [MESSAGE] - ' + ERROR_MESSAGE() + '
        |
        '

        SELECT @corpoFalha = @corpoFalha + ''

        -- =================================================================
        -- Bloco 05: Envio do e-mail de falha
        -- =================================================================
        EXEC msdb.dbo.sp_send_dbmail
            @recipients = @recipients
          , @subject = @subject
          , @profile_name = 'CRAVIL'
          , @body = @corpoFalha
          , @body_format = 'HTML'
    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO
