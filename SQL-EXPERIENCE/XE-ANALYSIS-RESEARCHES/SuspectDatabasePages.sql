------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referências
-- http://www.dbinternals.com.br/?p=1245
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT [A].[database_id] AS [cod_database],
       [B].[name] AS [nom_database],
       [A].file_id AS [cod_Arquivo],
       [C].[physical_name] AS [des_Arquivo],
       [A].[page_id] AS [cod_Pagina],
       CASE
           WHEN [A].[event_type] = 1
           THEN '823 or 824 error other than a bad checksum or a torn page'
           WHEN [A].[event_type] = 2
           THEN 'Bad checksum'
           WHEN [A].[event_type] = 3
           THEN 'Torn Page'
           WHEN [A].[event_type] = 4
           THEN 'Restored (The page was restored after it was marked bad)'
           WHEN [A].[event_type] = 5
           THEN 'Repaired (DBCC repaired the page)'
           WHEN [A].[event_type] = 7
           THEN 'Deallocated by DBCC'
       END AS [des_Erro],
       [A].[error_count] AS [qtd_Erro],
       [A].[last_update_date] AS [dth_UltimaAtualizacao]
  FROM [msdb].[dbo].[suspect_pages] AS [A]
       INNER JOIN [sys].[databases] AS [B] ON [B].[database_id] = [A].[database_id]
       INNER JOIN [sys].[master_files] AS [C] ON [C].[database_id] = [A].[database_id]
                                                 AND [C].file_id = [A].file_id;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--De acordo com o MSDN (https://msdn.microsoft.com/pt-br/library/ms191301(v=sql.110).aspx), temos que:

--Uma página é considerada “suspeita” quando o Mecanismo de Banco de Dados do SQL Server encontra um dos seguintes erros ao tentar ler uma página de dados:

--– Um erro 823 causado por uma CRC (verificação de redundância cíclica) emitido por um sistema operacional como, por exemplo, um erro de disco (certos erros de hardware)
--– Um erro 824, como uma página interrompida (qualquer erro lógico)

--A ID de cada página suspeita é registrada na tabela suspect_pages. O Mecanismo de Banco de Dados registra qualquer página suspeita encontrada durante o processamento regular, como o seguinte:

--– Uma consulta precisa ler uma página.
--– Durante uma operação DBCC CHECKDB.
--– Durante uma operação de backup.
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE Maintenance;
GO

CREATE EVENT SESSION [suspect_pages_event] ON SERVER 
ADD EVENT sqlserver.database_suspect_data_page
ADD TARGET package0.event_file
(SET filename=N'C:\DBACravil\ExtendedEvents\SuspectPages.xel',
 max_file_size = (10),
 max_rollover_files = (20)
)
WITH (MAX_MEMORY=4096 KB,
      EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,
	 MAX_DISPATCH_LATENCY=30 SECONDS,
	 MAX_EVENT_SIZE=0 KB,
	 MEMORY_PARTITION_MODE=NONE,
	 TRACK_CAUSALITY=OFF,
	 STARTUP_STATE=ON)
GO

-- Start the event session  
ALTER EVENT SESSION [suspect_pages_event]  
ON SERVER  
STATE = start;  
GO  

-- Obtain live session statistics   
select * from sys.dm_xe_packages	-- pacotes dos eventos
SELECT * FROM sys.dm_xe_sessions;  
SELECT * FROM sys.dm_xe_session_events;  
GO  

-- Add new events to the session  
ALTER EVENT SESSION [suspect_pages_event] ON SERVER  
ADD EVENT sqlserver.database_transaction_begin,  
ADD EVENT sqlserver.database_transaction_end;  
GO 


-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Para monitorar o arquivo gerado pelo EVENT SESSION:
-----------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @FileName NVARCHAR(4000);

SELECT @FileName = [target_data].value('(EventFileTarget/File/@name)[1]', 'nvarchar(4000)')
  FROM (SELECT CAST([target_data] AS XML) AS [target_data]
          FROM [sys].[dm_xe_sessions] AS [s]
               INNER JOIN [sys].[dm_xe_session_targets] AS [t] ON [s].[address] = [t].[event_session_address]
         WHERE [s].[name] = N'suspect_pages_event') AS [ft];

SELECT [XEData].value('(event/data[@name=database_id]/value)[1]', 'varchar(max)') AS [database_id],
       DB_NAME([XEData].value('(event/data[@name=database_id]/value)[1]', 'varchar(max)')) AS [database_name],
       [XEData].value('(event/data[@name=file_id]/value)[1]', 'varchar(max)') AS file_id,
       [XEData].value('(event/data[@name=page_id]/value)[1]', 'varchar(max)') AS [page_id],
       [XEData].value('(event/data[@name=page_error]/value)[1]', 'varchar(max)') AS [page_error_value],
       [XEData].value('(event/data[@name=page_error]/text)[1]', 'varchar(max)') AS [page_error_text]
  FROM (SELECT CAST([event_data] AS XML) AS [XEData]
          FROM [sys].[fn_xe_file_target_read_file](@FileName, NULL, NULL, NULL)) AS [event_data];