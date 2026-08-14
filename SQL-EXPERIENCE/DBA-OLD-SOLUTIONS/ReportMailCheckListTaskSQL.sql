/*
 *
    OBJETIVO: Procedure para geração e envio de relatório diário de tarefas do SQL Server,
              incluindo status de backups, jobs, logins com senhas expiradas,
              usuários órfãos e usuários com SID diferente do login.
    PROJETO: mssqlserver-solution-explorer
 *  
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_ReportCheckListTaskSQL
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        DECLARE @subject VARCHAR(100)
              , @recipients VARCHAR(100)
              , @des_MensagemHTML VARCHAR(MAX)

        -- ============================================================
        -- Início do HTML - Cabeçalho
        -- ============================================================
        SET @des_MensagemHTML = '
        <html>
        <head>
        <meta http-equiv=Content-Type content=text/html; charset=windows-1252>
        </head>
        <body>
        <div align=center>'

        -- ============================================================
        -- Título do relatório
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
            <tr height=20 style=height:15.0pt>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>CheckList Diário Task SQL Server - ' + CONVERT(VARCHAR(50), GETDATE(), 103) + '<b></td>
            </tr>
            <tr height=20 style=height:15.0pt>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Informações de Rotinas e Segurança: ' + @@SERVERNAME + '<b></td>
            </tr>
            <tr height=20>
                <td height=20 colspan=7 style=height:20.0pt></td>
            </tr>
        </table>'

        -- ============================================================
        -- Status dos Backups
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center>Status dos Backups</td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 align=left style=height:15.0pt; background: #FFFF00;>
                <td height=20 colspan=7 style=height:15.0pt; text-align:left>
                    Alerta amarelo indica ausência de Backup(s) conforme definido em Jobs.
                </td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td width=200 style=height:20.0pt>Status</td>
                <td width=350 style=height:20.0pt;>Banco de Dados</td>
                <td width=200 style=height:20.0pt;>Tipo Backup</td>
                <td width=200 style=height:20.0pt;>Data Inicio</td>
                <td width=200 style=height:20.0pt;>Data Final</td>
                <td width=150 style=height:20.0pt;>Recovery Model</td>
                <td width=0 style=height:20.0pt;></td>
            </tr>'

        DECLARE @bkp TABLE
        (
              status           VARCHAR(60)
            , banco            VARCHAR(60)
            , tipoBkp          VARCHAR(60)
            , dataInicio       VARCHAR(60)
            , dataFinal        VARCHAR(60)
            , type             VARCHAR(60)
            , backup_finish_date VARCHAR(60)
            , recovery_model   VARCHAR(60)
        )

        ;WITH cte_BackupSets AS
        (
            SELECT
                  MAX(ISNULL([A].[backup_set_id], '')) AS [backup_set_id]
                , ISNULL([A].[type], '') AS [type]
                , ISNULL(UPPER(CONVERT(VARCHAR(100), [B].[name])), '') AS [database_name]
                , MAX(ISNULL([A].[backup_start_date], '')) AS [backup_start_date]
                , MAX(ISNULL([A].[backup_finish_date], '')) AS [backup_finish_date]
                , ISNULL(B.recovery_model_desc, '') AS recovery_model
            FROM [master].[sys].[databases] AS [B]
                LEFT JOIN [msdb].[dbo].[backupset] AS [A]
                    ON [A].[database_name] = [B].[name]
                    AND [A].[type] IN ('D', 'I')
            GROUP BY
                  [B].[name]
                , [A].[type]
                , B.recovery_model_desc

            UNION

            SELECT
                  MAX(ISNULL([A].[backup_set_id], '')) AS [backup_set_id]
                , ISNULL([A].[type], '') AS [type]
                , ISNULL(UPPER(CONVERT(VARCHAR(100), [B].[name])), '') AS [database_name]
                , MAX(ISNULL([A].[backup_start_date], '')) AS [backup_start_date]
                , MAX(ISNULL([A].[backup_finish_date], '')) AS [backup_finish_date]
                , ISNULL(B.recovery_model_desc, '') AS recovery_model
            FROM [master].[sys].[databases] AS [B]
                LEFT JOIN [msdb].[dbo].[backupset] AS [A]
                    ON [A].[database_name] = [B].[name]
                    AND [A].[type] IN ('L')
            GROUP BY
                  [B].[name]
                , [A].[type]
                , B.recovery_model_desc
        )
        , cte_BackupFull AS
        (
            SELECT
                  MAX(ISNULL([backup_set_id], '')) AS [backup_set_id]
                , ISNULL([type], '') AS [type]
                , ISNULL([database_name], '') AS [database_name]
                , MAX(ISNULL([backup_start_date], '')) AS [backup_start_date]
                , MAX(ISNULL([backup_finish_date], '')) AS [backup_finish_date]
                , recovery_model
            FROM [cte_BackupSets]
            GROUP BY
                  [database_name]
                , [type]
                , recovery_model
        )

        INSERT INTO @bkp
        SELECT
              ISNULL(CAST(
                  CASE
                      WHEN [A].[type] = 'D'
                          AND CAST(DATEDIFF(DAY, ISNULL([A].[backup_finish_date], ''), GETDATE()) AS VARCHAR(10)) > 1
                          AND A.database_name NOT LIKE '%homolog%'
                          THEN 'WARNING'
                      WHEN [A].[type] = 'D'
                          AND CAST(DATEDIFF(DAY, ISNULL([A].[backup_finish_date], ''), GETDATE()) AS VARCHAR(10)) > 1
                          AND A.database_name LIKE '%homolog%'
                          THEN 'DESNECESSÁRIO'
                      WHEN ([A].[type] = 'I')
                          AND ((DATEDIFF(DAY, ISNULL([A].[backup_finish_date], ''), GETDATE()) >= 2
                          AND DATEPART(WEEKDAY, ISNULL([A].[backup_finish_date], '')) <> 6)
                          OR (DATEDIFF(DAY, ISNULL([A].[backup_finish_date], ''), GETDATE()) > 3
                          AND DATEPART(WEEKDAY, ISNULL([A].[backup_finish_date], '')) = 6))
                          AND A.database_name NOT LIKE '%homolog%'
                          THEN 'WARNING'
                      WHEN ([A].[type] = 'I')
                          AND ((DATEDIFF(DAY, ISNULL([A].[backup_finish_date], ''), GETDATE()) >= 2
                          AND DATEPART(WEEKDAY, ISNULL([A].[backup_finish_date], '')) <> 6)
                          OR (DATEDIFF(DAY, ISNULL([A].[backup_finish_date], ''), GETDATE()) > 3
                          AND DATEPART(WEEKDAY, ISNULL([A].[backup_finish_date], '')) = 6))
                          AND A.database_name LIKE '%homolog%'
                          THEN 'DESNECESSÁRIO'
                      WHEN [A].[type] = 'L'
                          AND CAST(DATEDIFF(HOUR, ISNULL([A].[backup_finish_date], ''), GETDATE()) AS VARCHAR(10)) > 1
                          AND A.database_name LIKE '%homolog%'
                          THEN 'DESNECESSÁRIO'
                      WHEN [A].[type] = 'L'
                          AND CAST(DATEDIFF(HOUR, ISNULL([A].[backup_finish_date], ''), GETDATE()) AS VARCHAR(10)) > 1
                          AND A.database_name NOT LIKE '%homolog%'
                          AND A.recovery_model <> 'SIMPLE'
                          THEN 'WARNING'
                      WHEN [A].[type] = 'L'
                          AND CAST(DATEDIFF(HOUR, ISNULL([A].[backup_finish_date], ''), GETDATE()) AS VARCHAR(10)) > 1
                          AND A.database_name NOT LIKE '%homolog%'
                          AND A.recovery_model = 'SIMPLE'
                          THEN 'DESNECESSÁRIO'
                      WHEN ([A].[type] IS NULL OR A.type = '')
                          AND A.recovery_model = 'SIMPLE'
                          THEN 'DESNECESSÁRIO'
                      WHEN ([A].[type] IS NULL OR A.type = '')
                          AND A.recovery_model <> 'SIMPLE'
                          AND A.database_name LIKE '%homolog%'
                          THEN 'DESNECESSÁRIO'
                      WHEN ([A].[type] IS NULL OR A.type = '')
                          AND A.recovery_model <> 'SIMPLE'
                          AND A.database_name NOT LIKE '%homolog%'
                          THEN 'WARNING'
                      ELSE 'Ok'
                  END AS VARCHAR(MAX)), '') AS Status
                , UPPER(CAST(ISNULL([A].[database_name], '') AS VARCHAR(100))) AS Banco
                , ISNULL(CAST(
                      CASE [A].[type]
                          WHEN 'D' THEN 'Full'
                          WHEN 'I' THEN 'Differential'
                          WHEN 'L' THEN 'Log'
                          WHEN 'F' THEN 'File or Filegroup'
                          WHEN 'G' THEN 'File Differential'
                          WHEN 'P' THEN 'Partial'
                          WHEN 'Q' THEN 'Partial Differential'
                          ELSE 'Sem Backup'
                      END AS VARCHAR(MAX)), '') AS TipoBkp
                , ISNULL(CAST(ISNULL(CONVERT(VARCHAR(50), [A].[backup_start_date]), '') AS VARCHAR(MAX)), '') AS dataInicio
                , ISNULL(CAST(ISNULL(CONVERT(VARCHAR(50), [A].[backup_finish_date]), '') AS VARCHAR(MAX)), '') AS dataFinal
                , ISNULL(A.type, '') AS type
                , ISNULL(A.backup_finish_date, '') AS backup_finish_date
                , recovery_model
        FROM [cte_BackupFull] AS [A]
        WHERE A.database_name NOT IN ('master', 'tempdb', 'model', 'msdb')
        ORDER BY
              [A].[database_name]
            , [type]

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               CASE
                   WHEN b.status = 'WARNING' THEN '<tr height=20 style=height:15.0pt;background: #FFFF00>'
                   ELSE CASE
                            WHEN CAST(ROW_NUMBER() OVER(ORDER BY b.banco, [type] ASC) % 2 AS BIT) = 1
                                THEN '<tr height=20 style=height:15.0pt>'
                            ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
                        END
               END +
               '<td height=20 style=height:15.0pt>' + b.status + '</td>' +
               '<td height=20 style=height:15.0pt>' + b.banco + '</td>' +
               '<td height=20 style=height:15.0pt>' + b.tipoBkp + '</td>' +
               '<td height=20 style=height:15.0pt>' + b.dataInicio + '</td>' +
               '<td height=20 style=height:15.0pt>' + b.dataFinal + '</td>' +
               '<td height=20 style=height:15.0pt>' + b.recovery_model + '</td>' +
               '<td width=0 style=height:15.0pt;></td>'
        FROM @bkp AS b

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</tr></table>'

        -- ============================================================
        -- Status dos Jobs
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '<br>
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center>Status dos Jobs</td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 align=left style=height:15.0pt; background: #37C1F8;>
                <td height=20 colspan=7 style=height:15.0pt; text-align:left>
                    Alerta Azul indica Job desabilitada sem identificação de falha na última execução.
                </td>
            </tr>
            <tr height=20 align=left style=height:15.0pt; background: #FFFF00;>
                <td height=20 colspan=7 style=height:15.0pt; text-align:left>
                    Alerta Amarelo indica Job habilitada com status cancelada, tente novamente ou desconhecida (histórico ausente na Job).
                </td>
            </tr>
            <tr height=20 align=left style=height:15.0pt; background: #FF0000;>
                <td height=20 colspan=7 style=height:15.0pt; text-align:left>
                    Alerta Vermelho indica falha na execução da Job.
                </td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td width=350 style=height:20.0pt>Nome Job</td>
                <td width=150 style=height:20.0pt;>Status</td>
                <td width=150 style=height:20.0pt;>Última Execução</td>
                <td width=200 style=height:20.0pt;>Data Inicio</td>
                <td width=200 style=height:20.0pt;>Data Final</td>
                <td width=150 style=height:20.0pt;>Duração [dd hh:mm:ss]</td>
                <td width=0 style=height:20.0pt;></td>
            </tr>'

        DECLARE @job TABLE
        (
              nome         VARCHAR(200)
            , status       VARCHAR(100)
            , ultimaExec   VARCHAR(100)
            , datainicio   VARCHAR(50)
            , datafim      VARCHAR(50)
            , run_status   INT
            , run_time     INT
            , run_date     INT
        )

        ;WITH cteJob AS
        (
            SELECT
                  MAX(ISNULL([sjh].[instance_id], '')) AS [instance_id]
                , [sj].[job_id]
                , [sj].[name]
                , [sj].[enabled]
            FROM [msdb]..[sysjobs] AS [sj]
                LEFT JOIN [msdb]..[sysjobhistory] AS [sjh]
                    ON [sjh].[job_id] = [sj].[job_id]
                    AND [sjh].[step_id] = 0
            GROUP BY
                  [sj].[job_id]
                , [sj].[name]
                , [sj].[enabled]
        )

        INSERT INTO @job
        SELECT
              CAST(ISNULL([j].[name], '') AS VARCHAR(200)) AS nome
            , ISNULL(CAST(
                  CASE
                      WHEN [j].[enabled] = 1 THEN 'Enabled'
                      ELSE 'Disabled'
                  END AS VARCHAR(100)), '') AS status
            , ISNULL(CAST(
                  CASE
                      WHEN [h].[run_status] = 0 THEN 'Falha'
                      WHEN [h].[run_status] = 1 THEN 'Sucesso'
                      WHEN [h].[run_status] = 2 THEN 'Tente Novamente'
                      WHEN [h].[run_status] = 3 THEN 'Cancelado'
                      ELSE 'Desconhecido'
                  END AS VARCHAR(100)), '') AS UltimaExec
            , ISNULL(CAST(
                  CASE
                      WHEN ISNULL([h].[run_date], 0) = 0 THEN ''
                      ELSE CONVERT(VARCHAR, [msdb].[dbo].[agent_datetime](
                          CASE
                              WHEN ISNULL([h].[run_date], 0) = 0 THEN 17530101
                              ELSE [h].[run_date]
                          END, ISNULL([h].[run_time], 0)), 113)
                  END AS VARCHAR(50)), '') AS dataInicio
            , ISNULL(CAST(
                  CASE
                      WHEN [h].[run_duration] IS NULL THEN ''
                      ELSE CONVERT(VARCHAR, DATEADD(SECOND,
                          YOUR_DATABASE.[Management].[fn_JobIntToSeconds](ISNULL([h].[run_duration], '')),
                          [msdb].[dbo].[agent_datetime](
                              CASE
                                  WHEN ISNULL([h].[run_date], 0) = 0 THEN 17530101
                                  ELSE [h].[run_date]
                              END, ISNULL([h].[run_time], 0))), 113)
                  END AS VARCHAR(50)), '') AS dataFim
            , ISNULL(h.run_status, 0) AS run_status
            , ISNULL(h.run_time, 0) AS run_time
            , CASE
                  WHEN ISNULL(h.run_date, 0) = 0 THEN 17530101
                  ELSE h.run_date
              END AS run_date
        FROM [cteJob] AS [j]
            LEFT JOIN [msdb].[dbo].[sysjobhistory] AS [h]
                ON [j].[instance_id] = [h].[instance_id]
                AND [h].[step_id] = 0
        ORDER BY
              [j].[name]
            , [msdb].[dbo].[agent_datetime]([h].[run_date], [h].[run_time]) DESC

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               CASE
                   WHEN j.ultimaExec = 'Falha' THEN '<tr height=20 style=height:15.0pt;background: #FF0000>'
                   WHEN j.status = 'Enabled'
                       AND j.ultimaExec IN ('Tente Novamente', 'Cancelado', 'Desconhecido')
                       THEN '<tr height=20 style=height:15.0pt;background: #FFFF00>'
                   WHEN j.status = 'Disabled'
                       AND j.ultimaExec IN ('Tente Novamente', 'Cancelado', 'Desconhecido', 'sucesso')
                       THEN '<tr height=20 style=height:15.0pt;background: #37C1F8>'
                   ELSE CASE
                            WHEN CAST(ROW_NUMBER() OVER(ORDER BY j.nome, [msdb].[dbo].[agent_datetime](j.run_date, j.run_time) DESC) % 2 AS BIT) = 1
                                THEN '<tr height=20 style=height:15.0pt>'
                            ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
                        END
               END +
               '<td height=20 style=height:15.0pt>' + j.Nome + '</td>' +
               '<td height=20 style=height:15.0pt>' + j.status + '</td>' +
               '<td height=20 style=height:15.0pt>' + j.ultimaExec + '</td>' +
               '<td height=20 style=height:15.0pt>' + j.datainicio + '</td>' +
               '<td height=20 style=height:15.0pt>' + j.datafim + '</td>' +
               '<td height=20 style=height:15.0pt>' +
               (SELECT Management.fn_CalculateDifferenceTime(ISNULL(j.datainicio, ''), ISNULL(j.datafim, ''))) +
               '</td>' +
               '<td width=0 style=height:15.0pt;></td>'
        FROM @job AS j

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</tr></table>'

        -- ============================================================
        -- Mensagens das Jobs
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '<br>
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center>Mensagens das Jobs</td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 align=left style=height:15.0pt; background: #FFFF00;>
                <td height=20 colspan=7 style=height:15.0pt; text-align:left>
                    Alerta amarelo apresenta maiores detalhes da Job com falha.
                </td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td width=300 style=height:20.0pt>Nome Job</td>
                <td width=100 style=height:20.0pt;>Última Execução</td>
                <td width=600 style=height:20.0pt;>Mensagem</td>
                <td width=20 style=height:20.0pt;></td>
                <td width=200 style=height:20.0pt;>Data</td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
            </tr>'

        DECLARE @Jobs1 TABLE
        (
              Seq       INT IDENTITY
            , name      SYSNAME
            , status    VARCHAR(50)
            , message   NVARCHAR(4000)
            , data_hora DATETIME
            , step_Id   INT
        )

        DECLARE @Jobs2 TABLE
        (
              Seq       INT IDENTITY
            , name      SYSNAME
            , status    VARCHAR(50)
            , message   NVARCHAR(4000)
            , data_hora DATETIME
            , step_Id   INT
        )

        INSERT INTO @Jobs1
        SELECT
              j.name
            , CASE h.run_status
                  WHEN 0 THEN 'Falha'
                  WHEN 1 THEN 'Sucesso'
                  WHEN 2 THEN 'Repetir'
                  WHEN 3 THEN 'Cancelado'
                  WHEN 4 THEN 'Em Progresso'
              END AS [status]
            , h.message
            , YOUR_DATABASE.Management.fn_ConverteDatetimeJobs(h.run_date, h.run_time) AS Data_Hora
            , h.step_id
        FROM msdb.dbo.sysjobs j
            CROSS APPLY
            (
                SELECT TOP 1
                      h.run_date
                    , h.run_time
                    , h.run_status
                    , h.message
                    , h.step_id
                FROM msdb.dbo.sysjobhistory h
                WHERE h.step_id = 0
                    AND h.job_id = j.job_id
                ORDER BY h.instance_id DESC
            ) h
        ORDER BY J.name

        INSERT INTO @Jobs2
        SELECT
              j.name
            , CASE h.run_status
                  WHEN 0 THEN 'Falha'
                  WHEN 1 THEN 'Sucesso'
                  WHEN 2 THEN 'Repetir'
                  WHEN 3 THEN 'Cancelado'
                  WHEN 4 THEN 'Em Progresso'
              END AS [status]
            , h.message
            , YOUR_DATABASE.Management.fn_ConverteDatetimeJobs(h.run_date, h.run_time) AS Data_Hora
            , h.step_id
        FROM msdb.dbo.sysjobs j
            CROSS APPLY
            (
                SELECT TOP 1
                      h.run_date
                    , h.run_time
                    , h.run_status
                    , h.message
                    , h.step_id
                FROM msdb.dbo.sysjobhistory h
                WHERE h.step_id <> 0
                    AND h.job_id = j.job_id
                ORDER BY h.instance_id DESC
            ) h
        ORDER BY J.name

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               CASE
                   WHEN t1.status <> 'Sucesso' THEN '<tr height=20 style=height:15.0pt;background: #FFFF00>'
                   ELSE CASE
                            WHEN CAST(ROW_NUMBER() OVER(ORDER BY t1.name ASC) % 2 AS BIT) = 1
                                THEN '<tr height=20 style=height:15.0pt>'
                            ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
                        END
               END +
               '<td height=20 style=height:15.0pt>' + t1.name + '</td>' +
               '<td height=20 style=height:15.0pt>' + t1.status + '</td>' +
               '<td height=20 style=height:15.0pt>' + t1.message + ' EXECUÇÃO DA ETAPA [ ' + CAST(t2.step_Id AS VARCHAR(2)) + ' ] -> ' + t2.message + '</td>' +
               '<td width=0 style=height:15.0pt;></td>' +
               '<td height=20 style=height:15.0pt>' + CONVERT(VARCHAR(30), t1.data_hora, 113) + '</td>' +
               '<td width=0 style=height:15.0pt;></td>' +
               '<td width=0 style=height:15.0pt;></td>'
        FROM @Jobs1 AS t1
            INNER JOIN @Jobs2 AS t2
                ON t1.Seq = t2.Seq

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</tr></table>'

        -- ============================================================
        -- Informações de Logins/Users - Título
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
            <tr height=20>
                <td height=20 colspan=7 style=height:20.0pt></td>
            </tr>
            <tr height=20 style=height:15.0pt>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Informações de Logins/Users<b></td>
            </tr>
            <tr height=20>
                <td height=20 colspan=7 style=height:20.0pt></td>
            </tr>
        </table>'

        -- ============================================================
        -- Logins com senhas expiradas
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center>Logins com senhas expiradas</td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td width=200 style=height:20.0pt>Login</td>
                <td width=200 style=height:20.0pt;>Última Alteração</td>
                <td width=200 style=height:20.0pt;>Data Expiração</td>
                <td width=100 style=height:20.0pt;>Policy</td>
                <td width=100 style=height:20.0pt;>Expirada</td>
                <td width=100 style=height:20.0pt;>Must Change</td>
                <td width=100 style=height:20.0pt;>Locked</td>
                <td width=100 style=height:20.0pt;>Tentativas Erradas</td>
            </tr>'

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               CASE
                   WHEN CAST(ROW_NUMBER() OVER(
                       ORDER BY
                           ISNULL(CAST(LOGINPROPERTY([SL].[name], 'IsExpired') AS VARCHAR(MAX)), '') DESC
                         , DATEADD(DD, CONVERT(INT, LOGINPROPERTY([SL].[name], 'DaysUntilExpiration')),
                               CONVERT(DATETIME, LOGINPROPERTY([SL].[name], 'PasswordLastSetTime'))) ASC) % 2 AS BIT) = 1
                       THEN '<tr height=20 style=height:15.0pt>'
                   ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
               END +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST([SL].[name] AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST(LOGINPROPERTY([SL].[name], 'PasswordLastSetTime') AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST(DATEADD(DD, CONVERT(INT, LOGINPROPERTY([SL].[name], 'DaysUntilExpiration')), CONVERT(DATETIME, LOGINPROPERTY([SL].[name], 'PasswordLastSetTime'))) AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST([SL].[is_policy_checked] AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST(LOGINPROPERTY([SL].[name], 'IsExpired') AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST(LOGINPROPERTY([SL].[name], 'IsMustChange') AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST(LOGINPROPERTY([SL].[name], 'IsLocked') AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST(LOGINPROPERTY([SL].[name], 'BadPasswordCount') AS VARCHAR(MAX)), '') + '</td><tr>'
        FROM [sys].[sql_logins] AS [SL]
        WHERE LOGINPROPERTY([SL].[name], 'IsExpired') = 1
            OR LOGINPROPERTY([SL].[name], 'DaysUntilExpiration') <= 1
        ORDER BY
              ISNULL(CAST(LOGINPROPERTY([SL].[name], 'IsExpired') AS VARCHAR(MAX)), '') DESC
            , DATEADD(DD, CONVERT(INT, LOGINPROPERTY([SL].[name], 'DaysUntilExpiration')),
                  CONVERT(DATETIME, LOGINPROPERTY([SL].[name], 'PasswordLastSetTime'))) ASC

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</table>'

        -- ============================================================
        -- Usuários órfãos
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '<br><br>
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center>Usuários Órfãos</td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td width=300 style=height:20.0pt>Banco de Dados</td>
                <td width=300 style=height:20.0pt;>Usuário</td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
            </tr>'

        CREATE TABLE ##tb_UsuariosOrfaos
        (
              [Database_Name] VARCHAR(255)
            , [Name]          VARCHAR(255)
        )

        EXEC [sp_MSforeachdb] '
        INSERT INTO ##tb_UsuariosOrfaos
        SELECT ''?'' AS database_name, B.name
        FROM master.sys.syslogins A
            RIGHT JOIN [?].sys.sysusers B
                ON A.name COLLATE Latin1_General_CI_AI = B.name COLLATE Latin1_General_CI_AI
        WHERE A.sid IS NULL
            AND B.issqlrole <> 1
            AND B.isapprole <> 1
            AND (B.name <> ''INFORMATION_SCHEMA''
                AND B.name NOT IN (''guest'', ''sys'', ''dbo'')
                AND B.name <> ''system_function_schema'')'

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               CASE
                   WHEN CAST(ROW_NUMBER() OVER(ORDER BY [Database_Name], [Name]) % 2 AS BIT) = 1
                       THEN '<tr height=20 style=height:15.0pt>'
                   ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
               END +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST([Database_Name] AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST([Name] AS VARCHAR(MAX)), '') + '</td>' +
               '<td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td></tr>'
        FROM ##tb_UsuariosOrfaos
        ORDER BY [Database_Name], [Name]

        DROP TABLE ##tb_UsuariosOrfaos

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</table>'

        -- ============================================================
        -- Usuários com SID diferentes do Login
        -- ============================================================
        SET @des_MensagemHTML = @des_MensagemHTML + '<br>
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:18px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td height=20 colspan=7 style=height:20.0pt;text-align:center>Usuários com SID diferentes do Login</td>
            </tr>
        </table>'

        SET @des_MensagemHTML = @des_MensagemHTML + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
            <tr height=20 style=color: #FFFFFF; background: #44546A;>
                <td width=300 style=height:20.0pt>Banco de Dados</td>
                <td width=300 style=height:20.0pt;>Usuário</td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
                <td width=0 style=height:20.0pt;></td>
            </tr>'

        CREATE TABLE ##tb_UsuariosSID
        (
              [Database_Name] VARCHAR(255)
            , [Name]          VARCHAR(255)
        )

        EXEC [sp_MSforeachdb] '
        INSERT INTO ##tb_UsuariosSID
        SELECT ''?'' AS database_name, B.name
        FROM master.sys.syslogins A
            INNER JOIN [?].sys.sysusers B
                ON A.name COLLATE Latin1_General_CI_AI = B.name COLLATE Latin1_General_CI_AI
                AND A.SId <> B.SId
        WHERE B.issqlrole <> 1
            AND B.isapprole <> 1
            AND (B.name <> ''INFORMATION_SCHEMA''
                AND B.name NOT IN (''guest'', ''sys'', ''dbo'')
                AND B.name <> ''system_function_schema'')'

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               CASE
                   WHEN CAST(ROW_NUMBER() OVER(ORDER BY [Database_Name], [Name]) % 2 AS BIT) = 1
                       THEN '<tr height=20 style=height:15.0pt>'
                   ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
               END +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST([Database_Name] AS VARCHAR(MAX)), '') + '</td>' +
               '<td height=20 style=height:15.0pt>' + ISNULL(CAST([Name] AS VARCHAR(MAX)), '') + '</td>' +
               '<td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td>
                <td width=0 style=height:15.0pt;></td></tr>'
        FROM ##tb_UsuariosSID
        ORDER BY [Database_Name], [Name]

        DROP TABLE ##tb_UsuariosSID

        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</table>'

        -- ============================================================
        -- Final do HTML
        -- ============================================================
        SELECT @des_MensagemHTML = @des_MensagemHTML +
               '</div>
                </body>
                </html>'

        -- ============================================================
        -- Envio do e-mail
        -- ============================================================
        SET @subject = 'CheckList Diário - Task SQL Server: ' + @@SERVERNAME
        SET @recipients = 'agenteti@cravil.com.br'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @des_MensagemHTML
          , @body_format  = 'HTML'

        COMMIT TRANSACTION

    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Captura de exceção e montagem do e-mail de falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'agenteti@cravil.com.br'

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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure sp_ReportCheckListTaskSQL:<b> <br>
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

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET NOCOUNT OFF
END
GO
