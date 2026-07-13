USE YOUR_DATABASE
GO
/*
Refer�ncia:
https://www.dirceuresende.com/blog/sql-server-como-identificar-e-monitorar-o-espaco-em-disco-total-livre-e-utilizado-pelos-datafiles-dos-databases/
EXEMPLO DE USO:
EXEC Management.sp_MonitoringSizeLimitDatafiles
    @Vl_Limite = 40 -- float
*/

CREATE OR ALTER PROCEDURE [Management].[sp_MonitoringSizeLimitDatafiles] (
    @Vl_Limite FLOAT = 95
	-- no caso trazer as bases que atingiram 94% de utiliza��o de espa�o limite proposto
)
WITH ENCRYPTION
AS BEGIN
	SET NOCOUNT ON
	BEGIN TRY
		BEGIN TRANSACTION
			------------------------------------------------------------------------------------------------
			-- IDENTIFICA��O DO ESPA�O UTILIZADO PELOS DATAFILES
			------------------------------------------------------------------------------------------------
			DECLARE @Monitor_Datafile_Size TABLE
				(
				database_id int,
				[database_name] sysname,
				state_desc varchar(50),
				[type_desc] varchar(10),
				[file_id] int,
				[name] sysname,
				physical_name varchar(100),
				disk_total_size_GB numeric(18,2),
				disk_free_size_GB numeric(18,2),
				size_GB numeric(18,2),
				max_size_GB numeric(18,2),
				max_real_size_GB numeric(18,2),
				free_space_GB numeric(18,2),
				growth_MB numeric(18,2),
				is_percent_growth bit,
				is_autogrowth_enabled int,
				percent_used numeric(18,2),
				growth_times int
				)

			INSERT INTO @Monitor_Datafile_Size
			SELECT
				B.database_id AS database_id,
				B.[name] AS [database_name],
				A.state_desc,
				A.[type_desc],
				A.[file_id],
				A.[name],
				A.physical_name,
				CAST(C.total_bytes / 1073741824.0 AS NUMERIC(18, 2)) AS disk_total_size_GB,
				CAST(C.available_bytes / 1073741824.0 AS NUMERIC(18, 2)) AS disk_free_size_GB,
				CAST(A.size / 128 / 1024.0 AS NUMERIC(18, 2)) AS size_GB,
				CAST(A.max_size / 128 / 1024.0 AS NUMERIC(18, 2)) AS max_size_GB,
				CAST(
					(CASE
						WHEN A.growth <= 0 THEN A.size / 128 / 1024.0
						WHEN A.max_size <= 0 THEN C.total_bytes / 1073741824.0
						WHEN A.max_size / 128 / 1024.0 > C.total_bytes / 1073741824.0 THEN C.total_bytes / 1073741824.0
						ELSE A.max_size / 128 / 1024.0 
					END) AS NUMERIC(18, 2)) AS max_real_size_GB,
				CAST(NULL AS NUMERIC(18, 2)) AS free_space_GB,
				(CASE WHEN A.is_percent_growth = 1 THEN A.growth ELSE CAST(A.growth / 128 AS NUMERIC(18, 2)) END) AS growth_MB,
				A.is_percent_growth,
				(CASE WHEN A.growth <= 0 THEN 0 ELSE 1 END) AS is_autogrowth_enabled,
				CAST(NULL AS NUMERIC(18, 2)) AS percent_used,
				CAST(NULL AS INT) AS growth_times  
			FROM
				sys.master_files        A   WITH(NOLOCK)
				JOIN sys.databases      B   WITH(NOLOCK)    ON  A.database_id = B.database_id
				CROSS APPLY sys.dm_os_volume_stats(A.database_id, A.[file_id]) C
		------------------------------------------------------------------------------------------------------------------------------------------
			--
			UPDATE A
			SET
				A.free_space_GB = (
				(CASE 
					WHEN max_size_GB <= 0 THEN A.disk_free_size_GB
					WHEN max_real_size_GB > disk_free_size_GB THEN A.disk_free_size_GB 
					ELSE max_real_size_GB - size_GB
				END)),
				A.percent_used = (size_GB / (CASE WHEN max_real_size_GB > disk_total_size_GB THEN A.disk_total_size_GB ELSE max_real_size_GB END)) * 100
			FROM 
				@Monitor_Datafile_Size A    
			--
			UPDATE A
			SET
				A.growth_times = 
				(CASE 
					WHEN A.growth_MB <= 0 THEN 0 
					WHEN A.is_percent_growth = 0 THEN (A.max_real_size_GB - A.size_GB) / (A.growth_MB / 1024.0) 
					ELSE NULL 
				END)
			FROM 
				@Monitor_Datafile_Size A

		-----------------------------------------------------------------------------------------------------------------------------------  
		   DECLARE  @Monitoramento_Datafile_Size TABLE
			(
			IdEfeitoZebrado int identity(1,1),
			Databases nvarchar(40),
			Nome_Logico nvarchar(80),
			Tipo varchar(10),
			Tamanho_Arquivo_Gb numeric(18,2),
			Tamanho_Limite_Gb numeric(18,2),
			Qt_Livre_Limite_Gb numeric(18,2),
			Autogrowth_Mb numeric(18,2),
			Qt_Vezes_Autogrowth int,
			Limite_Usado_% numeric(18,2)
			)   

			INSERT INTO @Monitoramento_Datafile_Size 
			(Databases, Nome_Logico, Tipo, Tamanho_Arquivo_Gb, Tamanho_Limite_Gb,	Qt_Livre_Limite_Gb, Autogrowth_Mb, Qt_Vezes_Autogrowth, Limite_Usado_% )

			SELECT m.[database_name], m.[name], m.[type_desc], m.size_GB, m.max_real_size_GB, m.free_space_GB, m.growth_MB, m.growth_times, m.percent_used
			from @Monitor_Datafile_Size AS m    
			WHERE m.percent_used >= @Vl_Limite 
			and m.[database_name] <> 'coleta'	-- Tratado para quando houver uma base que n�o precisa monitorar

			IF ((SELECT COUNT(*) FROM @Monitoramento_Datafile_Size) > 0)
			BEGIN                       

				DECLARE          
					@Assunto VARCHAR(200) = @@SERVERNAME + ' - Monitoramento de Espa�o de limite Proposto nos Datafiles',
					@Destinatario VARCHAR(MAX) = 'suporte@cravil.com.br',
					@Mensagem VARCHAR(MAX)                  
     
				SET @Mensagem = '
				Prezado DBA,<br/>
				Foi identificado aumento consider�vel nos datafiles da inst�ncia ' 
				+ @@SERVICENAME + ' no servidor ' + @@SERVERNAME + ':<br>
				Obs.: O percentual � baseado em quantos porcento o tamanho do <br>
				arquivo de dados tem em rela��o ao limite proposto. Alerta configurado para 95%<br><br>

				<TABLE border=1 cellpadding=2 cellspacing=0 style=border-collapse: collapse;table-layout:fixed;width:1210;font-family:Arial;font-size:14px>															
													<tr height=20  style=height:20.0pt align = left>
														<td bgcolor=#0B0B61 width=120> <font color=white>Databases				</td>
														<td bgcolor=#0B0B61 width=100> <font color=white>Nome_Logico				</td>
														<td bgcolor=#0B0B61 width=50> <font color=white>Tipo						</td>
														<td bgcolor=#0B0B61 width=100> <font color=white>Tamanho_Arquivo_Gb		</td>
														<td bgcolor=#0B0B61 width=100> <font color=white>Tamanho_Limite_Gb		</td>
														<td bgcolor=#0B0B61 width=80> <font color=white>Limite_Livre_Gb			</td>
														<td bgcolor=#0B0B61 width=70> <font color=white>Autogrowth_Mb				</td>										
														<td bgcolor=#0B0B61 width=90> <font color=white>Qt_Autogrowth				</td>
														<td bgcolor=#0B0B61 width=70> <font color=white>Limite_Usado_%			</td>
													</tr>
												  '
			
							SELECT  @Mensagem = @Mensagem + 
								   CASE
									  WHEN CAST(ROW_NUMBER() OVER(ORDER BY m.Databases ASC) % 2 AS BIT) = 1 THEN '<tr height=20 style=height:15.0pt align = left>'
									  ELSE '<tr height=20 style=height:15.0pt; background: #E4E4E4; align = left>'
								   END +
								   '<td height=20 style=height:15.0pt>' + CAST(m.Databases				AS NVARCHAR(80))+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + m.Nome_Logico									+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + m.Tipo											+ '</td>' +
								   '<td height=20 style=height:15.0pt>' + CAST(m.Tamanho_Arquivo_Gb		AS VARCHAR(20))	+ '</td>' + 
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Tamanho_Limite_Gb		AS VARCHAR(20))	+ '</td>' +			
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Qt_Livre_Limite_Gb		AS VARCHAR(20))	+ '</td>' +			
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Autogrowth_Mb			AS VARCHAR(20))	+ '</td>' +		   
								   '<td height=20 style=height:15.0pt>' +	CAST(m.Qt_Vezes_Autogrowth		AS VARCHAR(20))	+ '</td>' +	
								   '<td height=20 style=height:15.0pt>' +	CAST(m.[Limite_Usado_%]			AS VARCHAR(20))	+ '</td>' +	
								   '</tr>'
							  FROM @Monitoramento_Datafile_Size as m			 					 

							SELECT @Mensagem = @Mensagem + 
							 '</table>'+'<br><br>'

				--------------------------------------------------------------------------------------------------------------------------------------
				--*** Envia o e-mail
				--------------------------------------------------------------------------------------------------------------------------------------
				EXEC msdb.dbo.sp_send_dbmail
					@profile_name = 'CRAVIL' ,	
					@recipients = @Destinatario ,			
					@subject = @Assunto,				
					@body = @Mensagem,						
					@body_format = 'HTML'
		   
			END -- fim do if
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_MonitoringSizeLimitDatafiles]:<b> <br>
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
GO



