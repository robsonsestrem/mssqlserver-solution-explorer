/*
 *
	OBJETIVO: Monitoramento e alerta de Page Life Expectancy (PLE) no SQL Server,
	          incluindo criação de tabela de histórico, Job de coleta, Alertas
	          e Procedures de manutenção e notificação.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://simplesqlserver.com/2013/08/19/fixing-page-life-expectancy-ple/
 *	http://www.dbinternals.com.br/?p=1252
 *	https://www.sqlskills.com/blogs/jonathan/how-much-memory-does-my-sql-server-actually-need/
 *	https://catao.wordpress.com/2008/11/07/envio-de-alerta-de-falha-do-job-com-o-database-mail/
 *	http://blogdofernandoguarany.blogspot.com.br/2014/05/criando-jobs.html
 *	https://docs.microsoft.com/pt-br/sql/ssms/agent/assign-alerts-to-an-operator#SSMSProcedure
 *	https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-operator-transact-sql
 *	https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-notification-transact-sql
 *	https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-update-alert-transact-sql
 *	https://medium.com/@pelegrini/indicadores-do-sql-server-page-life-expectancy-b82d0d0a377b
 *	https://blog.sqlauthority.com/2014/05/01/sql-server-good-value-for-page-life-expectancy-notes-from-the-field-026/
 */
-- ============================================================
-- Monitoramento de Page Life Expectancy (PLE)
-- ============================================================
-- Cálculo do tamanho do Cache Size em GB para definição do limite ideal de PLE
SELECT
    COUNT(*) * 8 / 1024 / 1024 AS [Cached Size (GB)]
FROM [sys].[dm_os_buffer_descriptors];
-- Resultado de exemplo: 114 GB
-- Cálculo do valor mínimo recomendado: ((114 GB / 128 GB de memória disponível) * 300) = ~267 segundos

USE [DBA_PerformanceHub];
GO

-- Criação da tabela de histórico de contadores de performance
CREATE TABLE [Management].[CountPLE]
(
    [DateCount] [DATETIME] NOT NULL,
    [ObjectName] [NCHAR](128) NOT NULL,
    [CounterName] [NCHAR](128) NOT NULL,
    [CounterValue] [BIGINT] NOT NULL,
    [IdealCalculado] [DECIMAL](15, 2) NULL,
    CONSTRAINT [PK_tb_ContadorPerformance] PRIMARY KEY ([DateCount], [ObjectName], [CounterName])
)
ON [PRIMARY];
GO

-- Consulta de teste para validação do insert que será executado pela Job
SELECT
    GETDATE() AS [dth_Contador]
  , [object_name] AS [des_Objeto]
  , [counter_name] AS [des_Contador]
  , [cntr_value] AS [val_Contador]
  , (
        SELECT CAST(
            (
                SELECT COUNT(*) * 8. / 1024. / 1024. AS [Cached Size (GB)]
                FROM [sys].[dm_os_buffer_descriptors]
            ) / 128. * 300. AS DECIMAL(15, 2)
        )
    ) AS [ideal_calculado]
FROM [sys].[dm_os_performance_counters]
WHERE [object_name] LIKE '%Manager%'
  AND [counter_name] = 'Page life expectancy';


-- ============================================================
-- Criação da Job para geração do histórico de PLE
-- ============================================================
USE [msdb];
GO

BEGIN TRANSACTION;
DECLARE @ReturnCode INT;
SELECT @ReturnCode = 0;

-- Verifica e cria a categoria da Job se não existir
IF NOT EXISTS (
    SELECT [name]
    FROM [msdb].[dbo].[syscategories]
    WHERE [name] = N'Database DBA_PerformanceHub'
      AND [category_class] = 1
)
BEGIN
    EXEC @ReturnCode = [msdb].[dbo].[sp_add_category]
        @class = N'JOB',
        @type = N'LOCAL',
        @name = N'Database DBA_PerformanceHub';

    IF (@@ERROR <> 0 OR @ReturnCode <> 0)
        GOTO QuitWithRollback;
END

DECLARE @jobId BINARY(16);

