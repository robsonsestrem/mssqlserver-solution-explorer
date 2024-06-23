use Maintenance
go

create or alter procedure Management.sp_DeleteCountersPerfMon
(
 @qtdadeManterDias int = 60
)
with encryption
as
begin
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		BEGIN TRANSACTION 
		-- Busca quantidade de dias
		declare @qtdade int = 
		(
			select count(*)
			from(
					select
					x.[Date] as Dia			
					from
				(
					SELECT 
					cast(CONVERT(VARCHAR(10),CONVERT(varchar,CounterDateTime),101) as date) as [Date]
					FROM dbo.CounterData
	
				) as x
				group by x.[Date]
			)as x2
		)

		declare @dataMin datetime

		-- Trata a quantidade para ficar apenas com x dias de registros
		while (@qtdade > @qtdadeManterDias)
		begin 
			set @dataMin =
			(
			   select min(x2.Dia)
			   from
				(select
					x.Date as Dia
					from
					(
					SELECT 
					cast(CONVERT(VARCHAR(10),CONVERT(varchar,CounterDateTime),101) as date) as [Date]
					FROM dbo.CounterData	
					) as x
					group by x.Date
				) as x2
			)
			print 'Deletando dados do dia -> ' + cast(@dataMin as varchar(20))

			delete from dbo.CounterData 
			where cast(convert(varchar(10),convert(varchar,CounterDateTime),101) as date) <= @dataMin
	
			set @qtdade -= 1
		end -- fim do while

		COMMIT TRANSACTION
	END TRY		
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteCountersPerfMon]:<b> <br>
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
