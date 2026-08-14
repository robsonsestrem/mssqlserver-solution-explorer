/*
 *
    OBJETIVO: Procedure para identificação e notificação de inconsistências
              na sequência de ART (Anotação de Responsabilidade Técnica)
              no sistema, verificando gaps na numeração das receitas.
    PROJETO: mssqlserver-solution-explorer
 * 
 */
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE Erp.sp_ReportGapART
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        DECLARE @dataValidacao DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))

        BEGIN TRANSACTION

        -- ============================================================
        -- Verifica se existe pelo menos um gap na sequência de ART
        -- ============================================================
        IF (
            SELECT COUNT(*) AS Qtdade
            FROM
            (
                SELECT
                      t1.RatFilCod AS Filial
                    , t1.RatEngCod AS Engenhheiro
                    , t1.RatNumRec - 1 AS Gap
                    , t1.RatDatEmis AS Data
                FROM YOUR_DATABASE.dbo.RATMOVESTOQELEVEL3 t1 WITH(NOLOCK)
                WHERE t1.RatDatEmis >= @dataValidacao
                    AND NOT EXISTS
                    (
                        SELECT RATNUMREC
                        FROM YOUR_DATABASE.dbo.RATMOVESTOQELEVEL3 ANT WITH(NOLOCK)
                        WHERE t1.RatNumRec - 1 = ANT.RatNumRec
                            AND t1.RatFilCod = ANT.RatFilCod
                            AND t1.RatEngCod = ANT.RatEngCod
                    )
                GROUP BY
                      t1.RatFilCod
                    , t1.RatEngCod
                    , t1.RatNumRec
                    , t1.RatDatEmis
            ) AS x
        ) > 0
        BEGIN
            -- ============================================================
            -- Declaração de variáveis para envio do e-mail
            -- ============================================================
            DECLARE @Assunto      VARCHAR(200) = 'Inconsistência Sistêmica - Problemas Com ART'
                  , @Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br;adriana@cravil.com.br'
                  , @Mensagem     VARCHAR(MAX)

            -- ============================================================
            -- Início da montagem do corpo do e-mail
            -- ============================================================
            SET @Mensagem = '
            Atenção,
            erro na sequência de ART foi identificado, dados abaixo:
            <br><br>

            <TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:1200pt;font-family:Arial;font-size:14px>
                <tr height=20 style=height:20.0pt align=center>
                    <td bgcolor=#0B0B61 width=200> <font color=white>Filial</td>
                    <td bgcolor=#0B0B61 width=200> <font color=white>Engenheiro</td>
                    <td bgcolor=#0B0B61 width=200> <font color=white>Receita_Gap</td>
                    <td bgcolor=#0B0B61 width=200> <font color=white>Data</td>
                </tr>'

            -- ============================================================
            -- Montagem das linhas da tabela com os dados dos gaps
            -- ============================================================
            SELECT @Mensagem = @Mensagem +
                   CASE
                       WHEN CAST(ROW_NUMBER() OVER(ORDER BY t1.RatEngCod ASC) % 2 AS BIT) = 1
                           THEN '<tr height=20 style=height:15.0pt align=center>'
                       ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align=center>'
                   END +
                   '<td height=20 style=height:15.0pt>' + CAST(t1.RatFilCod AS VARCHAR(20)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(t1.RatEngCod AS VARCHAR(20)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(t1.RatNumRec - 1 AS VARCHAR(20)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CONVERT(VARCHAR(20), t1.RatDatEmis, 103) + '</td>' +
                   '</tr>'
            FROM YOUR_DATABASE.dbo.RATMOVESTOQELEVEL3 t1 WITH(NOLOCK)
            WHERE t1.RatDatEmis >= @dataValidacao
                AND NOT EXISTS
                (
                    SELECT RATNUMREC
                    FROM YOUR_DATABASE.dbo.RATMOVESTOQELEVEL3 ANT WITH(NOLOCK)
                    WHERE t1.RatNumRec - 1 = ANT.RatNumRec
                        AND t1.RatFilCod = ANT.RatFilCod
                        AND t1.RatEngCod = ANT.RatEngCod
                )
            GROUP BY
                  t1.RatFilCod
                , t1.RatEngCod
                , t1.RatNumRec
                , t1.RatDatEmis

            -- ============================================================
            -- Finalização da tabela HTML
            -- ============================================================
            SELECT @Mensagem = @Mensagem +
                   '</table>' + '<br><br>'

            -- ============================================================
            -- Envio do e-mail
            -- ============================================================
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name   = 'CRAVIL'
              , @recipients     = @Destinatario
              , @subject        = @Assunto
              , @body           = @Mensagem
              , @body_format    = 'HTML'
        END

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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportGapART]:<b> <br>
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
END
GO
