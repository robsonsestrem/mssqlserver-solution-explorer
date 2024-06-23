use Maintenance
go

create or alter procedure Management.sp_loadRestartServer
with encryption
as
begin
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

	DECLARE @tb_Downtime TABLE
			([dth_Shutdown] DATETIME,
			 [dth_Start]    DATETIME,
			 [num_Minutos]  INT
			);

			DECLARE @des_PathTrace VARCHAR(250), @num_Arquivo INT;
			DECLARE @des_ArquivoAtual VARCHAR(300), @des_ArquivoAnterior VARCHAR(300);
			DECLARE @dth_Start DATETIME, @dth_Shutdown DATETIME;
			DECLARE @ind_ArquivoExiste INT 

			SELECT @num_Arquivo = CAST(SUBSTRING(RIGHT(path, CHARINDEX('\', REVERSE(path))-1), 5, LEN(RIGHT(path, CHARINDEX('\', REVERSE(path))-1-4-4))) AS INT), -- -4 = len('log_') and next -4 = len('.trc')
				   @des_PathTrace = SUBSTRING(path, 1, LEN(path)-CHARINDEX('\', REVERSE(path))+1)
			  FROM [sys].[traces]
			 WHERE [id] = 1;

			SET @ind_ArquivoExiste = 1;

			WHILE @ind_ArquivoExiste = 1
				BEGIN
					SET @des_ArquivoAtual = @des_PathTrace+'log_'+CAST(@num_Arquivo AS VARCHAR)+'.trc';

					SET @num_Arquivo = @num_Arquivo - 1;
					SET @des_ArquivoAnterior = @des_PathTrace+'log_'+CAST(@num_Arquivo AS VARCHAR)+'.trc';

					EXEC [master].[dbo].[xp_fileexist]
						 @des_ArquivoAnterior,
						 @ind_ArquivoExiste OUTPUT;

					IF @ind_ArquivoExiste = 1
						BEGIN
							SELECT @dth_Start = MIN([starttime])
							  FROM [fn_trace_gettable](@des_ArquivoAtual, 1)
							 WHERE [starttime] IS NOT NULL;

							SELECT @dth_Shutdown = MAX([starttime])
							  FROM [fn_trace_gettable](@des_ArquivoAnterior, 1)
							 WHERE [starttime] IS NOT NULL;

							INSERT INTO @tb_Downtime
							VALUES
							(@dth_Shutdown,
							 @dth_Start,
							 DATEDIFF(minute, @dth_Shutdown, @dth_Start)
							);
						END;
				END;
	begin transaction	

	insert into Maintenance.Management.HistoryRestartServer(ServerName, DateInsert, DateShutdown, DateStart, [Minutes])
	select @@SERVERNAME, getdate(),t1.dth_Shutdown, t1.dth_Start, t1.num_Minutos from @tb_Downtime as t1
	where t1.num_Minutos <> 0
	and t1.dth_Shutdown not in (
								select t2.DateShutdown
								from Maintenance.Management.HistoryRestartServer as t2
								)
	commit transaction
	end try
	BEGIN CATCH
		ROLLBACK TRANSACTION

		DECLARE @corpoFalha varchar(max)
		      , @subject VARCHAR(100)			-- assunto
		      , @recipients VARCHAR(100);		-- destinatário				
		SET @subject = 'Falha na execução de Procedure: '+@@SERVERNAME;
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_loadRestartServer]:<b> <br>
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

	SET NOCOUNT OFF
	SET TRANSACTION ISOLATION LEVEL READ COMMITTED
end


---------------------------------------------------------------------------------------------------------------------------
-- Criação da Tabela que é alimentada para Complementar Checklist
---------------------------------------------------------------------------------------------------------------------------
--create table management.HistoryRestartServer
--	(
--	IdRestart int not null identity(1,1) primary key,
--	ServerName varchar(20) not null, 
--	DateInsert datetime not null,
--	DateShutdown datetime not null,
--	DateStart datetime not null,
--	[Minutes] int not null
--	)