-- Adiciona a Job
EXEC @ReturnCode = [msdb].[dbo].[sp_add_job]
    @job_name = N'TI_PageLifeExpectancy',
    @enabled = 1,
    @notify_level_eventlog = 0,
    @notify_level_email = 0,
    @notify_level_netsend = 0,
    @notify_level_page = 0,
    @delete_level = 0,
    @description = N'Coleta histórica do contador Page Life Expectancy.',
    @category_name = N'Database DBA_PerformanceHub',
    @owner_login_name = N'admcravil',
    @job_id = @jobId OUTPUT;

IF (@@ERROR <> 0 OR @ReturnCode <> 0)
    GOTO QuitWithRollback;

-- Adiciona o passo da Job com o comando T-SQL de insert
EXEC @ReturnCode = [msdb].[dbo].[sp_add_jobstep]
    @job_id = @jobId,
    @step_name = N'Page_Life_Expectancy',
    @step_id = 1,
    @cmdexec_success_code = 0,
    @on_success_action = 1,
    @on_success_step_id = 0,
    @on_fail_action = 2,
    @on_fail_step_id = 0,
    @retry_attempts = 0,
    @retry_interval = 0,
    @os_run_priority = 0,
    @subsystem = N'TSQL',
    @command = N'INSERT INTO [DBA_PerformanceHub].[Management].[CountPLE]
    SELECT
        GETDATE() AS [dth_Contador]
      , [object_name] AS [des_Objeto]
      , [counter_name] AS [des_Contador]
      , [cntr_value] AS [val_Contador]
      , (
            SELECT CAST(
                (
                    SELECT COUNT(*) * 8. / 1024. / 1024. AS [Cached Size (GB)]
                    FROM [sys].[dm_os_buffer_descriptors]
                ) / 128. * 300. AS DECIMAL(15, 2)
            )
        ) AS [ideal_calculado]
    FROM [sys].[dm_os_performance_counters]
    WHERE [object_name] LIKE ''%Manager%''
      AND [counter_name] = ''Page life expectancy'';',
    @database_name = N'DBA_PerformanceHub',
    @flags = 0;

IF (@@ERROR <> 0 OR @ReturnCode <> 0)
    GOTO QuitWithRollback;

-- Atualiza o passo inicial da Job
EXEC @ReturnCode = [msdb].[dbo].[sp_update_job]
    @job_id = @jobId,
    @start_step_id = 1;

IF (@@ERROR <> 0 OR @ReturnCode <> 0)
    GOTO QuitWithRollback;

-- Associa a Job ao servidor local
EXEC @ReturnCode = [msdb].[dbo].[sp_add_jobserver]
    @job_id = @jobId,
    @server_name = N'(local)';

IF (@@ERROR <> 0 OR @ReturnCode <> 0)
    GOTO QuitWithRollback;

COMMIT TRANSACTION;
GOTO EndSave;

QuitWithRollback:
    IF (@@TRANCOUNT > 0)
        ROLLBACK TRANSACTION;

EndSave:
GO

-- Consulta para descobrir o ID da Job e utilizar na configuração do Alerta
SELECT
    [job_id]
  , [name]
FROM [msdb].[dbo].[sysjobs]
WHERE [name] = N'TI_PageLifeExpectancy';


-- ============================================================
-- Criação do Alerta de Page Life Expectancy
-- ============================================================
USE [msdb];
GO

EXEC [msdb].[dbo].[sp_add_alert]
    @name = N'PageLifeExpectancy',
    @message_id = 0,
    @severity = 0,
    @enabled = 1,
    @delay_between_responses = 30,
    @include_event_description_in = 1,
    @notification_message = N'ATENÇÃO! Page Life Expectancy < 200 segundos. Esse contador indica o tempo em segundos que uma página de memória permanece no cache. Quanto maior esse tempo, maior a chance do SQL Server encontrar a informação necessária sem realizar busca em disco.',
    @category_name = N'[Uncategorized]',
    @performance_condition = N'SQLServer:Buffer Manager|Page life expectancy||<|200',
    @job_id = N'2be5100d-b70d-48fc-aee4-5b5ab0391eb1'; -- Substituir pelo job_id real obtido na consulta anterior
GO

-- Adição do Operador para recebimento dos alertas
USE [msdb];
GO

