/*
 *
    OBJETIVO: Procedure para monitoramento do espaço livre em datafiles (mdf, ndf, ldf),
              alertando quando o percentual livre fica abaixo do limite configurado
              (padrão 5%), com envio de e-mail contendo os detalhes dos arquivos críticos.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: FILEPROPERTY, sys.database_files, sp_msforeachdb
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_MonitoringSizeFreeDatafiles
(
    @percentFree FLOAT = 5
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        BEGIN TRANSACTION

        -- ============================================================
        -- Criação da tabela temporária para armazenar informações dos datafiles
        -- ============================================================
        IF OBJECT_ID('tempdb..##tempDatafileFree') IS NOT NULL
            DROP TABLE ##tempDatafileFree

        CREATE TABLE ##tempDatafileFree
        (
              DatabaseName   SYSNAME
            , LogicalName    SYSNAME
            , PhysicalName   NVARCHAR(100)
            , Size_Gb        DECIMAL(18, 2)
            , SpaceFree_Gb   DECIMAL(18, 2)
            , PercFreeFile   DECIMAL(18, 2)
        )

        -- ============================================================
        -- Coleta dos dados de todos os bancos de dados via sp_msforeachdb
        -- ============================================================
        EXEC sp_msforeachdb '
        USE [?];
        INSERT INTO ##tempDatafileFree
        (
              DatabaseName
            , LogicalName
            , physicalName
            , size_Gb
            , SpaceFree_Gb
            , PercFreeFile
        )
        SELECT
              DB_NAME() AS DatabaseName
            , Name
            , physical_name
            , CAST(CAST(ROUND(CAST(size AS DECIMAL) * 8.0 / 1024.0, 2) AS DECIMAL(18, 2)) AS NVARCHAR) AS Size_Gb
            , CAST(CAST(ROUND(CAST(size AS DECIMAL) * 8.0 / 1024.0, 2) AS DECIMAL(18, 2))
                - CAST(FILEPROPERTY(name, ''SpaceUsed'') * 8.0 / 1024.0 AS DECIMAL(18, 2)) AS NVARCHAR) AS SpaceFree_Gb
            , (CAST(ROUND(CAST(size AS DECIMAL) * 8.0 / 1024.0, 2) AS DECIMAL(18, 2))
                - CAST(FILEPROPERTY(name, ''SpaceUsed'') * 8.0 / 1024.0 AS DECIMAL(18, 2))) * 100
                / CAST(ROUND(CAST(size AS DECIMAL) * 8.0 / 1024.0, 2) AS DECIMAL(18, 2)) AS PercFreeFile
        FROM sys.database_files;'

        -- Opção para filtrar bancos específicos (caso necessário)
        -- DELETE FROM ##tempDatafileFree
        -- WHERE DatabaseName LIKE '%YOUR_DATABASE%'

        -- ============================================================
        -- Verifica se existem datafiles com espaço livre abaixo do limite
        -- ============================================================
        IF ((SELECT COUNT(*) FROM ##tempDatafileFree AS t WHERE t.PercFreeFile <= @percentFree) > 0)
        BEGIN
            -- ============================================================
            -- Declaração de variáveis para envio do e-mail
            -- ============================================================
            DECLARE @Assunto      VARCHAR(200) = @@SERVERNAME + ' - Monitoramento de Espaço Livre nos DataFiles'
                  , @Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br'
                  , @Mensagem     VARCHAR(MAX)

            -- ============================================================
            -- Início da montagem do corpo do e-mail
            -- ============================================================
            SET @Mensagem = '
            Atenção DBA,<br>
            Espaço livre em algum(s) arquivos de dados (mdf, ndf e ldf) está reduzido (menor que 5%).
            <br>Obs.: Em caso de bases muito grandes foi calibrado para alertar em 3%.
            <br>Instância: ' + @@SERVICENAME + '
            <br>Servidor: ' + @@SERVERNAME + '
            <br><br>

            <TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
                <tr height=20 style=height:20.0pt align=left>
                    <td bgcolor=#0B0B61 width=120> <font color=white>DatabaseName</td>
                    <td bgcolor=#0B0B61 width=120> <font color=white>LogicalName</td>
                    <td bgcolor=#0B0B61 width=650> <font color=white>PhysicalName</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>Size_Gb</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>SpaceUsed_GB</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>SpaceFree_Gb</td>
                    <td bgcolor=#0B0B61 width=70> <font color=white>SpaceFree_%</td>
                </tr>'

            -- ============================================================
            -- Montagem das linhas da tabela com os dados críticos
            -- ============================================================
            SELECT @Mensagem = @Mensagem +
                   CASE
                       WHEN CAST(ROW_NUMBER() OVER(ORDER BY t.DatabaseName ASC) % 2 AS BIT) = 1
                           THEN '<tr height=20 style=height:15.0pt align=left>'
                       ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align=left>'
                   END +
                   '<td height=20 style=height:15.0pt>' + t.DatabaseName + '</td>' +
                   '<td height=20 style=height:15.0pt>' + t.LogicalName + '</td>' +
                   '<td height=20 style=height:15.0pt>' + t.PhysicalName + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(CAST(t.size_Gb / 1024 AS DECIMAL(18, 2)) AS VARCHAR(20)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(CAST((t.size_Gb - t.SpaceFree_Gb) / 1024 AS DECIMAL(18, 2)) AS VARCHAR(20)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(CAST(t.SpaceFree_Gb / 1024 AS DECIMAL(18, 2)) AS VARCHAR(20)) + '</td>' +
                   '<td height=20 style=height:15.0pt>' + CAST(t.PercFreeFile AS VARCHAR(20)) + '</td>' +
                   '</tr>'
            FROM ##tempDatafileFree AS t
            WHERE t.PercFreeFile <= @percentFree

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

        -- ============================================================
        -- Limpeza da tabela temporária
        -- ============================================================
        DROP TABLE ##tempDatafileFree

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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_MonitoringSizeFreeDatafiles]:<b> <br>
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
