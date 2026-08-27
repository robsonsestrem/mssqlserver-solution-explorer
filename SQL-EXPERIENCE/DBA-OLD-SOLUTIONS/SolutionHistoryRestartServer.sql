/*
 *
    OBJETIVO: Procedure para identificar e armazenar histórico de reinicializações
              do SQL Server através da leitura dos arquivos de trace (.trc),
              registrando os períodos de downtime (shutdown e startup).
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  Documentação oficial: fn_trace_gettable, xp_fileexist, sys.traces
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_loadRestartServer
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY

        -- ============================================================
        -- Tabela temporária para armazenar os períodos de downtime
        -- ============================================================
        DECLARE @tb_Downtime TABLE
        (
              [dth_Shutdown] DATETIME
            , [dth_Start]    DATETIME
            , [num_Minutos]  INT
        )

        -- ============================================================
        -- Declaração de variáveis para manipulação dos arquivos de trace
        -- ============================================================
        DECLARE @des_PathTrace VARCHAR(250)
              , @num_Arquivo INT
              , @des_ArquivoAtual VARCHAR(300)
              , @des_ArquivoAnterior VARCHAR(300)
              , @dth_Start DATETIME
              , @dth_Shutdown DATETIME
              , @ind_ArquivoExiste INT

        -- ============================================================
        -- Obtém o caminho e número do arquivo de trace atual
        -- ============================================================
        SELECT @num_Arquivo = CAST(SUBSTRING(RIGHT(path, CHARINDEX('\', REVERSE(path)) - 1), 5, LEN(RIGHT(path, CHARINDEX('\', REVERSE(path)) - 1 - 4 - 4))) AS INT)
             , @des_PathTrace = SUBSTRING(path, 1, LEN(path) - CHARINDEX('\', REVERSE(path)) + 1)
        FROM [sys].[traces]
        WHERE [id] = 1

        SET @ind_ArquivoExiste = 1

        -- ============================================================
        -- Loop para percorrer arquivos de trace anteriores
        -- ============================================================
        WHILE @ind_ArquivoExiste = 1
        BEGIN
            SET @des_ArquivoAtual = @des_PathTrace + 'log_' + CAST(@num_Arquivo AS VARCHAR) + '.trc'

            SET @num_Arquivo = @num_Arquivo - 1
            SET @des_ArquivoAnterior = @des_PathTrace + 'log_' + CAST(@num_Arquivo AS VARCHAR) + '.trc'

            EXEC [master].[dbo].[xp_fileexist]
                @des_ArquivoAnterior
              , @ind_ArquivoExiste OUTPUT

            IF @ind_ArquivoExiste = 1
            BEGIN
                SELECT @dth_Start = MIN([starttime])
                FROM [fn_trace_gettable](@des_ArquivoAtual, 1)
                WHERE [starttime] IS NOT NULL

                SELECT @dth_Shutdown = MAX([starttime])
                FROM [fn_trace_gettable](@des_ArquivoAnterior, 1)
                WHERE [starttime] IS NOT NULL

                INSERT INTO @tb_Downtime
                VALUES
                (
                      @dth_Shutdown
                    , @dth_Start
                    , DATEDIFF(MINUTE, @dth_Shutdown, @dth_Start)
                )
            END
        END

        -- ============================================================
        -- Insere os dados na tabela de histórico (evitando duplicatas)
        -- ============================================================
        BEGIN TRANSACTION

        INSERT INTO YOUR_DATABASE.Management.HistoryRestartServer
        (
              ServerName
            , DateInsert
            , DateShutdown
            , DateStart
            , [Minutes]
        )
        SELECT
              @@SERVERNAME
            , GETDATE()
            , t1.dth_Shutdown
            , t1.dth_Start
            , t1.num_Minutos
        FROM @tb_Downtime AS t1
        WHERE t1.num_Minutos <> 0
            AND t1.dth_Shutdown NOT IN
            (
                SELECT t2.DateShutdown
                FROM YOUR_DATABASE.Management.HistoryRestartServer AS t2
            )

        COMMIT TRANSACTION

    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Captura de exceção e montagem do e-mail de falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject    VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content=text/html; charset=windows-1252>
            </head>
            <body>
            <div align=left>'

        SELECT @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_loadRestartServer]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'

    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO

-- ============================================================
-- Criação da Tabela que é alimentada para Complementar Checklist
-- ============================================================
USE YOUR_DATABASE
GO

CREATE TABLE Management.HistoryRestartServer
(
      IdRestart     INT NOT NULL IDENTITY(1, 1) PRIMARY KEY
    , ServerName    VARCHAR(20) NOT NULL
    , DateInsert    DATETIME NOT NULL
    , DateShutdown  DATETIME NOT NULL
    , DateStart     DATETIME NOT NULL
    , [Minutes]     INT NOT NULL
)
GO
