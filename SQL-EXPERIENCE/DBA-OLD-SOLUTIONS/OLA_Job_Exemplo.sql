USE [msdb]
GO

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Esta Job inclui alterar o modo de recuperação das bases e fazer shrink antes das reindexações
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[DBA - Manutenção]]    Script Date: 22/05/2018 15:55:25 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[DBA - Manutenção]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[DBA - Manutenção]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'TI_IndexOptimize', 
		@enabled=0, 
		@notify_level_eventlog=0, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[DBA - Manutenção]', 
		@owner_login_name=N'CRAVIL\rdornel', 
		@notify_email_operator_name=N'DBA_Jobs_SetorTI', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SIMPLE]    Script Date: 22/05/2018 15:55:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SIMPLE', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @DB_Name varchar(100) 
DECLARE @Command nvarchar(200) 
DECLARE database_cursor CURSOR FOR 
SELECT name 
FROM MASTER.sys.sysdatabases WHERE name in (''GesCooper90'',''CooperSystem'',''DW_GesCooper'',''Edocs'',''GesCooper90'',''Guru5'',
''Guru6'',''IntegraTICravil'',''rhcravil'',''TICRAVIL'')

OPEN database_cursor 

FETCH NEXT FROM database_cursor INTO @DB_Name 

WHILE @@FETCH_STATUS = 0 
BEGIN 
     SELECT @Command = ''ALTER DATABASE '' + ''['' + @DB_Name + '']'' + '' SET RECOVERY SIMPLE''
     PRINT @Command
	 EXEC sp_executesql @Command 

     FETCH NEXT FROM database_cursor INTO @DB_Name 
END 

CLOSE database_cursor 
DEALLOCATE database_cursor ', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [SHRINK]    Script Date: 22/05/2018 15:55:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'SHRINK', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [GesCooper90]
GO
DBCC SHRINKFILE (N''GesCooper90_log'' , 0, TRUNCATEONLY)
GO
USE [CooperSystem]
GO
DBCC SHRINKFILE (N''CooperSystem_log'' , 0, TRUNCATEONLY)
GO
USE [DW_GesCooper]
GO
DBCC SHRINKFILE (N''DW_GesCooper_log'' , 0, TRUNCATEONLY)
GO
USE [Edocs]
GO
DBCC SHRINKFILE (N''Edocs_log'' , 0, TRUNCATEONLY)
GO
USE [Guru5]
GO
DBCC SHRINKFILE (N''dbguru_log'' , 0, TRUNCATEONLY)
GO
USE [Guru6]
GO
DBCC SHRINKFILE (N''dbguru_log'' , 0, TRUNCATEONLY)
GO
USE [IntegraTICravil]
GO
DBCC SHRINKFILE (N''IntegraTICravil'' , 0, TRUNCATEONLY)
GO
USE [rhcravil]
GO
DBCC SHRINKFILE (N''rhcravil_log'' , 0, TRUNCATEONLY)
GO
USE [TICRAVIL]
GO
DBCC SHRINKFILE (N''TICRAVIL_log'' , 0, TRUNCATEONLY)
GO
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [RodaIndexOptimize]    Script Date: 22/05/2018 15:55:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'RodaIndexOptimize', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXECUTE dbo.IndexOptimize @Databases = ''GesCooper90,CooperSystem,DW_GesCooper,Edocs,Guru5,Guru6,IntegraTICravil,rhcravil,TICRAVIL'',
@FragmentationLow = NULL,
@FragmentationMedium = ''INDEX_REORGANIZE,INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationHigh = ''INDEX_REBUILD_ONLINE,INDEX_REBUILD_OFFLINE'',
@FragmentationLevel1 = 5,
@FragmentationLevel2 = 30,
@UpdateStatistics = ''ALL'',
@OnlyModifiedStatistics = ''Y'',
--@PageCountLevel=0
@logtotable=''Y''', 
		@database_name=N'Maintenance', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [FULL]    Script Date: 22/05/2018 15:55:25 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'FULL', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @DB_Name varchar(100) 
DECLARE @Command nvarchar(200) 
DECLARE database_cursor CURSOR FOR 
SELECT name 
FROM MASTER.sys.sysdatabases WHERE name in (''GesCooper90'',''CooperSystem'',''DW_GesCooper'',''Edocs'',''GesCooper90'',''Guru5'',
''Guru6'',''IntegraTICravil'',''rhcravil'',''TICRAVIL'')

OPEN database_cursor 

FETCH NEXT FROM database_cursor INTO @DB_Name 

WHILE @@FETCH_STATUS = 0 
BEGIN 
     SELECT @Command = ''ALTER DATABASE '' + ''['' + @DB_Name + '']'' + '' SET RECOVERY FULL''
     PRINT @Command
	 EXEC sp_executesql @Command 

     FETCH NEXT FROM database_cursor INTO @DB_Name 
END 

CLOSE database_cursor 
DEALLOCATE database_cursor ', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 3
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'DOMINGO', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20180402, 
		@active_end_date=99991231, 
		@active_start_time=120000, 
		@active_end_time=235959, 
		@schedule_uid=N'65bf7ff8-2bf2-4d52-b80f-02501b03573a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


