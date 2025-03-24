---------------------------------------------------------------------------------------------------------------------------------------------------
-- SQL Server – Como fazer backup de todos os jobs do SQL Agent via linha de comando (CLR C# ou Powershell)
-- https://dirceuresende.com/blog/sql-server-como-fazer-backup-de-todos-os-jobs-do-sql-agent-via-linha-de-comando-clr-c-ou-powershell/
-- Criado com ajuda do ChatGPT
---------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @JobScript NVARCHAR(MAX) = ''
DECLARE @jobId UNIQUEIDENTIFIER,
        @jobName NVARCHAR(128),
        @jobDescription NVARCHAR(MAX),
        @enabled BIT,
        @notifyLevelEventlog INT,
        @notifyLevelEmail INT,
        @notifyLevelNetsend INT,
        @notifyLevelPage INT,
        @deleteLevel INT,
        @ownerLogin NVARCHAR(128),
        @categoryName NVARCHAR(128),
        @stepId INT,
        @stepName NVARCHAR(128),
        @subsystem NVARCHAR(128),
        @command NVARCHAR(MAX),
        @databaseName NVARCHAR(128),
        @cmdExecSuccessCode INT,
        @onSuccessAction INT,
        @onSuccessStepId INT,
        @onFailAction INT,
        @onFailStepId INT,
        @retryAttempts INT,
        @retryInterval INT,
        @osRunPriority INT,
        @scheduleId INT,
        @scheduleName NVARCHAR(128),
        @freqType INT,
        @freqInterval INT,
        @freqSubdayType INT,
        @freqSubdayInterval INT,
        @freqRelativeInterval INT,
        @freqRecurrenceFactor INT,
        @activeStartDate INT,
        @activeEndDate INT,
        @activeStartTime INT,
        @activeEndTime INT,
        @scheduleUid UNIQUEIDENTIFIER,
        @output_file_name NVARCHAR(200); 

SET @JobScript = @JobScript + 'USE msdb;' + CHAR(13) + CHAR(10)


SET @JobScript = @JobScript + '
SET NOCOUNT ON
SET XACT_ABORT ON

BEGIN TRY
  BEGIN TRANSACTION' + CHAR(13) + CHAR(10)

SET @JobScript = @JobScript + CHAR(13) + CHAR(10);

-- Cursor para percorrer todas as Jobs
DECLARE jobCursor CURSOR FOR
SELECT j.job_id,
       j.name,
       ISNULL(j.description, ''),
       j.enabled,
       j.notify_level_eventlog,
       j.notify_level_email,
       j.notify_level_netsend,
       j.notify_level_page,
       j.delete_level,
       SUSER_SNAME(j.owner_sid),
       c.name AS category_name
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.syscategories c ON j.category_id = c.category_id;

OPEN jobCursor;

FETCH NEXT FROM jobCursor INTO @jobId, @jobName, @jobDescription, @enabled, @notifyLevelEventlog, 
                               @notifyLevelEmail, @notifyLevelNetsend, @notifyLevelPage, 
                               @deleteLevel, @ownerLogin, @categoryName;

WHILE @@FETCH_STATUS = 0
BEGIN

     -- Criação do Job
    SET @JobScript = @JobScript + '--------------------------------------------------------------------------------------------------------------------------' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '-- Script para o Job: ' + @JobName + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '--------------------------------------------------------------------------------------------------------------------------' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + 'DECLARE @jobId_' + REPLACE(CAST(@jobId AS VARCHAR(100)), '-', '') + ' UNIQUEIDENTIFIER;' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + 'EXEC msdb.dbo.sp_add_job ' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @job_name = N''' + @jobName + ''',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @enabled = ' + CAST(@enabled AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @notify_level_eventlog = ' + CAST(@notifyLevelEventlog AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @notify_level_email = ' + CAST(@notifyLevelEmail AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @notify_level_netsend = ' + CAST(@notifyLevelNetsend AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @notify_level_page = ' + CAST(@notifyLevelPage AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @delete_level = ' + CAST(@deleteLevel AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @description = N''' + REPLACE(@jobDescription, '''', '''''') + ''',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @category_name = N''' + @categoryName + ''',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @owner_login_name = N''' + @ownerLogin + ''',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @job_id = @jobId_' + REPLACE(CAST(@jobId AS VARCHAR(100)), '-', '') + ' OUTPUT;' + CHAR(13) + CHAR(10);    
    SET @JobScript = @JobScript + CHAR(13) + CHAR(10);

    -- Cursor para os Steps do Job
    DECLARE stepCursor CURSOR FOR
    SELECT step_id,
           step_name,
           subsystem,
           command,
           database_name,
           cmdexec_success_code,
           on_success_action,
           on_success_step_id,
           on_fail_action,
           on_fail_step_id,
           retry_attempts,
           retry_interval,
           os_run_priority,
           output_file_name
    FROM msdb.dbo.sysjobsteps
    WHERE job_id = @jobId;

    OPEN stepCursor;

    FETCH NEXT FROM stepCursor INTO @stepId, @stepName, @subsystem, @command, @databaseName, 
                                    @cmdExecSuccessCode, @onSuccessAction, @onSuccessStepId, 
                                    @onFailAction, @onFailStepId, @retryAttempts, @retryInterval, 
                                    @osRunPriority,@output_file_name;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @JobScript = @JobScript + 'EXEC msdb.dbo.sp_add_jobstep ' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @job_id = @jobId_' + REPLACE(CAST(@jobId AS VARCHAR(100)), '-', '') + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @step_id = ' + CAST(@stepId AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @step_name = N''' + @stepName + ''',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @subsystem = N''' + @subsystem + ''',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @command = N''' + REPLACE(@command, '''', '''''') + ''',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @database_name = N''' + @databaseName + ''',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @cmdexec_success_code = ' + CAST(@cmdExecSuccessCode AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @on_success_action = ' + CAST(@onSuccessAction AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @on_success_step_id = ' + CAST(@onSuccessStepId AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @on_fail_action = ' + CAST(@onFailAction AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @on_fail_step_id = ' + CAST(@onFailStepId AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @retry_attempts = ' + CAST(@retryAttempts AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @retry_interval = ' + CAST(@retryInterval AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @os_run_priority = ' + CAST(@osRunPriority AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);  
        SET @JobScript = @JobScript + '    @output_file_name = N''' + ISNULL(@output_file_name, 'NULL') + ''';' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + CHAR(13) + CHAR(10);      

        FETCH NEXT FROM stepCursor INTO @stepId, @stepName, @subsystem, @command, @databaseName, 
                                        @cmdExecSuccessCode, @onSuccessAction, @onSuccessStepId, 
                                        @onFailAction, @onFailStepId, @retryAttempts, @retryInterval, 
                                        @osRunPriority, @output_file_name;
    END;

    CLOSE stepCursor;
    DEALLOCATE stepCursor;

    -- Cursor para os Agendamentos do Job
    DECLARE scheduleCursor CURSOR FOR
    SELECT s.schedule_id, 
           s.name, 
           s.freq_type, 
           s.freq_interval, 
           s.freq_subday_type, 
           s.freq_subday_interval, 
           s.freq_relative_interval, 
           s.freq_recurrence_factor, 
           s.active_start_date, 
           s.active_end_date, 
           s.active_start_time, 
           s.active_end_time,
           s.schedule_uid
    FROM msdb.dbo.sysschedules s
    INNER JOIN msdb.dbo.sysjobschedules js ON s.schedule_id = js.schedule_id
    WHERE js.job_id = @jobId;

    OPEN scheduleCursor;

    FETCH NEXT FROM scheduleCursor INTO @scheduleId, @scheduleName, @freqType, @freqInterval, 
                                       @freqSubdayType, @freqSubdayInterval, @freqRelativeInterval, 
                                       @freqRecurrenceFactor, @activeStartDate, @activeEndDate, 
                                       @activeStartTime, @activeEndTime, @scheduleUid;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @JobScript = @JobScript + 'EXEC msdb.dbo.sp_add_jobschedule ' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @job_id = @jobId_' + REPLACE(CAST(@jobId AS VARCHAR(100)), '-', '') + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @name = N''' + @scheduleName + ''',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @enabled = 1,' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @freq_type = ' + CAST(@freqType AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @freq_interval = ' + CAST(@freqInterval AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @freq_subday_type = ' + CAST(@freqSubdayType AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @freq_subday_interval = ' + CAST(@freqSubdayInterval AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @freq_relative_interval = ' + CAST(@freqRelativeInterval AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @freq_recurrence_factor = ' + CAST(@freqRecurrenceFactor AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @active_start_date = ' + CAST(@activeStartDate AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @active_end_date = ' + CAST(@activeEndDate AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @active_start_time = ' + CAST(@activeStartTime AS NVARCHAR) + ',' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + '    @active_end_time = ' + CAST(@activeEndTime AS NVARCHAR) + ';' + CHAR(13) + CHAR(10);
        SET @JobScript = @JobScript + CHAR(13) + CHAR(10);        

        FETCH NEXT FROM scheduleCursor INTO @scheduleId, @scheduleName, @freqType, @freqInterval, 
                                           @freqSubdayType, @freqSubdayInterval, @freqRelativeInterval, 
                                           @freqRecurrenceFactor, @activeStartDate, @activeEndDate, 
                                           @activeStartTime, @activeEndTime, @scheduleUid;
    END;

    CLOSE scheduleCursor;
    DEALLOCATE scheduleCursor;

    -- Associar o Job ao SQL Server Agent
    SET @JobScript = @JobScript + 'EXEC msdb.dbo.sp_add_jobserver ' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @job_id = @jobId_' + REPLACE(CAST(@jobId AS VARCHAR(100)), '-', '') + ',' + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + '    @server_name = N''(local)'';' + CHAR(13) + CHAR(10);    
    SET @JobScript = @JobScript + CHAR(13) + CHAR(10);
    SET @JobScript = @JobScript + CHAR(13) + CHAR(10);

    FETCH NEXT FROM jobCursor INTO @jobId, @jobName, @jobDescription, @enabled, @notifyLevelEventlog, 
                                   @notifyLevelEmail, @notifyLevelNetsend, @notifyLevelPage, 
                                   @deleteLevel, @ownerLogin, @categoryName;
END;

CLOSE jobCursor;
DEALLOCATE jobCursor;


SET @JobScript = @JobScript + 
'
  COMMIT TRANSACTION
END TRY
BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrorNumber
   ,ERROR_SEVERITY() AS ErrorSeverity
   ,ERROR_STATE() AS ErrorState
   ,ERROR_LINE() AS ErrorLine
   ,ERROR_MESSAGE() AS ErrorMessage;

  IF (XACT_STATE()) = -1
  BEGIN
    PRINT ''A transação está em um estado incompatível. Retrocedendo transação.''
    ROLLBACK TRANSACTION;
  END;

  IF (XACT_STATE()) = 1
  BEGIN
    PRINT ''A transação é compatível. Transação completada.''
    COMMIT TRANSACTION;
  END;
END CATCH

SET NOCOUNT OFF
SET XACT_ABORT OFF
'

SELECT @JobScript AS [CONTENT]

