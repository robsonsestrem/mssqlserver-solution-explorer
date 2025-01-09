----------------------------------------------------------------------------------------------------------
-- Outra solução de backup
-- https://stackoverflow.com/questions/3361163/automatically-create-scripts-for-all-sql-server-jobs
----------------------------------------------------------------------------------------------------------
USE msdb
Go

EXEC sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
EXEC sp_configure 'xp_cmdshell', 1
GO
RECONFIGURE

GO


Create PROCEDURE CreateBackUpFromJob
@JobName NVARCHAR(1000) ,
@Path VARCHAR(1000)
AS 
BEGIN

    DECLARE @JobCommand NVARCHAR(MAX) = ''
    DECLARE @JobCommand1 NVARCHAR(MAX) = ''
    DECLARE @JobCommand2 NVARCHAR(MAX) = ''

---------------- Declare Temp Table ------------------
    DECLARE @OutPut TABLE
        (
          Id INT IDENTITY(1, 1)
                 PRIMARY KEY ,
          Echo NVARCHAR(MAX) NOT NULL
        )
------------------------------------------------------
    SELECT  
--* , 
            @JobCommand = ' INSERT INTO [msdb].[dbo].[sysjobs] '
            + ' ([job_id],[originating_server_id],[name],[enabled],[description],    [start_step_id],[category_id] '
            + ' ,[owner_sid],[notify_level_eventlog],[notify_level_email],[notify_level_netsend],[notify_level_page] '
            + ' ,[notify_email_operator_id],[notify_netsend_operator_id],[notify_page_operator_id],[delete_level] '
            + ' ,[date_created],[date_modified],[version_number]) '
            + ' VALUES ( ''' + CONVERT(VARCHAR(MAX), [job_id]) + ''','
            + +CONVERT(VARCHAR(MAX), [originating_server_id]) + ',' + ''''
            + [name] + ''',' + CONVERT(VARCHAR(MAX), [enabled]) + ','
            + '''' + [description] + ''','
            + CONVERT(VARCHAR(MAX), [start_step_id]) + ','
            + CONVERT(VARCHAR(MAX), [category_id]) + ','
            --? Convert varbinary to varchar
            --+CONVERT(VarChar(4000),[owner_sid])+','
            + '0x01' + ',' + CONVERT(VARCHAR(MAX), [notify_level_eventlog])
            + ',' + CONVERT(VARCHAR(MAX), [notify_level_email]) + ','
            + CONVERT(VARCHAR(MAX), [notify_level_netsend]) + ','
            + CONVERT(VARCHAR(MAX), [notify_level_page]) + ','
            + CONVERT(VARCHAR(MAX), [notify_email_operator_id]) + ','
            + CONVERT(VARCHAR(MAX), [notify_netsend_operator_id]) + ','
            + CONVERT(VARCHAR(MAX), [notify_page_operator_id]) + ','
            + CONVERT(VARCHAR(MAX), [delete_level]) + ',' + ''''
            + CONVERT(VARCHAR(MAX), [date_created]) + ''',' + ''''
            + CONVERT(VARCHAR(MAX), [date_modified]) + ''','
            + CONVERT(VARCHAR(MAX), [version_number]) + ' ) '
    FROM    msdb.dbo.sysjobs AS Job
    WHERE   Job.name = @JobName
---------------------------------------------------------------------------------------
    SET @JobCommand = ' ' + @JobCommand + ' '
    INSERT  INTO @OutPut
            ( Echo )
    VALUES  ( @JobCommand )
    SET @JobCommand = ' '
---------------------------------------------------------------------------------------
    SET @JobCommand = ' ' + @JobCommand + ' ';

    DECLARE @job_id [uniqueidentifier] 
    DECLARE @step_id [int] 
    DECLARE @step_name [sysname] 
    DECLARE @subsystem NVARCHAR(40) 
    DECLARE @command NVARCHAR(MAX) 
    DECLARE @flags [int] 
