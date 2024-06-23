use Maintenance
go

CREATE OR ALTER PROCEDURE Management.sp_MonitoringSizeFreeDatafiles
(
 @percentFree float = 5
)
WITH ENCRYPTION
AS 
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
			IF(OBJECT_ID('tempdb..##tempDatafileFree') is not null)
				DROP TABLE ##tempDatafileFree

			CREATE TABLE ##tempDatafileFree(DatabaseName sysname , 
								LogicalName sysname , 
								PhysicalName nvarchar(100) , 
								Size_Gb decimal(18 , 2) ,					
								SpaceFree_Gb decimal(18 , 2) , 
								PercFreeFile decimal(18 , 2));   
			EXEC sp_msforeachdb '
			Use [?];
			INSERT INTO ##tempDatafileFree(DatabaseName , 
							   LogicalName , 
							   physicalName , 
							   size_Gb ,							  				  
							   SpaceFree_Gb , 
							   PercFreeFile)
			  SELECT DB_NAME()AS DatabaseName , 
				   Name , 
				   physical_name , 
				   CAST(CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2))AS nvarchar) as Size_Gb , 	   	          
				   --
				   CAST(CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2)) - 
				   CAST(FILEPROPERTY(name , ''SpaceUsed'') * 8.0 / 1024.0 AS decimal(18 , 2))AS nvarchar) AS SpaceFree_Gb ,
				   --
				   (CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2)) - 
				   CAST(FILEPROPERTY(name , ''SpaceUsed'') * 8.0 / 1024.0  AS decimal(18 , 2))) * 100 / 
				   CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2)AS decimal(18 , 2)) AS PercFreeFile

			  FROM sys.database_files;'

			  --delete from ##tempDatafileFree
			  --where DatabaseName like '%gescooper%'	-- Tratado para quando houver uma base que não precisa monitorar


			  ---------------------------------------------------------------------------------------------------------------------------------------------------
			  -- Valida as condições para o envio de e-mail
			  ---------------------------------------------------------------------------------------------------------------------------------------------------
			  IF((SELECT count(*) FROM ##tempDatafileFree AS t WHERE t.PercFreeFile <= @percentFree) > 0)
				BEGIN
					DECLARE 				
						@Assunto VARCHAR(200) = @@SERVERNAME + ' - Monitoramento de Espaço Livre nos DataFiles',
						@Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br',
						@Mensagem VARCHAR(MAX)
            		      
					SET @Mensagem = '
					Atenção DBA,<br>
					Espaço livre em algum(s) arquivos de dados (mdf, ndf e ldf) está reduzido (menor que 5%).
					<br>Obs.: Em caso de bases muito grandes foi calibrado para alertar em 3%.
					<br>Instância: ' + @@SERVICENAME + ' 
					<br>Servidor: ' + @@SERVERNAME + '
					<br><br> 

					<TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:1000t;font-family:Arial;font-size:14px>															
											<tr height=20  style=height:20.0pt align = left>
												<td bgcolor=#0B0B61 width=120> <font color=white>DatabaseName		</td>
												<td bgcolor=#0B0B61 width=120> <font color=white>LogicalName		</td>
												<td bgcolor=#0B0B61 width=650> <font color=white>PhysicalName		</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>Size_Gb			</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>SpaceUsed_GB		</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>SpaceFree_Gb		</td>
												<td bgcolor=#0B0B61 width=70> <font color=white>SpaceFree_%		</td>										
											</tr>
										 '	
				  SELECT @Mensagem = @Mensagem + 

				   CASE	  WHEN CAST(ROW_NUMBER() OVER(ORDER BY t.DatabaseName ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt align = left>'
									  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align = left>'
								   END +
								   '<td height=20 style=height:15.0pt>' + t.DatabaseName													+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + t.LogicalName													+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + t.PhysicalName													+ '</td>' +
								   --
								   '<td height=20 style=height:15.0pt>' + CAST(CAST(t.size_Gb / 1024 as decimal(18,2)) AS VARCHAR(20))	+ '</td>' + 
								   --
								   '<td height=20 style=height:15.0pt>' +	CAST(CAST((t.size_Gb - t.SpaceFree_Gb) / 
																			1024 as decimal(18,2))	AS VARCHAR(20))							+ '</td>' +		
								   --	
								   '<td height=20 style=height:15.0pt>' +	CAST(CAST((t.SpaceFree_Gb / 
																			1024) as decimal(18,2))	AS VARCHAR(20))							+ '</td>' +	
								   --		
								   '<td height=20 style=height:15.0pt>' +	CAST(t.PercFreeFile		AS VARCHAR(20))							+ '</td>' +		   
								   '</tr>'				      
				  from ##tempDatafileFree as t
				  where t.PercFreeFile <= @percentFree
				
				  SELECT @Mensagem = @Mensagem + 
							 '</table>'+'<br><br>'
				  ---------------------------------------------------------------------------------------------------------------------------------------------------
				  -- ***Envia o e-mail
				  ---------------------------------------------------------------------------------------------------------------------------------------------------
					EXEC msdb.dbo.sp_send_dbmail
						@profile_name = 'CRAVIL' ,	
						@recipients = @Destinatario ,	
						@subject = @Assunto,			
						@body = @Mensagem,				
						@body_format = 'HTML'

				END --fim do if
				DROP TABLE ##tempDatafileFree
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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_MonitoringSizeFreeDatafiles]:<b> <br>
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
END