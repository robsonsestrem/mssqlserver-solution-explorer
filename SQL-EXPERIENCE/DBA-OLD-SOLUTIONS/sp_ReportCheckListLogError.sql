USE Maintenance
GO

CREATE OR ALTER PROCEDURE Management.sp_ReportCheckListLogError
WITH ENCRYPTION
AS
BEGIN 
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @des_MensagemHTML VARCHAR(MAX);
			/**************************************************************************************************************/
			/* Início do HTML                                                                                             */
			
			Set @des_MensagemHTML = '	
			<html>
			<head>
			<meta http-equiv=Content-Type content=text/html; charset=windows-1252>
			</head>

			<body>
			<div align=center>'

			/**************************************************************************************************************/
			/* Server Info.sql                                                                                            */

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:20px>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Dados do Arquivo de Log Current  - ' + CONVERT(VARCHAR, GETDATE(), 103) + '<b></td>
			 </tr>
			 <tr height=20 style=height:15.0pt>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center><b>Servidor: ' + @@SERVERNAME + '<b></td>
			 </tr>
			 <tr height=20>
			  <td height=20 colspan=7 style=height:20.0pt></td>
			 </tr>
			</table> '


			/* 06 - Resumo de erros log                                                                                   */

			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:16px>
			  <tr height=20  style=color: #FFFFFF; background: #44546A;>
			  <td height=20 colspan=7 style=height:20.0pt;text-align:center>Resumo das Informações</td>
			  </tr>
			</table> '
			Set @des_MensagemHTML = @des_MensagemHTML + '
			<table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
			<tr height=20  style=color: #FFFFFF; background: #44546A;>
			<td width=200 style=height:20.0pt>Data</td>
			<td width=200 style=height:20.0pt;>Origem</td>
			<td width=650 style=height:20.0pt;>Descrição</td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			<td width=0 style=height:20.0pt;></td>
			</tr>'

			CREATE TABLE [#ERRORLOG]
			([RowID]     INT IDENTITY(1,1) PRIMARY KEY,
			 [EntryTime] DATETIME,
			 [source]    VARCHAR(50),
			 [LogEntry]  VARCHAR(4000)
			);

			DECLARE @Command NVARCHAR(128);

			SET @Command = 'exec master.dbo.xp_readerrorlog 0';

			INSERT INTO [#ERRORLOG]
			EXEC [sp_executesql]
				 @Command;

			DELETE [#ERRORLOG]
			 WHERE
			   ([LogEntry] NOT LIKE '%err%'
				AND [LogEntry] NOT LIKE '%warn%'
				AND [LogEntry] NOT LIKE '%kill%'
				AND [LogEntry] NOT LIKE '%dead%'
				AND [LogEntry] NOT LIKE '%cannot%'
				AND [LogEntry] NOT LIKE '%could%'
				AND [LogEntry] NOT LIKE '%fail%'
				AND [LogEntry] NOT LIKE '%not%'
				AND [LogEntry] NOT LIKE '%stop%'
				AND [LogEntry] NOT LIKE '%terminate%'
				AND [LogEntry] NOT LIKE '%bypass%'
				AND [LogEntry] NOT LIKE '%roll%'
				AND [LogEntry] NOT LIKE '%truncate%'
				AND [LogEntry] NOT LIKE '%upgrade%'
				AND [LogEntry] NOT LIKE '%victim%'
				AND [LogEntry] NOT LIKE '%recover%'
				AND [LogEntry] NOT LIKE '%IO requests taking longer than%')
			   OR [LogEntry] LIKE '%errorlog%'
			   OR [LogEntry] LIKE '%dbcc%'
			   OR [LogEntry] LIKE '%The Service Broker endpoint is in disabled or stopped state%';

			DELETE [#ERRORLOG]
			 WHERE [EntryTime] IS NULL
				   OR [EntryTime] < DATEADD(hour, -24, GETDATE())
				   OR [LogEntry] IS NULL;

			SELECT @des_MensagemHTML = @des_MensagemHTML + 
				   CASE
					  WHEN CAST(ROW_NUMBER() OVER(ORDER BY [EntryTime] DESC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt>'
					  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4;>'
				   END +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast(CONVERT( VARCHAR, [EntryTime], 113) as varchar(max)), '')  + '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([source] as varchar(max)), '')  + '</td>' +
				   '<td height=20 style=height:15.0pt>' + IsNull(Cast([LogEntry] as varchar(max)), '')  + '</td>' +
				  '<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					<td width=0 style=height:15.0pt;></td>
					</tr>'
			  FROM [#ERRORLOG]
			 ORDER BY [EntryTime] DESC;

			DROP TABLE [#ERRORLOG];

			 SELECT @des_MensagemHTML = @des_MensagemHTML + 
			 '</table>'
  
			  SELECT @des_MensagemHTML = @des_MensagemHTML + 
			'</div>
			</body>
			</html>'

			DECLARE @subject VARCHAR(100), @recipients VARCHAR(100);

			SET @subject = 'CheckList Diário - Log de erros SQL Server';
			SET @recipients = 'agenteti@cravil.com.br';

			EXEC [msdb].[dbo].[sp_send_dbmail]
				@recipients = @recipients,
				@subject = @subject,
				@profile_name = 'CRAVIL',
				@body = @des_MensagemHTML,
				@body_format = 'HTML';
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION

		DECLARE @corpoFalha varchar(max)		     			
		SET @subject = 'Falha na execução de Procedure: '+@@SERVERNAME;
		SET @recipients = 'agenteti@cravil.com.br';
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_ReportCheckListLogError]:<b> <br>
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
	SET NOCOUNT OFF;
END