--Declare @additional_parameters [ntext] 
    DECLARE @additional_parameters NVARCHAR(MAX)  
    DECLARE @cmdexec_success_code [int] 
    DECLARE @on_success_action [tinyint] 
    DECLARE @on_success_step_id [int] 
    DECLARE @on_fail_action [tinyint] 
    DECLARE @on_fail_step_id [int] 
    DECLARE @server [sysname] 
    DECLARE @database_name [sysname] 
    DECLARE @database_user_name [sysname] 
    DECLARE @retry_attempts [int] 
    DECLARE @retry_interval [int] 
    DECLARE @os_run_priority [int] 
    DECLARE @output_file_name [nvarchar](200) 
    DECLARE @last_run_outcome [int] 
    DECLARE @last_run_duration [int] 
    DECLARE @last_run_retries [int] 
    DECLARE @last_run_date [int] 
    DECLARE @last_run_time [int] 
    DECLARE @proxy_id [int] 
    DECLARE @step_uid [uniqueidentifier] 


    DECLARE Cur CURSOR
    FOR
        SELECT  JobSteps.*
        FROM    msdb.dbo.sysjobsteps JobSteps
                INNER JOIN msdb.dbo.sysjobs Job ON Job.job_id = JobSteps.job_id
        WHERE   Job.name = @JobName
    OPEN Cur

    FETCH NEXT FROM Cur INTO @job_id, @step_id, @step_name, @subsystem,
        @command, @flags, @additional_parameters, @cmdexec_success_code,
        @on_success_action, @on_success_step_id, @on_fail_action,
        @on_fail_step_id, @server, @database_name, @database_user_name,
        @retry_attempts, @retry_interval, @os_run_priority,
        @output_file_name, @last_run_outcome, @last_run_duration,
        @last_run_retries, @last_run_date, @last_run_time, @proxy_id,
        @step_uid 

    WHILE ( @@FETCH_STATUS = 0 ) 
        BEGIN

            SET @JobCommand = ' INSERT INTO [msdb].[dbo].[sysjobsteps] '
                + '([job_id],[step_id],[step_name],[subsystem],[command],[flags],    [additional_parameters] '
                + ' ,[cmdexec_success_code],[on_success_action],[on_success_step_id],    [on_fail_action] '
                + ' ,[on_fail_step_id],[server],[database_name],[database_user_name],    [retry_attempts] '
                + ' ,[retry_interval],[os_run_priority],[output_file_name],[last_run_outcome],[last_run_duration] '
                + ' ,[last_run_retries],[last_run_date],[last_run_time],[proxy_id],[step_uid]) '
                + ' VALUES ( ''' + ISNULL(CONVERT(VARCHAR(MAX), @job_id),
                                          'Null') + ''','
                + ISNULL(CONVERT(VARCHAR(MAX), @step_id), 'Null') + ','
                + +'''' + ISNULL(CONVERT(VARCHAR(MAX), @step_name), 'Null')
                + ''',' + '''' + ISNULL(CONVERT(VARCHAR(MAX), @subsystem),
                                        'Null') + ''',' + '''';
            SET @JobCommand1 = ISNULL(CONVERT(VARCHAR(MAX), @command),
                                      'Null') + ''',';
            SET @JobCommand1 = REPLACE(@JobCommand1, CHAR(13) + CHAR(10),
                                       ' ')
            SET @JobCommand2 = ISNULL(CONVERT(VARCHAR(MAX), @flags),
                                      'Null') + ',' + ''''
                + ISNULL(CONVERT(VARCHAR(MAX), @additional_parameters),
                         'Null') + ''','
                + ISNULL(CONVERT(VARCHAR(MAX), @cmdexec_success_code),
                         'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @on_success_action), 'Null')
                + ',' + ISNULL(CONVERT(VARCHAR(MAX), @on_success_step_id),
                               'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @on_fail_action), 'Null')
                + ',' + ISNULL(CONVERT(VARCHAR(MAX), @on_fail_step_id),
                               'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @server), 'Null') + ','
                + +'''' + ISNULL(CONVERT(VARCHAR(MAX), @database_name),
                                 'Null') + ''',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), @database_user_name),
                         'Null') + ''','
                + ISNULL(CONVERT(VARCHAR(MAX), @retry_attempts), 'Null')
                + ',' + ISNULL(CONVERT(VARCHAR(MAX), @retry_interval),
                               'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @os_run_priority), 'Null')
                + ',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), @output_file_name), 'Null')
                + ''',' + ISNULL(CONVERT(VARCHAR(MAX), @last_run_outcome),
                                 'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @last_run_duration), 'Null')
                + ',' + ISNULL(CONVERT(VARCHAR(MAX), @last_run_retries),
                               'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @last_run_date), 'Null')
                + ',' + ISNULL(CONVERT(VARCHAR(MAX), @last_run_time),
                               'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), @proxy_id), 'Null') + ','
                + +'''' + ISNULL(CONVERT(VARCHAR(MAX), @step_uid), 'Null')
                + '''' + ' )'

            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @JobCommand )
            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @JobCommand1 )
            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @JobCommand2 )

            FETCH NEXT FROM Cur INTO @job_id, @step_id, @step_name,
                @subsystem, @command, @flags, @additional_parameters,
                @cmdexec_success_code, @on_success_action,
                @on_success_step_id, @on_fail_action, @on_fail_step_id,
                @server, @database_name, @database_user_name,
                @retry_attempts, @retry_interval, @os_run_priority,
                @output_file_name, @last_run_outcome, @last_run_duration,
                @last_run_retries, @last_run_date, @last_run_time,
                @proxy_id, @step_uid 
        END

    CLOSE Cur
    DEALLOCATE Cur      

---------------------------------------------------------------------------------------
    SET @JobCommand = @JobCommand + ' ';
    SET @JobCommand = ''
---------------------------------------------------------------------------------------
    SET @JobCommand = @JobCommand + ' ';
    DECLARE @Command_sysjobschedules NVARCHAR(MAX) = ''
    DECLARE @Comand_sysschedules NVARCHAR(MAX) = ''

    DECLARE Cur CURSOR
    FOR
        SELECT  Command_sysjobschedules = ' INSERT INTO [msdb].[dbo].[sysjobschedules]     '
                + ' ( [schedule_id],[job_id],[next_run_date],[next_run_time] ) '
                + ' VALUES ( ' + '@@IDENTITY , ' + ''''
                + CONVERT(VARCHAR(MAX), JobSch.job_id) + ''' , '
                + CONVERT(VARCHAR(MAX), JobSch.next_run_date) + ' , '
                + CONVERT(VARCHAR(MAX), JobSch.next_run_time) + ' ) ' ,
                Comand_sysschedules = ''
                + ' INSERT INTO [msdb].[dbo].[sysschedules]( '
                + ' [schedule_uid],[originating_server_id],[name],[owner_sid], '
                + ' [enabled],[freq_type],[freq_interval] '
                + ' ,[freq_subday_type],[freq_subday_interval], '
                + ' [freq_relative_interval],[freq_recurrence_factor] '
                + ' ,[active_start_date],[active_end_date],[active_start_time], '
                + ' [active_end_time],[date_created],[date_modified],[version_number]) '
                + 'VALUES ( ' + ''''
                + CONVERT(VARCHAR(MAX), Sch.schedule_uid) + ''',' + +''''
                + CONVERT(VARCHAR(MAX), Sch.originating_server_id) + ''','
                + +'''' + CONVERT(VARCHAR(MAX), Sch.name) + ''','
                + --Convert(VarChar(Max),Sch.owner_sid + ','+
                '0x01' + ',' + CONVERT(VARCHAR(MAX), Sch.enabled) + ','
                + CONVERT(VARCHAR(MAX), Sch.freq_type) + ','
                + CONVERT(VARCHAR(MAX), Sch.freq_interval) + ','
                + CONVERT(VARCHAR(MAX), Sch.freq_subday_type) + ','
                + CONVERT(VARCHAR(MAX), Sch.freq_subday_interval) + ','
                + CONVERT(VARCHAR(MAX), Sch.freq_relative_interval) + ','
                + CONVERT(VARCHAR(MAX), Sch.freq_recurrence_factor) + ','
                + CONVERT(VARCHAR(MAX), Sch.active_start_date) + ','
                + CONVERT(VARCHAR(MAX), Sch.active_end_date) + ','
                + CONVERT(VARCHAR(MAX), Sch.active_start_time) + ','
                + CONVERT(VARCHAR(MAX), Sch.active_end_time) + ',' + +''''
                + CONVERT(VARCHAR(MAX), Sch.date_created) + ''',' + +''''
                + CONVERT(VARCHAR(MAX), Sch.date_modified) + ''','
                + CONVERT(VARCHAR(MAX), Sch.version_number) + '  ) '
        FROM    msdb.dbo.sysjobschedules AS JobSch
                INNER JOIN msdb.dbo.sysjobs AS Job ON Job.job_id = JobSch.job_id
                INNER JOIN msdb.dbo.sysschedules AS Sch ON JobSch.schedule_id =     Sch.schedule_id
        WHERE   Job.name = @JobName

    OPEN Cur

    FETCH NEXT FROM Cur INTO @Command_sysjobschedules,
        @Comand_sysschedules

    DECLARE @Temp NVARCHAR(MAX) = ''

    WHILE ( @@FETCH_STATUS = 0 ) 
        BEGIN
    --Set @JobCommand = ' ' + @Comand_sysschedules+ ' ' +       @Command_sysjobschedules
    --Insert InTo @OutPut ( Echo ) Values ( @JobCommand )

            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @Comand_sysschedules )
            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @Command_sysjobschedules )

            FETCH NEXT FROM Cur INTO @Command_sysjobschedules,
                @Comand_sysschedules
        END

    SET @JobCommand = @JobCommand + ' ' + @Temp
    CLOSE Cur
    DEALLOCATE Cur      