EXEC [msdb].[dbo].[sp_add_operator]
    @name = N'DBA_Alerts_SetorTI',
    @enabled = 1,
    @weekday_pager_start_time = 0,
    @weekday_pager_end_time = 120000,
    @saturday_pager_start_time = 0,
    @saturday_pager_end_time = 120000,
    @sunday_pager_start_time = 0,
    @sunday_pager_end_time = 120000,
    @pager_days = 0,
    @email_address = N'suporte@cravil.com.br',
    @category_name = N'[Uncategorized]';
GO

-- Vinculação da notificação por e-mail ao Alerta (utilizando perfil do Database Mail)
EXEC [msdb].[dbo].[sp_add_notification]
    @alert_name = N'PageLifeExpectancy',
    @operator_name = N'DBA_Alerts_SetorTI',
    @notification_method = 1;
GO


-- ============================================================
-- Cálculo dos limites ideais de PLE com base 
-- na memória configurada e no cache atual
-- ============================================================
WITH [tm_cte] AS (
    SELECT
        CONVERT(INT, [value_in_use]) / 1024. AS [memory_gb]
      , CONVERT(INT, [value_in_use]) / 1024. / 4. * 300. AS [counter_by_memory]
    FROM [sys].[configurations]
    WHERE [name] LIKE 'max server memory%'
),
[cached_cte] AS (
    SELECT
        COUNT(*) * 8. / 1024. / 1024. AS [cached_gb]
      , COUNT(*) * 8. / 1024. / 1024. / 4. * 300. AS [counter_by_cache]
    FROM [sys].[dm_os_buffer_descriptors]
)
SELECT
    CEILING([counter_by_memory]) AS [Limite 1]
  , CEILING([counter_by_cache]) AS [Limite 2]
FROM [tm_cte], [cached_cte];


-- ============================================================
-- Procedure para limpeza do histórico de PLE, 
-- mantendo apenas a quantidade de dias configurada
-- ============================================================
USE [YOUR_DATABASE];
GO

CREATE OR ALTER PROCEDURE [Management].[sp_DeleteCountPLE]
    @qtdadeManterDias INT = 60 -- Quantidade de dias para manter no histórico
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @qtdadeDias INT;
        DECLARE @dataMin DATE;

        -- Calcula a quantidade atual de dias distintos com registros
        SET @qtdadeDias = (
            SELECT COUNT([x].[Registros])
            FROM (
                SELECT COUNT(*) AS [Registros]
                FROM [YOUR_DATABASE].[Management].[CountPLE] AS [t1]
                GROUP BY CAST([t1].[DateCount] AS DATE)
            ) AS [x]
        );

        -- Loop para excluir dias antigos até atingir a quantidade desejada
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin = (
                SELECT CAST(DATEADD(DAY, 1, (SELECT MIN([t1].[DateCount]) FROM [YOUR_DATABASE].[Management].[CountPLE] AS [t1])) AS DATE)
            );

            DELETE FROM [YOUR_DATABASE].[Management].[CountPLE]
            WHERE [DateCount] < @dataMin;

            SET @qtdadeDias -= 1;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @corpoFalha VARCHAR(MAX);
        DECLARE @subject VARCHAR(100);
        DECLARE @recipients VARCHAR(100);

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';
        
        SET @corpoFalha = '
        <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
        </head>
        <body>
        <div align="left">';

        SELECT @corpoFalha = @corpoFalha + '
        <table border="0" cellpadding="0" cellspacing="0" width="402" style="border-collapse: collapse; table-layout: fixed; width: 1000pt; font-family: Arial; font-size: 14px;">
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <b>Falha na procedure [sp_DeleteCountPLE]:</b><br>
                </td>
            </tr>
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                    <br><br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                    <br><br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                </td>
            </tr>
        </table>';

        SELECT @corpoFalha = @corpoFalha + '
        </div>
        </body>
        </html>';

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML';
    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
END
GO


-- ============================================================
-- Procedure para verificação e 
-- alerta de PLE abaixo do ideal calculado
-- ============================================================
USE [YOUR_DATABASE];
GO

