USE YOUR_DATABASE
GO
/*
Exemplo de uso:
EXECUTE Management.sp_MonitoringSpaceDisk @percentualUsado = 80
https://www.dirceuresende.com/blog/sql-server-como-identificar-e-monitorar-os-discos-espaco-em-disco-total-livre-e-utilizado/
*/

CREATE OR ALTER PROCEDURE Management.sp_MonitoringSpaceDisk
(
	@percentualUsado FLOAT = 70
)
WITH ENCRYPTION
AS 
BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
			IF (OBJECT_ID('tempdb..##Monitoramento_Espaco_Disco') IS NOT NULL) 
				DROP TABLE ##Monitoramento_Espaco_Disco

			CREATE TABLE ##Monitoramento_Espaco_Disco
			(
			IdEfeitoZebrado int identity(1,1),
			[Montagem] NVARCHAR(10),
			[Volume] NVARCHAR(50),
			[Espa�oTotal_Gb] DECIMAL(19,2),
			[TotalDisponivel_Gb] DECIMAL(19,2),
			[TotalUsado_Gb] DECIMAL(19,2),
			[Disponivel_%] DECIMAL(10,2),
			[Utilizado_%] DECIMAL(10,2)
			)

			INSERT INTO ##Monitoramento_Espaco_Disco
			SELECT DISTINCT
					VS.volume_mount_point [Montagem] ,
					VS.logical_volume_name AS [Volume] ,
					CAST(CAST(VS.total_bytes AS DECIMAL(19, 2)) / 1024 / 1024 / 1024 AS DECIMAL(10, 2)) AS [Espa�oTotal_Gb] ,
					CAST(CAST(VS.available_bytes AS DECIMAL(19, 2)) / 1024 / 1024 / 1024 AS DECIMAL(10, 2)) AS [TotalDisponivel_Gb],
					CAST(CAST((VS.total_bytes - VS.available_bytes) AS DECIMAL(19,2)) / 1024 / 1024 / 1024 AS DECIMAL(19,2)) AS [TotalUsado_Gb],
					CAST(( CAST(VS.available_bytes AS DECIMAL(19, 2)) / CAST(VS.total_bytes AS DECIMAL(19, 2)) * 100 ) AS DECIMAL(10, 2)) AS [Disponivel_%] ,
					CAST(( 100 - CAST(VS.available_bytes AS DECIMAL(19, 2)) / CAST(VS.total_bytes AS DECIMAL(19, 2)) * 100 ) AS DECIMAL(10, 2)) AS [Utilizado_%] 
				FROM
					sys.master_files AS MF
					CROSS APPLY [sys].[dm_os_volume_stats](MF.database_id, MF.file_id) AS VS
				WHERE
					CAST(VS.available_bytes AS DECIMAL(19, 2)) / CAST(VS.total_bytes AS DECIMAL(19, 2)) * 100 < 100
				
			------------------------------------------------------------
			-- ENVIA NOTIFICA��O
			------------------------------------------------------------
			IF ((SELECT COUNT(IdEfeitoZebrado) FROM ##Monitoramento_Espaco_Disco as m 
				 WHERE m.[Utilizado_%] >= @percentualUsado ) > 0)
			BEGIN        
				DECLARE 				
					@Assunto VARCHAR(200) = @@SERVERNAME + ' - Monitoramento de Espa�o no Disco dos DataFiles',
					@Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br',
					@Mensagem VARCHAR(MAX)
            		      
				SET @Mensagem = '
				Prezado DBA,<br>
				Espa�o utilizado em disco aumentou consideravelmente (maior que 80% usado), detalhes abaixo:
				<br>Inst�ncia: ' + @@SERVICENAME + ' 
				<br>Servidor: ' + @@SERVERNAME + '
				<br><br> 

				<TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:900pt;font-family:Arial;font-size:14px>															
										<tr height=20  style=height:20.0pt align = left>
											<td bgcolor=#0B0B61 width=120> <font color=white>Montagem				</td>
											<td bgcolor=#0B0B61 width=120> <font color=white>Volume				</td>
											<td bgcolor=#0B0B61 width=120> <font color=white>Espa�oTotal_Gb		</td>
											<td bgcolor=#0B0B61 width=120> <font color=white>TotalDisponivel_Gb	</td>
											<td bgcolor=#0B0B61 width=120> <font color=white>TotalUsado_Gb		</td>
											<td bgcolor=#0B0B61 width=120> <font color=white>Disponivel_%			</td>
											<td bgcolor=#0B0B61 width=120> <font color=white>Utilizado_%			</td>										
										</tr>
									  '			
						SELECT  @Mensagem = @Mensagem + 
							   CASE
								  WHEN CAST(ROW_NUMBER() OVER(ORDER BY m.IdEfeitoZebrado ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt align = left>'
								  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align = left>'
							   END +
							   '<td height=20 style=height:15.0pt>' + m.Montagem									+ '</td>' +
							   '<td height=20 style=height:15.0pt>' + m.Volume									+ '</td>' +
							   '<td height=20 style=height:15.0pt>' + CAST(m.Espa�oTotal_Gb		AS VARCHAR(20))	+ '</td>' +
							   '<td height=20 style=height:15.0pt>' + CAST(m.TotalDisponivel_Gb	AS VARCHAR(20))	+ '</td>' + 
							   '<td height=20 style=height:15.0pt>' +	CAST(m.TotalUsado_Gb		AS VARCHAR(20))	+ '</td>' +			
							   '<td height=20 style=height:15.0pt>' +	CAST(m.[Disponivel_%]		AS VARCHAR(20))	+ '</td>' +			
							   '<td height=20 style=height:15.0pt>' +	CAST(m.[Utilizado_%]		AS VARCHAR(20))	+ '</td>' +		   
							   '</tr>'
						  FROM ##Monitoramento_Espaco_Disco	as m			 
						  WHERE m.[Utilizado_%] >= @percentualUsado

						SELECT @Mensagem = @Mensagem + 
						 '</table>'+'<br><br>'

				------------------------------------------------------------
				-- ***Envia o e-mail
				------------------------------------------------------------
				EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'CRAVIL' ,	-- sysname
					@recipients = @Destinatario ,	-- varchar(max)
					@subject = @Assunto,			-- nvarchar(255)
					@body = @Mensagem,				-- nvarchar(max)
					@body_format = 'HTML'

			END -- fim do if

			DROP TABLE ##Monitoramento_Espaco_Disco
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_MonitoringSpaceDisk]:<b> <br>
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