---------------------------------------------------------------------------------------
    SET @JobCommand = @JobCommand + ' ';
    SET @JobCommand = ''
---------------------------------------------------------------------------------------
    SET @JobCommand = @JobCommand + ' ';

    DECLARE @Command_notifications VARCHAR(MAX)
    DECLARE @Command_operators VARCHAR(MAX)
    DECLARE @Command_sysalerts VARCHAR(MAX)

    DECLARE Cur CURSOR
    FOR
        SELECT  Command_notifications = ' INSERT INTO [msdb].[dbo].[sysnotifications] '
                + ' ([alert_id] ' + ' ,[operator_id] '
                + ' ,[notification_method]) ' + ' VALUES ' + ' ( '
                + '@Al,' + '@OP,'
                + CONVERT(VARCHAR(MAX), Noti.notification_method) + ' ) ' ,
                Command_operators = ' INSERT INTO [msdb].[dbo].[sysoperators] '
                + ' ( [name],[enabled],[email_address],[last_email_date],[last_email_time],[pager_address]'
                + ' ,[last_pager_date],[last_pager_time],[weekday_pager_start_time],[weekday_pager_end_time]'
                + ' ,[saturday_pager_start_time],[saturday_pager_end_time],[sunday_pager_start_time]'
                + ' ,[sunday_pager_end_time],[pager_days],[netsend_address],    [last_netsend_date]'
                + ' ,[last_netsend_time],[category_id]) ' + ' VALUES ( '
                + +'''' + CONVERT(VARCHAR(MAX), Ope.[name]) + ''','
                + CONVERT(VARCHAR(MAX), Ope.[enabled]) + ',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), Ope.[email_address]), '')
                + ''',' + CONVERT(VARCHAR(MAX), Ope.[last_email_date])
                + ',' + CONVERT(VARCHAR(MAX), Ope.[last_email_time]) + ','
                + +'''' + ISNULL(CONVERT(VARCHAR(MAX), Ope.[pager_address]),
                                 '') + ''','
                + CONVERT(VARCHAR(MAX), Ope.[last_pager_date]) + ','
                + CONVERT(VARCHAR(MAX), Ope.[last_pager_time]) + ','
                + CONVERT(VARCHAR(MAX), Ope.[weekday_pager_start_time])
                + ',' + CONVERT(VARCHAR(MAX), Ope.[weekday_pager_end_time])
                + ','
                + CONVERT(VARCHAR(MAX), Ope.[saturday_pager_start_time])
                + ','
                + CONVERT(VARCHAR(MAX), Ope.[saturday_pager_end_time])
                + ','
                + CONVERT(VARCHAR(MAX), Ope.[sunday_pager_start_time])
                + ',' + CONVERT(VARCHAR(MAX), Ope.[sunday_pager_end_time])
                + ',' + CONVERT(VARCHAR(MAX), Ope.[pager_days]) + ','
                + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), Ope.[netsend_address]), '')
                + ''',' + CONVERT(VARCHAR(MAX), Ope.[last_netsend_date])
                + ',' + CONVERT(VARCHAR(MAX), Ope.[last_netsend_time])
                + ',' + CONVERT(VARCHAR(MAX), Ope.[category_id])
                + ' ) Set @OP = @@IDENTITY ' ,
                Command_sysalerts = 'INSERT INTO [msdb].[dbo].[sysalerts] '
                + ' ([name],[event_source],[event_category_id],[event_id],[message_id]     '
                + ' ,[severity],[enabled],[delay_between_responses],    [last_occurrence_date] '
                + ' ,[last_occurrence_time],[last_response_date],[last_response_time] '
                + ' ,[notification_message],[include_event_description],[database_name] '
                + ' ,[event_description_keyword],[occurrence_count],[count_reset_date] '
                + ' ,[count_reset_time],[job_id],[has_notification],[flags] '
                + ' ,[performance_condition],[category_id]) ' + ' VALUES '
                + ' ( ' + +'''' + CONVERT(VARCHAR(MAX), Ale.[name])
                + ''',' + +'''' + CONVERT(VARCHAR(MAX), Ale.[event_source])
                + ''','
                + ISNULL(CONVERT(VARCHAR(MAX), Ale.[event_category_id]),
                         'Null') + ','
                + ISNULL(CONVERT(VARCHAR(MAX), Ale.[event_id]), 'Null')
                + ',' + ISNULL(CONVERT(VARCHAR(MAX), Ale.[message_id]), '')
                + ',' + CONVERT(VARCHAR(MAX), Ale.[severity]) + ','
                + CONVERT(VARCHAR(MAX), Ale.[enabled]) + ','
                + CONVERT(VARCHAR(MAX), Ale.[delay_between_responses])
                + ',' + CONVERT(VARCHAR(MAX), Ale.[last_occurrence_date])
                + ',' + CONVERT(VARCHAR(MAX), Ale.[last_occurrence_time])
                + ',' + CONVERT(VARCHAR(MAX), Ale.[last_response_date])
                + ',' + CONVERT(VARCHAR(MAX), Ale.[last_response_time])
                + ',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), Ale.[notification_message]),
                         '') + ''','
                + CONVERT(VARCHAR(MAX), Ale.[include_event_description])
                + ',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), Ale.[database_name]), '')
                + ''',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), Ale.[event_description_keyword]),
                         '') + ''','
                + CONVERT(VARCHAR(MAX), Ale.[occurrence_count]) + ','
                + CONVERT(VARCHAR(MAX), Ale.[count_reset_date]) + ','
                + CONVERT(VARCHAR(MAX), Ale.[count_reset_time]) + ','
                + +'''' + CONVERT(VARCHAR(MAX), Ale.[job_id]) + ''','
                + CONVERT(VARCHAR(MAX), Ale.[has_notification]) + ','
                + CONVERT(VARCHAR(MAX), Ale.[flags]) + ',' + +''''
                + ISNULL(CONVERT(VARCHAR(MAX), Ale.[performance_condition]),
                         '') + ''','
                + CONVERT(VARCHAR(MAX), Ale.[category_id])
                + +') Set @Al = @@IDENTITY '
        FROM    msdb.dbo.sysalerts AS Ale
                INNER JOIN msdb.dbo.sysnotifications AS Noti ON ( Ale.id =     Noti.alert_id )
                INNER JOIN msdb.dbo.sysoperators AS Ope ON ( Noti.operator_id = ope.id     )
                INNER JOIN msdb.dbo.sysjobs AS Job ON ( Job.job_id = Ale.job_id )
        WHERE   Job.name = 'aaJob'

    OPEN Cur

    FETCH NEXT FROM Cur INTO @Command_notifications, @Command_operators,
        @Command_sysalerts

    DECLARE @Temp1 NVARCHAR(MAX) = ''
    DECLARE @Temp2 NVARCHAR(MAX) = ''

    SET @JobCommand = ' Declare @OP int; Declare @Al int;  '
    INSERT  INTO @OutPut
            ( Echo )
    VALUES  ( @JobCommand )

    WHILE ( @@FETCH_STATUS = 0 ) 
        BEGIN
    --Set @JobCommand = ' ' + @Command_operators + ' ' + @Command_sysalerts + '     ' + @Command_notifications
    --Insert InTo @OutPut ( Echo ) Values ( @JobCommand )

            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @Command_operators )
            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @Command_sysalerts )
            INSERT  INTO @OutPut
                    ( Echo )
            VALUES  ( @Command_notifications )

            FETCH NEXT FROM Cur INTO @Command_notifications,
                @Command_operators, @Command_sysalerts
        END

    CLOSE Cur
    DEALLOCATE Cur