CREATE OR ALTER PROCEDURE [Management].[sp_AlertPLE]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @assuntoEmail NVARCHAR(70);
        DECLARE @CorpoEmail NVARCHAR(MAX);
        DECLARE @contadorDmv BIGINT;
        DECLARE @idealCalculado DECIMAL(15, 2);

        -- Obtém o valor atual do contador Page Life Expectancy
        SET @contadorDmv = (
            SELECT [cntr_value]
            FROM [sys].[dm_os_performance_counters]
            WHERE [object_name] LIKE '%Manager%'
              AND [counter_name] = 'Page life expectancy'
        );

        -- Calcula o valor ideal baseado no Cached Size
        SET @idealCalculado = (
            SELECT CAST(
                (
                    (
                        SELECT COUNT(*) * 8. / 1024. / 1024. AS [Cached Size (GB)]
                        FROM [sys].[dm_os_buffer_descriptors]
                    ) / 128. * 300.
                ) AS DECIMAL(15, 2)
            )
        );

        -- Se o contador estiver abaixo do ideal, registra e envia alerta
        IF (@contadorDmv < @idealCalculado)
        BEGIN
            -- Inserção do histórico do evento de alerta
            INSERT INTO [YOUR_DATABASE].[Management].[CountPLE]
            SELECT
                GETDATE() AS [dth_Contador]
              , [object_name] AS [des_Objeto]
              , [counter_name] AS [des_Contador]
              , [cntr_value] AS [val_Contador]
              , @idealCalculado AS [ideal_calculado]
            FROM [sys].[dm_os_performance_counters]
            WHERE [object_name] LIKE '%Manager%'
              AND [counter_name] = 'Page life expectancy';

            -- Montagem do corpo do e-mail de alerta
            SET @CorpoEmail = '
            <table border="0" cellpadding="0" cellspacing="0" width="402" style="border-collapse: collapse; table-layout: fixed; width: 1000pt; font-family: Arial; font-size: 14px;">
                <tr height="20" style="color: black;">
                    <td width="300" style="height: 20.0pt;">
                        <b>Data:</b> ' + CONVERT(VARCHAR(30), GETDATE(), 113) + '<br><br>
                        <b>Descrição:</b> O contador de desempenho do SQL Server <b>''Page Life Expectancy''</b> do objeto ''Buffer Manager'' está abaixo do ideal de ' + CAST(@idealCalculado AS VARCHAR(10)) + ', valor atual é de ' + CAST(@contadorDmv AS VARCHAR(20)) + '.<br><br>
                        <b>Obs.:</b> Esse contador nos diz o tempo em segundos que uma página de memória fica no cache. Quanto maior esse tempo, maior é a chance do SQL Server encontrar a informação que precisa e assim economizar uma busca no disco.
                    </td>
                </tr>
            </table>
            <br><br>';

            SELECT @CorpoEmail = @CorpoEmail + '</tr></table><br><br>';

            -- Envio do e-mail
            SET @assuntoEmail = 'Server - ' + @@SERVERNAME + ' - Evidências de Performance no SQL Server (PLE)';
            
            EXEC [msdb].[dbo].[sp_send_dbmail]
                @profile_name = 'CRAVIL',
                @recipients = 'suporte@cravil.com.br;',
                @subject = @assuntoEmail,
                @body = @CorpoEmail,
                @body_format = 'HTML';
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;

        DECLARE @corpoFalha VARCHAR(MAX);
        DECLARE @subject VARCHAR(100);
        DECLARE @recipients VARCHAR(100);

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';
        
        SET @corpoFalha = '
        <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
        </head>
        <body>
        <div align="left">';

        SELECT @corpoFalha = @corpoFalha + '
        <table border="0" cellpadding="0" cellspacing="0" width="402" style="border-collapse: collapse; table-layout: fixed; width: 1000pt; font-family: Arial; font-size: 14px;">
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <b>Falha na procedure [sp_AlertPLE]:</b><br>
                </td>
            </tr>
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                    <br><br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                    <br><br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                </td>
            </tr>
        </table>';

        SELECT @corpoFalha = @corpoFalha + '
        </div>
        </body>
        </html>';

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML';
    END CATCH

    SET NOCOUNT OFF;
END
GO
