USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_CreateTrace]
WITH ENCRYPTION
AS
BEGIN
    declare @rc int, 
			@TraceID INT,	
			@maxfilesize bigint, 
			@on bit, 
			@intfilter int, 
			@bigintfilter bigint
	
	BEGIN TRY
		BEGIN TRANSACTION
			select @on = 1, @maxfilesize = 1000000
			-- Cria��o do trace
			exec @rc = sp_trace_create @TraceID output, 0, N'C:\DBACravil\Trace\Querys_Demoradas', @maxfilesize, NULL
			if (@rc != 0) goto error
			exec sp_trace_setevent @TraceID, 10, 1, @on 
			exec sp_trace_setevent @TraceID, 10, 6, @on 
			exec sp_trace_setevent @TraceID, 10, 8, @on 
			exec sp_trace_setevent @TraceID, 10, 10, @on
			exec sp_trace_setevent @TraceID, 10, 11, @on
			exec sp_trace_setevent @TraceID, 10, 12, @on
			exec sp_trace_setevent @TraceID, 10, 13, @on
			exec sp_trace_setevent @TraceID, 10, 14, @on
			exec sp_trace_setevent @TraceID, 10, 15, @on
			exec sp_trace_setevent @TraceID, 10, 16, @on
			exec sp_trace_setevent @TraceID, 10, 17, @on
			exec sp_trace_setevent @TraceID, 10, 18, @on
			exec sp_trace_setevent @TraceID, 10, 26, @on
			exec sp_trace_setevent @TraceID, 10, 35, @on
			exec sp_trace_setevent @TraceID, 10, 40, @on
			exec sp_trace_setevent @TraceID, 10, 48, @on
			exec sp_trace_setevent @TraceID, 10, 64, @on
			exec sp_trace_setevent @TraceID, 12, 1,  @on
			exec sp_trace_setevent @TraceID, 12, 6,  @on
			exec sp_trace_setevent @TraceID, 12, 8,  @on
			exec sp_trace_setevent @TraceID, 12, 10, @on
			exec sp_trace_setevent @TraceID, 12, 11, @on
			exec sp_trace_setevent @TraceID, 12, 12, @on
			exec sp_trace_setevent @TraceID, 12, 13, @on
			exec sp_trace_setevent @TraceID, 12, 14, @on
			exec sp_trace_setevent @TraceID, 12, 15, @on
			exec sp_trace_setevent @TraceID, 12, 16, @on
			exec sp_trace_setevent @TraceID, 12, 17, @on
			exec sp_trace_setevent @TraceID, 12, 18, @on
			exec sp_trace_setevent @TraceID, 12, 26, @on
			exec sp_trace_setevent @TraceID, 12, 35, @on
			exec sp_trace_setevent @TraceID, 12, 40, @on
			exec sp_trace_setevent @TraceID, 12, 48, @on
			exec sp_trace_setevent @TraceID, 12, 64, @on

			set @bigintfilter = 30000000								-- valor de microssegundos que d� 30 segundos
			exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

			-- Set the trace status to start
			exec sp_trace_setstatus @TraceID, 1
			goto finish
			error:
			select ErrorCode=@rc
			finish:
		COMMIT TRANSACTION
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_CreateTrace]:<b> <br>
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
END
GO