---------------------------------------------------------------------------------------
    SET @JobCommand = @JobCommand + ' ';
    SET @JobCommand = ''
---------------------------------------------------------------------------------------

    DECLARE @EchoField NVARCHAR(4000) = ''
    DECLARE @EchoCommand NVARCHAR(4000) = ''

    DECLARE Cur CURSOR
    FOR
        SELECT  RTRIM(LTRIM(Echo)) AS EchoCommand
        FROM    @OutPut
    OPEN Cur

    FETCH NEXT FROM Cur INTO @EchoField

    WHILE ( @@FETCH_STATUS = 0 ) 
        BEGIN
            SET @EchoCommand = 'ECHO ' + @EchoField + ' >> ' + @Path
                + @JobName
                + REPLACE(REPLACE(CONVERT(VARCHAR(200), GETDATE()), ' ',
                                  ''), ':', '') + '.txt'
    --Print @EchoCommand
            EXEC xp_cmdshell @EchoCommand
            FETCH NEXT FROM Cur INTO @EchoField
        END

    CLOSE Cur
    DEALLOCATE Cur

END
GO



Use msdb
Go

Create Procedure CreateBackUpFromAllJob
@Path VarChar(1000)  
As
Begin
Declare @JobName NVarChar(1000) = ''

Declare Cur1 Cursor For
    Select job.name 
    From sysjobs As job

Open Cur1

Fetch Next From Cur1 InTo @JobName

While( @@FETCH_STATUS = 0 )
    Begin
        Exec msdb.dbo.CreateBackUpFromJob @JobName , @Path
        Fetch Next From Cur1 InTo @JobName
    End

Close Cur1
Deallocate Cur1

END

