/*
 *
    OBJETIVO: Procedure para identificação e notificação de vendas indevidas
              realizadas para funcionários no crediário, detectando possíveis
              vendas a funcionários com condições especiais de pagamento.
    PROJETO: mssqlserver-solution-explorer
 *
 */
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE Erp.sp_ReportNotSaleEmployee
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -- ============================================================
        -- Definição do período de análise (últimas 24 horas)
        -- ============================================================
        DECLARE @datainicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
        DECLARE @datafinal DATETIME = DATEADD(MILLISECOND, +997, DATEADD(SECOND, +59, DATEADD(MINUTE, +59, DATEADD(HOUR, +23, DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))))))

        BEGIN TRANSACTION

        -- ============================================================
        -- Verifica se existem vendas com características suspeitas
        -- (funcionários com crediário, filial específica)
        -- ============================================================
        IF (
            SELECT COUNT(*)
            FROM YOUR_DATABASE.dbo.VENDASECF CUP WITH(NOLOCK)
                INNER JOIN YOUR_DATABASE.dbo.TRANSACIONADORES TRA WITH(NOLOCK)
                    ON CUP.CupCliCod = TRA.TraCod
                INNER JOIN YOUR_DATABASE.dbo.VENDASECFLEVEL2 PAG WITH(NOLOCK)
                    ON CUP.FilCod = PAG.FilCod
                    AND CUP.CupDatMov = PAG.CupDatMov
                    AND CUP.CaiCod = PAG.CaiCod
                    AND CUP.CaiOpeCod = PAG.CaiOpeCod
                    AND CUP.CupCodigo = PAG.CupCodigo
            WHERE TRA.TraNatJuridica = 1                        -- pessoa física
                AND TRA.TraNatSocial = 3                        -- funcionário
                AND TRA.TraNatComercial = 2                     -- funcionário
                AND (PAG.cuptottiprec = 3 OR PAG.cuptotfincod = 4)
                AND CUP.CupSitIntegracao = 1                    -- cupons integrados
                AND CUP.FilCod = 60
                AND CUP.CupDatMov BETWEEN @datainicio AND @datafinal
        ) > 0
        BEGIN
            -- ============================================================
            -- Declaração de variáveis para envio do e-mail
            -- ============================================================
            DECLARE @Assunto      VARCHAR(200) = 'Atenção - Ocorreram Possíveis Vendas Indevidas'
                  , @Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br;denise@cravil.com.br'
                  , @Mensagem     VARCHAR(MAX)

            -- ============================================================
            -- Início da montagem do corpo do e-mail
            -- ============================================================
            SET @Mensagem = '
            Para conhecimento da controladoria,<br>
            segue informações sobre vendas nos caixa(s) para funcionário(s) no crediário, detalhes abaixo:
            <br><br>

            <TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:1200pt;font-family:Arial;font-size:14px>
                <tr height=20 style=height:20.0pt align=left>
                    <td bgcolor=#0B0B61 width=90> <font color=white>Matrícula</td>
                    <td bgcolor=#0B0B61 width=450> <font color=white>Nome</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>Filial</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>Caixa</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>Operador</td>
                    <td bgcolor=#0B0B61 width=100> <font color=white>DataVenda</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>Cupom</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>Valor</td>
                    <td bgcolor=#0B0B61 width=100> <font color=white>Vencimento</td>
                    <td bgcolor=#0B0B61 width=90> <font color=white>Situação</td>
                </tr>'

            -- ============================================================
            -- Montagem das linhas da tabela com os dados das vendas
            -- ============================================================
            SELECT @Mensagem = @Mensagem +
                   CASE
                       WHEN CAST(ROW_NUMBER() OVER(ORDER BY TRA.TraNom ASC) % 2 AS BIT) = 1
                           THEN '<tr height=20 style=height:15.0pt align=left>'
                       ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align=left>'
                   END +
                   '<td height=20 style=height:15.0pt>' + CAST(TRA.TraCod AS VARCHAR(10)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + TRA.TraNom + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(TRA.TraFilCod AS VARCHAR(3)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(PAG.CaiCod AS VARCHAR(3)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(PAG.CaiOpeCod AS VARCHAR(10)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CONVERT(VARCHAR(20), PAG.CupDatMov, 103) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(PAG.CupCodigo AS VARCHAR(10)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + (SELECT DBA_PerformanceHub.Erp.fn_FormatIntToMoney(PAG.CupTotVlr)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CONVERT(VARCHAR(20), PAG.CupTotDatVct, 103) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CASE
                       WHEN CUP.CupSituac = 1 THEN 'NORMAL'
                       WHEN CUP.CupSituac = 0 THEN 'CANCELADO'
                       ELSE 'INDEFINIDO'
                   END + '</td>' +
                   '</tr>'
            FROM YOUR_DATABASE.dbo.VENDASECF CUP WITH(NOLOCK)
                INNER JOIN YOUR_DATABASE.dbo.TRANSACIONADORES TRA WITH(NOLOCK)
                    ON CUP.CupCliCod = TRA.TraCod
                INNER JOIN YOUR_DATABASE.dbo.VENDASECFLEVEL2 PAG WITH(NOLOCK)
                    ON CUP.FilCod = PAG.FilCod
                    AND CUP.CupDatMov = PAG.CupDatMov
                    AND CUP.CaiCod = PAG.CaiCod
                    AND CUP.CaiOpeCod = PAG.CaiOpeCod
                    AND CUP.CupCodigo = PAG.CupCodigo
            WHERE TRA.TraNatJuridica = 1                        -- pessoa física
                AND TRA.TraNatSocial = 3                        -- funcionário
                AND TRA.TraNatComercial = 2                     -- funcionário
                AND (PAG.cuptottiprec = 3 OR PAG.cuptotfincod = 4)
                AND CUP.CupDatMov BETWEEN @datainicio AND @datafinal
                AND CUP.FilCod = 60

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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportNotSaleEmployee]:<b> <br>
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
