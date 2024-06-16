USE Maintenance

GO

--DROP EVENT SESSION evt_Rollback ON SERVER;
--GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Criar EX
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT SESSION Rollback_GesCooper90
ON SERVER
ADD EVENT sqlserver.sql_transaction (
  ACTION (package0.collect_system_time,
		 sqlos.task_time,
		 sqlserver.client_app_name,
		 sqlserver.client_hostname,
		 sqlserver.database_id,
		 sqlserver.database_name,
		 sqlserver.session_id,
		 sqlserver.sql_text,
		 sqlserver.tsql_frame,
		 sqlserver.username)    
  WHERE transaction_state = 2     
   And  session_id > 50
   AND [sqlserver].[database_name] = N'GesCooper90' 
   and [sqlserver].[username] <> N'gescooper'
   And object_name <> 'TVQuery'
)
ADD TARGET package0.event_file(SET filename=N'C:\DBACravil\ExtendedEvents\Rollback_Report.xel',max_file_size=(50),max_rollover_files=(25));
-- CASO QUEIRA ARMAZENAR OS EVENTOS NO ring_buffer
-- ADD TARGET package0.ring_buffer(SET max_events_limit=(5000),max_memory=(4096))


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Criar a tabela que será utilizada para guardar os rollbacks gerados
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance
GO
IF OBJECT_ID('[Management].[HistoryRollback]') IS NOT NULL
    DROP TABLE Management.[HistoryRollback]; 
GO

