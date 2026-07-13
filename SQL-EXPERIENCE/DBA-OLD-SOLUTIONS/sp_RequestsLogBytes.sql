USE YOUR_DATABASE
GO

create or alter procedure Management.sp_RequestsLogBytes
with encryption
as
begin	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

	BEGIN TRY 
		begin transaction

		insert into [Management].[HistoryRequestLogBytes]
		(
			[session_id] ,
			[open_transaction_count],
			[status],
			[Login Name],
			[Database],
			[Begin Time],
			[Log Bytes],
			[Log Rsvd],
			[Last T-SQL Text],
			[Last Plan]			 
		)
		SELECT
			[s_tst].[session_id],
			[s_er].open_transaction_count,
			[s_es].status,
			[s_es].[login_name] AS [Login Name],
			DB_NAME (s_tdt.database_id) AS [Database],
			[s_tdt].[database_transaction_begin_time] AS [Begin Time],			
			[s_tdt].[database_transaction_log_bytes_used] AS [Log Bytes],		
			[s_tdt].[database_transaction_log_bytes_reserved] AS [Log Rsvd],	
			[s_est].text AS [Last T-SQL Text],									
			[s_eqp].[query_plan] AS [Last Plan]									
		FROM
			sys.dm_tran_database_transactions [s_tdt]
		JOIN
			sys.dm_tran_session_transactions [s_tst]
		ON
			[s_tst].[transaction_id] = [s_tdt].[transaction_id]
		JOIN
			sys.[dm_exec_sessions] [s_es]
		ON
			[s_es].[session_id] = [s_tst].[session_id]
		JOIN
			sys.dm_exec_connections [s_ec]
		ON
			[s_ec].[session_id] = [s_tst].[session_id]
		LEFT OUTER JOIN
			sys.dm_exec_requests [s_er]
		ON
			[s_er].[session_id] = [s_tst].[session_id]
		CROSS APPLY
			sys.dm_exec_sql_text ([s_ec].[most_recent_sql_handle]) AS [s_est]
		OUTER APPLY
			sys.dm_exec_query_plan ([s_er].[plan_handle]) AS [s_eqp]

	    WHERE [s_es].session_id <> @@SPID
			AND ([s_es].[status] <> 'sleeping' OR ([s_es].[status] = 'sleeping' AND [s_er].open_transaction_count > 0))

		commit transaction 
	END TRY 

	BEGIN CATCH
			ROLLBACK TRANSACTION
			DECLARE @corpoFalha varchar(max)
				  , @subject VARCHAR(100)			-- assunto
				  , @recipients VARCHAR(100);		-- destinat�rio				
			SET @subject = 'Falha na execu��o de Procedure: '+@@SERVERNAME;
			SET @recipients = 'suporte@cravil.com.br';
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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_RequestsLogBytes]:<b> <br>
				  </td>
				 </tr>
				 <tr height=20 style=height:20.0pt>
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
					  <br> [ERROR NUMBER] - '+ cast(ERROR_NUMBER() as varchar(10)) + '
					  <br>				  
					  <br> [LINE] - '+ cast(ERROR_LINE() as varchar(10)) + '
					  <br>
					  <br> [MESSAGE] - '+  ERROR_MESSAGE() + '
				   </td>
				  </tr>
			</table>'

			SELECT @corpoFalha = @corpoFalha + 
				'</div>
				</body>
				</html>'

			EXEC [msdb].[dbo].[sp_send_dbmail]
					@recipients = @recipients,
					@subject = @subject,
					@profile_name = 'CRAVIL',
					@body = @corpoFalha,
					@body_format = 'HTML';

			END CATCH

	SET TRANSACTION ISOLATION LEVEL READ COMMITTED 

end






