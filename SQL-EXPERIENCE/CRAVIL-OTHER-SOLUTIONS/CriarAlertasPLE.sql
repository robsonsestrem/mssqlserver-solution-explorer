--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://simplesqlserver.com/2013/08/19/fixing-page-life-expectancy-ple/
-- http://www.dbinternals.com.br/?p=1252
--SQL Server Buffer Manager \ Page life expectancy – Indica a quantidade em segundos que uma página de dados fica no buffer pool do SQLServer. 
--Se esse número ficar abaixo de um limite pré-estabelecido, pode indicar problemas de performance, ou querys mal escritas ou realmente um gargalo de memória.
--Em um post do Jonathan Kehayias no site http://www.sqlskills.com ele indica uma forma de como calcular esse limite, ao contrário de um número (300) que muitos indicam.
--A fórmula indicada por ele é: (DataCacheSizeInGB/4GB)*300, o que é realmente muito mais razoável do que um valor fixo de 300 para qualquer tipo ou configuração de servidor.
--Para saber o tamanho do seu Cache Size em GB execute o select abaixo:
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.sqlskills.com/blogs/jonathan/how-much-memory-does-my-sql-server-actually-need/
-- Especificando valor ideal de ambiente em horários de bom funcionamento
SELECT COUNT(*) * 8 / 1024 / 1024 AS 'Cached Size (GB)'
FROM [sys].[dm_os_buffer_descriptors]; -- deu 114

--No meu caso o retorno foi 114, então calculando o valor: ((114 Gb / 128Gb de memória disponível) * 300) segundos da métrica da microsoft
--Logo, o valor mínimo de PLE recomendado é: 267 segundos aproximadamente, ou seja, segundos saudáveis para que se tenha páginas de dados no buffer pool.

USE Maintenance;
go
CREATE TABLE Management.[CountPLE]
([DateCount] [DATETIME] NOT NULL,
 [ObjectName]   [NCHAR](128) NOT NULL,
 [CounterName] [NCHAR](128) NOT NULL,
 [CounterValue] [BIGINT] NOT NULL,
 [IdealCalculado] [decimal](15, 2) NULL,
CONSTRAINT [PK_tb_ContadorPerformance] PRIMARY KEY([DateCount], [ObjectName], [CounterName])
)
ON [primary];


-- coleta de teste, este será o insert da job na tabela de histórico
SELECT GETDATE() AS [dth_Contador],
       [object_name] AS [des_Objeto],
       [counter_name] AS [des_Contador],
       [cntr_value] AS [val_Contador],
	   (SELECT cast((
		(SELECT COUNT(*) * 8. / 1024. / 1024. AS 'Cached Size (GB)'
		FROM [sys].[dm_os_buffer_descriptors]
		)/128.*300.) as decimal(15,2))) AS [ideal_calculado]
  FROM [sys].[dm_os_performance_counters]
 WHERE [object_name] LIKE '%Manager%'
       AND [counter_name] = 'Page life expectancy';
-- 2017-08-01 13:35:27.307	SQLServer:Buffer Manager   	Page life expectancy   3098


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Job para geração do histórico
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Job [TI_PageLifeExpectancy]    Script Date: 8/1/2017 5:57:25 PM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 8/1/2017 5:57:25 PM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'TI_PageLifeExpectancy', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'admcravil', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Page_Life_Expectancy]    Script Date: 8/1/2017 5:57:26 PM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Page_Life_Expectancy', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO Maintenance.Management.CountPLE
		SELECT GETDATE() AS [dth_Contador],
			   [object_name] AS [des_Objeto],
			   [counter_name] AS [des_Contador],
			   [cntr_value] AS [val_Contador],
			   (SELECT cast((
				(SELECT COUNT(*) * 8. / 1024. / 1024. AS ''Cached Size (GB)''
				FROM [sys].[dm_os_buffer_descriptors]
				)/128.*300.) as decimal(15,2))) AS [ideal_calculado]
		 FROM [sys].[dm_os_performance_counters]
		 WHERE [object_name] LIKE ''%Manager%''
			   AND [counter_name] = ''Page life expectancy'';', 

		@database_name=N'Maintenance', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Descobrir o ID para colocar no alerta
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT *
FROM [msdb]..[sysjobs]
WHERE [name] = 'TI_PageLifeExpectancy';


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando os alertas
-- https://catao.wordpress.com/2008/11/07/envio-de-alerta-de-falha-do-job-com-o-database-mail/
-- http://blogdofernandoguarany.blogspot.com.br/2014/05/criando-jobs.html						-- exemplos de alertas diversos do sql server
-- https://docs.microsoft.com/pt-br/sql/ssms/agent/assign-alerts-to-an-operator#SSMSProcedure
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-operator-transact-sql
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-add-notification-transact-sql
-- https://docs.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-update-alert-transact-sql	-- alterar os alertas
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Alert [PageLifeExpectancy]    Script Date: 8/1/2017 5:58:01 PM ******/
EXEC msdb.dbo.sp_add_alert @name=N'PageLifeExpectancy', 
		@message_id=0, 
		@severity=0, 
		@enabled=1, 
		@delay_between_responses=30, 
		@include_event_description_in=1, 
		@notification_message=N'ATENÇÃO! Page Life Expectancy < 267 segundos. Esse contador nos diz o tempo em segundos que uma página de memória fica no cache. 
							  Quanto maior esse tempo, maior é a chance do SQL Server encontrar a informação que precisa e assim economizar uma busca no disco.', 
		@category_name=N'[Uncategorized]', 
		@performance_condition=N'SQLServer:Buffer Manager|Page life expectancy||<|200', 
		@job_id=N'2be5100d-b70d-48fc-aee4-5b5ab0391eb1'
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Adiciona um operador para os alertas
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE [msdb]
GO

/****** Object:  Operator [DBACravil]    Script Date: 8/1/2017 5:58:49 PM ******/
EXEC msdb.dbo.sp_add_operator @name=N'DBA_Alerts_SetorTI', 
		@enabled=1, 
		@weekday_pager_start_time=0, 
		@weekday_pager_end_time=120000, 
		@saturday_pager_start_time=0, 
		@saturday_pager_end_time=120000, 
		@sunday_pager_start_time=0, 
		@sunday_pager_end_time=120000, 
		@pager_days=0, 
		@email_address=N'suporte@cravil.com.br', 
		@category_name=N'[Uncategorized]'
GO


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Vincula notificação para alerta de e-mail (conta do perfil do databaseMail)
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EXEC [msdb].[dbo].[sp_add_notification]
     @alert_name = N'PageLifeExpectancy',
     @operator_name = N'DBA_Alerts_SetorTI',
     @notification_method = 1;
GO

