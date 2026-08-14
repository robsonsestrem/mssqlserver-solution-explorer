/*
 *
    OBJETIVO: Procedure para geração e envio de relatório diário de processos bloqueados
              no SQL Server, com extração de dados da tabela HistoryBlockedProcess
              e envio por e-mail com anexo CSV contendo os detalhes dos bloqueios.
    PROJETO: mssqlserver-solution-explorer
 *
 */
-- Caso seja necessário para suportar anexo maior nos e-mails:
-- EXECUTE msdb.dbo.sysmail_configure_sp 'MaxFileSize', '50000000';

USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_ReportBloquedProcess]
    @ExibirApenasHtml BIT = 0
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    -- ============================================================
    -- Declaração de variáveis
    -- ============================================================
    DECLARE @inicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
    DECLARE @fim DATETIME = DATEADD(MILLISECOND, +997, DATEADD(SECOND, +59, DATEADD(MINUTE, +59, DATEADD(HOUR, +23, DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))))))
    DECLARE @vSubject NVARCHAR(255) = 'Relatório diário - Processos Bloqueados no Sistema'
    DECLARE @vBody AS NVARCHAR(MAX) = ''
    DECLARE @contaInsert INT = 0

    -- ============================================================
    -- Criação da tabela temporária para armazenar os dados extraídos
    -- ============================================================
    IF OBJECT_ID('tempdb..##ReportBlock') IS NOT NULL
    BEGIN
        DROP TABLE ##ReportBlock
    END
    ELSE
    BEGIN
        CREATE TABLE ##ReportBlock
        (
              Segundos                  VARCHAR(50)
            , Evento                    VARCHAR(50)
            , Data_Inicio               VARCHAR(23)
            , Data_Fim                  VARCHAR(23)
            , BD                        VARCHAR(50)
            , Mode                      VARCHAR(10)
            , LockMode                  VARCHAR(10)
            , WaitResource              VARCHAR(100)
            , Program_Blocked           VARCHAR(100)
            , SPID_Blocked              VARCHAR(10)
            , Host_Blocked              VARCHAR(100)
            , Login_Blocked             VARCHAR(100)
            , IsolationLevel_Blocked    VARCHAR(100)
            , Script_Blocked            VARCHAR(MAX)
            , Program_Blocking          VARCHAR(100)
            , SPID_Blocking             VARCHAR(10)
            , Host_Blocking             VARCHAR(100)
            , Login_Blocking            VARCHAR(100)
            , IsolationLevel_Blocking   VARCHAR(100)
            , Script_Blocking           VARCHAR(MAX)
        )
    END

    -- ============================================================
    -- Extração dos dados dos gráficos de bloqueio
    -- ============================================================
    ;WITH cte_BlockedProcess AS
    (
        SELECT
              IdBlock
            , DateBlock
            , DatabaseName
            , GraphBlock
        FROM
            Management.HistoryBlockedProcess
        WHERE
            DateBlock BETWEEN @inicio AND @fim
    )
    INSERT INTO ##ReportBlock
    (
          Segundos
        , Evento
        , Data_Inicio
        , Data_Fim
        , BD
        , Mode
        , LockMode
        , WaitResource
        , Program_Blocked
        , SPID_Blocked
        , Host_Blocked
        , Login_Blocked
        , IsolationLevel_Blocked
        , Script_Blocked
        , Program_Blocking
        , SPID_Blocking
        , Host_Blocking
        , Login_Blocking
        , IsolationLevel_Blocking
        , Script_Blocking
    )
    SELECT
          REPLACE((CAST(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Duration)') AS VARCHAR(60)) AS MONEY) / 1000 / 1000), ',', '.') AS Segundos
        , CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EventType)') AS VARCHAR(50)) AS Evento
        , REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Inicio
        , REPLACE(CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/EndTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Fim
        , [A].DatabaseName AS BD
        , CAST([A].GraphBlock.[query]('data(/EVENT_INSTANCE/Mode)') AS VARCHAR(10)) AS Mode
        , [BlockedProcess].Process.value('@lockMode', 'varchar(max)') AS LockMode
        , [BlockedProcess].Process.value('@waitresource', 'varchar(max)') AS Waitresource
        , [BlockedProcess].Process.value('@clientapp', 'varchar(max)') AS Program_Blocked
        , [BlockedProcess].Process.value('@spid', 'varchar(max)') AS SPID_Blocked
        , [BlockedProcess].Process.value('@hostname', 'varchar(max)') AS Host_Blocked
        , [BlockedProcess].Process.value('@loginname', 'varchar(max)') AS Login_Blocked
        , [BlockedProcess].Process.value('@isolationlevel', 'varchar(max)') AS IsolationLevel_Blocked
        , REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockedProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)), '<inputbuf>', ''), '</inputbuf>', '')), CHAR(10), ''), CHAR(13), ''), CHAR(9), '') AS Script_Blocked
        , [BlockingProcess].Process.value('@clientapp', 'varchar(max)') AS Program_Blocking
        , [BlockingProcess].Process.value('@spid', 'varchar(max)') AS SPID_Blocking
        , [BlockingProcess].Process.value('@hostname', 'varchar(max)') AS Host_Blocking
        , [BlockingProcess].Process.value('@loginname', 'varchar(max)') AS Login_Blocking
        , [BlockingProcess].Process.value('@isolationlevel', 'varchar(max)') AS IsolationLevel_Blocking
        , REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST([BlockingProcess].Process.[query]('inputbuf') AS VARCHAR(MAX)), '<inputbuf>', ''), '</inputbuf>', '')), CHAR(10), ''), CHAR(13), ''), CHAR(9), '') AS Script_Blocking
    FROM
        [cte_BlockedProcess] AS [A]
        CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocked-process/process') AS [BlockedProcess]([Process])
        CROSS APPLY A.GraphBlock.[nodes]('//blocked-process-report/blocking-process/process') AS [BlockingProcess]([Process])
    WHERE
        [BlockedProcess].Process.value('@hostname', 'varchar(max)') NOT IN ('CTI-000492', 'CTI-000370')
        AND [BlockingProcess].Process.value('@hostname', 'varchar(max)') NOT IN ('CTI-000492', 'CTI-000370')

    -- ============================================================
    -- Captura do resultado de inserções
    -- ============================================================
    SET @contaInsert = @@ROWCOUNT

    -- ============================================================
    -- Tratamento do corpo do e-mail
    -- ============================================================
    IF (@contaInsert = 0)
    BEGIN
        SET @vBody = '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
                <tr height=20 style=color:black;>
                    <td width=300 style=height:20.0pt>Não houve processos bloqueados.
                        <br>Data dos eventos: ' + CONVERT(VARCHAR(12), @inicio, 105) + '
                        <br>Instância: ' + @@SERVERNAME + '
                    </td>
                </tr>
            </table>
            <br><br>'

        IF @ExibirApenasHtml = 0
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name   = 'CRAVIL'
              , @recipients     = 'suporte@cravil.com.br'
              , @subject        = @vSubject
              , @body           = @vBody
              , @body_format    = 'HTML'
            -- @file_attachments = 'C:\Data\DatabaseMail\robson.png'
        END
        ELSE
        BEGIN
            SELECT @vBody
        END
    END
    ELSE
    BEGIN
        -- ============================================================
        -- Caso tenha registros, monta a mensagem com anexo
        -- ============================================================
        SET @vBody = '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
                <tr height=20 style=color:black;>
                    <td width=300 style=height:20.0pt>Anexo dados de processos bloqueados disponíveis para análise.
                        <br>Os dados coletados são apenas de bloqueios que duraram mais de 10 segundos.
                        <br>Data dos eventos: ' + CONVERT(VARCHAR(12), @inicio, 105) + '
                        <br>Instância: ' + @@SERVERNAME + '
                    </td>
                </tr>
            </table>
            <br><br>'

        -- ============================================================
        -- Montagem da query para anexo CSV
        -- ============================================================
        DECLARE @Query NVARCHAR(MAX)
        DECLARE @tab CHAR(1) = CHAR(9)

        SET @Query = '
        SET NOCOUNT ON;

        SELECT
              ''Segundos'',''Evento'',''Data_Inicio'',''Data_Fim'',''BD'', ''Mode'', ''LockMode'', ''WaitResource''
            , ''Program_Blocked'',''SPID_Blocked'',''Host_Blocked'',''Login_Blocked'',''IsolationLevel_Blocked'', ''Script_Blocked''
            , ''Program_Blocking'',''SPID_Blocking'',''Host_Blocking'',''Login_Blocking'',''IsolationLevel_Blocking'',''Script_Blocking''

        UNION ALL

        SELECT
              Segundos
            , Evento
            , Data_Inicio
            , Data_Fim
            , BD
            , Mode
            , LockMode
            , WaitResource
            , Program_Blocked
            , SPID_Blocked
            , Host_Blocked
            , Login_Blocked
            , IsolationLevel_Blocked
            , Script_Blocked
            , Program_Blocking
            , SPID_Blocking
            , Host_Blocking
            , Login_Blocking
            , IsolationLevel_Blocking
            , Script_Blocking
        FROM ##ReportBlock'

        -- ============================================================
        -- Envio do e-mail com anexo
        -- ============================================================
        IF @ExibirApenasHtml = 0
        BEGIN
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name                   = 'CRAVIL'
              , @recipients                     = 'suporte@cravil.com.br'
              , @subject                        = @vSubject
              , @body                           = @vBody
              , @body_format                    = 'HTML'
              , @query                          = @Query
              , @attach_query_result_as_file    = 1
              , @query_attachment_filename      = 'ProcessosBloqueados.csv'
              , @query_result_header            = 0
              , @query_result_separator         = @tab
              , @query_result_no_padding        = 1
              , @query_result_width             = 32767
            -- @file_attachments = 'C:\Data\DatabaseMail\robson.png'
        END
        ELSE
        BEGIN
            SELECT @vBody
        END

        -- ============================================================
        -- Limpeza da tabela temporária
        -- ============================================================
        IF OBJECT_ID('tempdb..##ReportBlock') IS NOT NULL
        BEGIN
            DROP TABLE ##ReportBlock
        END
    END

    SET NOCOUNT OFF
END
GO