CREATE TABLE Management.[HistoryRollback]
([cod_Rollback]                 INT IDENTITY
                                    NOT NULL,
 [dth_InicioTransacao]          DATETIME2 NULL,
 [dth_FinalTransacao]           DATETIME2 NULL,
 [val_DuracaoTransacaoSegundos] BIGINT NULL,
 [val_DuracaoRollbackSegundos]  BIGINT NULL,
 [cod_Sessao]                   INT NULL,
 [cod_Database]                 INT NULL,
 [nom_Database]                 VARCHAR(MAX) NULL,
 [des_Usuario]                  VARCHAR(MAX) NULL,
 [des_HostName]                 VARCHAR(MAX) NULL,
 [des_AppName]                  VARCHAR(MAX) NULL,
 [des_EstadoTransacao]          NVARCHAR(MAX) NULL,
 [num_Handle]                   VARCHAR(MAX) NULL,
 [sql_Text]                     NVARCHAR(MAX) NULL,
 CONSTRAINT [PK_tb_Rollback] PRIMARY KEY([cod_Rollback])
);


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Busca e inserção dos dados com base no arquivo .xel
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO  Management.[HistoryRollback]
([dth_InicioTransacao],
 [dth_FinalTransacao],
 [val_DuracaoTransacaoSegundos],
 [val_DuracaoRollbackSegundos],
 [cod_Sessao],
 [cod_Database],
 [nom_Database],
 [des_Usuario],
 [des_HostName],
 [des_AppName],
 [des_EstadoTransacao],
 [num_Handle],
 [sql_Text]
)
SELECT DATEADD([second], ([target_data].value('(event/data[@name=duration])[1]', 'bigint')/1000000)*-1, DATEADD([hh], DATEDIFF([hh], GETUTCDATE(), CURRENT_TIMESTAMP), 
	   [target_data].value('(event/@timestamp)[1]', 'datetime2'))) AS [dth_InicioTransacao],
       DATEADD([hh], DATEDIFF([hh], GETUTCDATE(), CURRENT_TIMESTAMP), [target_data].value('(event/@timestamp)[1]', 'datetime2')) AS [dth_FinalTransacao],
       [target_data].value('(event/data[@name=duration])[1]', 'bigint')/1000000 AS [val_DuracaoTransacaoSegundos],
       [target_data].value('(event/action[@name=task_time])[1]', 'bigint')/1000000 AS [val_DuracaoRollbackSegundos],
       [target_data].value('(event/action[@name=session_id])[1]', 'int') AS [session_id],
       [target_data].value('(event/action[@name=database_id])[1]', 'int') AS [database_id],
	   DB_NAME([target_data].value('(event/action[@name=database_id])[1]', 'int')) AS [nom_Database],
       [target_data].value('(event/action[@name=username])[1]', 'varchar(max)') AS [des_Usuario],
       [target_data].value('(event/action[@name=client_hostname])[1]', 'varchar(max)') AS [des_HostName],
       [target_data].value('(event/action[@name=client_app_name])[1]', 'varchar(max)') AS [des_AppName],
       [target_data].value('(event/data[@name=transaction_state]/text)[1]', 'nvarchar(max)') AS [transaction_state],
       [frame_data].value('./@handle', 'varchar(max)') AS [num_handle],
       [target_data].value('(event/action[@name=sql_text])[1]', 'nvarchar(max)') AS [sql_text]
  FROM (SELECT CAST([event_data] AS XML) AS [target_data]
          FROM [sys].[fn_xe_file_target_read_file](N'C:\DBACravil\ExtendedEvents\Rollback_Report_0_131745155695760000.xel', NULL, NULL, NULL)) AS [s]
       OUTER APPLY [target_data].[nodes]('event/action[@name=tsql_frame]/value/frame') AS [Frame]([frame_data]);


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Busca e inserção dos dados com base no ring_buffer
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO Management.[HistoryRollback]
([dth_InicioTransacao],
 [dth_FinalTransacao],
 [val_DuracaoTransacaoSegundos],
 [val_DuracaoRollbackSegundos],
 [cod_Sessao],
 [cod_Database],
 [nom_Database],
 [des_Usuario],
 [des_HostName],
 [des_AppName],
 [des_EstadoTransacao],
 [num_Handle],
 [sql_Text]
)
SELECT DATEADD([second], ([event].value('(event/data[@name=duration])[1]', 'bigint')/1000000)*-1, DATEADD([hh], DATEDIFF([hh], GETUTCDATE(), CURRENT_TIMESTAMP), 
       [event].value('(event/@timestamp)[1]', 'datetime2'))) AS [dth_InicioTransacao],
       DATEADD([hh], DATEDIFF([hh], GETUTCDATE(), CURRENT_TIMESTAMP), [event].value('(event/@timestamp)[1]', 'datetime2')) AS [dth_FinalTransacao],
       [event].value('(event/data[@name=duration])[1]', 'bigint')/1000000 AS [val_DuracaoTransacaoSegundos],
       [event].value('(event/action[@name=task_time])[1]', 'bigint')/1000000 AS [val_DuracaoRollbackSegundos],
       [event].value('(event/action[@name=session_id])[1]', 'int') AS [session_id],
       [event].value('(event/action[@name=database_id])[1]', 'int') AS [database_id],
	  DB_NAME([event].value('(event/action[@name=database_id])[1]', 'int')) AS [nom_Database],
       [event].value('(event/action[@name=username])[1]', 'varchar(max)') AS [des_Usuario],
       [event].value('(event/action[@name=client_hostname])[1]', 'varchar(max)') AS [des_HostName],
       [event].value('(event/action[@name=client_app_name])[1]', 'varchar(max)') AS [des_AppName],
       [event].value('(event/data[@name=transaction_state]/text)[1]', 'nvarchar(max)') AS [transaction_state],
       [frame_data].value('./@handle', 'varchar(max)') AS [num_handle],
       [event].value('(event/action[@name=sql_text])[1]', 'nvarchar(max)') AS [sql_text]
  FROM (SELECT [n].[query]('.') AS [event]
          FROM
        (
            SELECT CAST([target_data] AS XML) AS [target_data]
              FROM [sys].[dm_xe_sessions] AS [s]
                   JOIN [sys].[dm_xe_session_targets] AS [t] ON [s].[address] = [t].[event_session_address]
             WHERE [s].[name] = 'Rollback_GesCooper90'
                   AND [t].[target_name] = 'ring_buffer'
        ) AS [s]
        CROSS APPLY [target_data].[nodes]('RingBufferTarget/event') AS [q]([n])) AS [t]
       CROSS APPLY [event].[nodes]('event/action[@name=tsql_frame]/value/frame') AS [Frame]([frame_data]);
