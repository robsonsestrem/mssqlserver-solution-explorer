----------------------------------------------------------------------------------------------------------------------------------
-- Fonte -> http://www.fabriciolima.net/blog/2011/06/29/rotina-para-atualizar-as-estatisticas-do-seu-banco-de-dados/
----------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_UpdateStatisticsDB5]
WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
		if(OBJECT_ID('tempdb..#Atualiza_Estatisticas') is not null)
		drop table #Atualiza_Estatisticas

			Create table #Atualiza_Estatisticas
			(
				Id_Estatistica int identity(1,1),
				Ds_Comando varchar(4000),
				Nr_Linha int
			)

			;WITH Tamanho_Tabelas AS (
				SELECT sc.name as [schema], obj.name, prt.rows
					FROM sys.objects obj
					JOIN sys.indexes idx on obj.object_id= idx.object_id
					JOIN sys.partitions prt on obj.object_id= prt.object_id
					JOIN sys.allocation_units alloc on alloc.container_id= prt.partition_id
					join sys.schemas sc on sc.schema_id = obj.schema_id 
					WHERE obj.type= 'U' AND idx.index_id IN (0, 1)and prt.rows > 1000
					GROUP BY sc.name, obj.name, prt.rows)

				insert into #Atualiza_Estatisticas(Ds_Comando,Nr_Linha)
				SELECT 'UPDATE STATISTICS ' +D.[schema]+ '.'  + B.name+ ' ' + A.name+ ' WITH FULLSCAN', D.rows -- gera��o do script e contagem das linhas
					FROM sys.stats A
					join sys.sysobjects B on A.object_id = B.id
					join sys.sysindexes C on C.id = B.id and A.name= C.Name					
					JOIN Tamanho_Tabelas D on  B.name= D.Name
					WHERE  C.rowmodctr > 100
					and C.rowmodctr > D.rows *.005											 -- condi��o calculada para ver necessidade de atualizar
					and substring( B.name,1,3) not in ('sys','dtp')							 -- nega tabelas internas
					ORDER BY D.rows

			declare @Loop int, @Comando nvarchar(4000)
			set @Loop = 1
		BEGIN TRANSACTION
			while exists(select top 1 null from #Atualiza_Estatisticas)
				begin				
						select @Comando = Ds_Comando
						from #Atualiza_Estatisticas
						where Id_Estatistica = @Loop

						EXECUTE sp_executesql @Comando

						delete from #Atualiza_Estatisticas
						where Id_Estatistica = @Loop

						set @Loop= @Loop + 1
				end
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_UpdateStatisticsDB13]:<b> <br>
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
END