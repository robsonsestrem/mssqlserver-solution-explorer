/*
 *
    OBJETIVO: Procedure para identificar e finalizar processos ociosos no SQL Server
              com tempo de execução superior ao limite configurado (padrão 5 horas),
              utilizando a procedure sp_whoisactive para coleta de informações
              e registro dos processos finalizados em tabela de histórico.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: sp_whoisactive (Adam Machanic)
 */
-- ============================================================
-- Exemplo de uso:
-- EXECUTE Management.sp_ProcesskillIdle @idleTime = '05:00:00.000'
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_ProcesskillIdle
(
    @idleTime TIME = '05:00:00.000'
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY

        -- ============================================================
        -- Criação da tabela temporária para armazenar dados do sp_whoisactive
        -- ============================================================
        IF OBJECT_ID('tempdb..##whoisactive') IS NOT NULL
            DROP TABLE ##whoisactive

        CREATE TABLE ##whoisactive
        (
              [dd hh:mm:ss.mss]  VARCHAR(8000) NULL
            , [session_id]       SMALLINT NULL
            , [login_name]       NVARCHAR(128) NULL
            , [host_name]        NVARCHAR(128) NULL
            , [status]           VARCHAR(30) NULL
            , [database_name]    NVARCHAR(128) NULL
            , [open_tran_count]  VARCHAR(30) NULL
            , [program_name]     NVARCHAR(128) NULL
            , [collection_time]  DATETIME NULL
            , [start_time]       DATETIME NULL
            , [login_time]       DATETIME NULL
            , [sql_text]         XML NULL
            , [sql_command]      XML NULL
        )

        -- ============================================================
        -- Execução do sp_whoisactive para coleta de processos ativos
        -- ============================================================
        EXEC Management.sp_whoisactive
            @show_own_spid       = 0                 -- <> @@SPID
          , @show_system_spids   = 0                 -- session_id > 50
          , @get_outer_command   = 1
          , @output_column_list  = '
                [dd hh:mm:ss.mss]
              , [session_id]
              , [login_name]
              , [host_name]
              , [status]
              , [database_name]
              , [open_tran_count]
              , [program_name]
              , [collection_time]
              , [start_time]
              , [login_time]
              , [sql_text]
              , [sql_command]
            '
          , @destination_table   = 'tempdb..##whoisactive'

        -- ============================================================
        -- Registra os processos ociosos na tabela de histórico
        -- ============================================================
        INSERT INTO [YOUR_DATABASE].[Management].[HistoryKillProcess]
        SELECT
              x.[dd hh:mm:ss.mss]
            , x.session_id
            , x.login_name
            , x.[host_name]
            , x.[status]
            , x.[database_name]
            , x.open_tran_count
            , x.[program_name]
            , x.collection_time
            , x.start_time
            , x.login_time
            , x.sql_text
            , x.sql_command
        FROM
        (
            SELECT
                  t1.*
                , CAST(RIGHT(t1.[dd hh:mm:ss.mss], 12) AS TIME) AS horas
            FROM ##whoisactive AS t1
            WHERE t1.login_name IN
                (
                      'cravil\nfe'
                    , 'cravil\task'
                    , 'cravil\administrator'
                    , 'cravil\backupexec'
                    , 'cravil\sqlserver'
                    , 'cravil\vcenter'
                    , 'nt service\mssqlserver'
                    , 'nt service\sqlserveragent'
                    , 'nt authority\system'
                    , 'YOUR_DATABASE'
                    , 'admadriana'
                    , 'cravil\domo'
                    , 'cravil\infogen03'
                    , 'agrosystem'
                    , 'consulta'
                    , 'guru'
                    , 'cravil\infogen02'
                    , 'cravil\infogen01'
                    , 'infadriano'
                    , 'infedivaldo'
                    , 'infedivan'
                    , 'infeliezer'
                    , 'infivan'
                    , 'infjehan'
                    , 'infernando'
                    , 'infmarcelo'
                    , 'inftiago'
                    , 'infneimar'
                    , 'suptcadm'
                    , 'vpxuser'
                    , 'sqlmdsmon'
                )
                AND t1.[database_name] IN ('YOUR_DATABASE')
        ) AS x
        WHERE x.horas > @idleTime

        -- ============================================================
        -- Concatena os SPIDs para execução dos comandos KILL
        -- ============================================================
        DECLARE @query VARCHAR(MAX) = ''

        SELECT @query = COALESCE(@query, ',') + 'KILL ' + CONVERT(VARCHAR, x.session_id) + '; '
        FROM
        (
            SELECT
                  t1.*
                , CAST(RIGHT(t1.[dd hh:mm:ss.mss], 12) AS TIME) AS horas
            FROM ##whoisactive AS t1
            WHERE t1.login_name IN
                (
                      'cravil\nfe'
                    , 'cravil\task'
                    , 'cravil\administrator'
                    , 'cravil\backupexec'
                    , 'cravil\sqlserver'
                    , 'cravil\vcenter'
                    , 'nt service\mssqlserver'
                    , 'nt service\sqlserveragent'
                    , 'nt authority\system'
                    , 'YOUR_DATABASE'
                    , 'admadriana'
                    , 'cravil\domo'
                    , 'cravil\infogen03'
                    , 'agrosystem'
                    , 'consulta'
                    , 'guru'
                    , 'cravil\infogen02'
                    , 'cravil\infogen01'
                    , 'infadriano'
                    , 'infedivaldo'
                    , 'infedivan'
                    , 'infeliezer'
                    , 'infivan'
                    , 'infjehan'
                    , 'infernando'
                    , 'infmarcelo'
                    , 'inftiago'
                    , 'infneimar'
                    , 'suptcadm'
                    , 'vpxuser'
                    , 'sqlmdsmon'
                )
                AND t1.[database_name] IN ('YOUR_DATABASE')
        ) AS x
        WHERE x.horas > @idleTime

        -- ============================================================
        -- Executa os comandos KILL para finalizar os processos ociosos
        -- ============================================================
        IF (LEN(@query) > 0 AND @@ROWCOUNT <> 0)
            EXEC(@query)

    END TRY

    BEGIN CATCH
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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ProcesskillIdle]:<b> <br>
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
