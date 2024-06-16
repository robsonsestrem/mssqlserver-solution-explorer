USE Maintenance
GO

CREATE OR ALTER PROCEDURE Management.sp_VisionDependencies
WITH ENCRYPTION
AS
BEGIN
	  SET NOCOUNT ON 
	 
	  BEGIN TRY
		  DECLARE @ListaDatabases TABLE  
		  (
			  id int IDENTITY PRIMARY KEY,
			  NAME varchar(300)
		  ) 
		  INSERT INTO @ListaDatabases  ( NAME )
			 SELECT NAME
			 FROM master.sys.sysdatabases s
			 WHERE dbid NOT IN (1,2,3,4) 
			 AND DATABASEPROPERTYEX(NAME, 'Status') = 'ONLINE'
			 ORDER  BY 1 
		  DECLARE @dependeciasTodos TABLE  
		  (
		  DatabaseName sysname,
		  Referenced_Object_Type nvarchar(100),
		  Referenced_Entity_Name nvarchar(100),
		  Referenced_Id int,
		  Dependent_Objects_List nvarchar(max) 
		  )

		  DECLARE
			 @id int,
			 @cnt int,
			 @Comando nvarchar(max),
			 @NomeBanco varchar(300);
	  
		  SET @id = 1
		  SET @cnt = (SELECT MAX(id) FROM @ListaDatabases)
	  BEGIN TRANSACTION
		  WHILE (@id <= @cnt)
				BEGIN
				  SET @NomeBanco = (SELECT NAME FROM @ListaDatabases WHERE id = @id)
				  SET @Comando =
				  '
				  use '+@NomeBanco+'			  			  
				  SELECT
					DatabaseName = ''' + @NomeBanco + ''',
					o.type_desc AS referenced_object_type,
					d1.referenced_entity_name,
					d1.referenced_id,
					STUFF((
							SELECT
								'', '' + OBJECT_NAME(d2.referencing_id)
							FROM
								sys.sql_expression_dependencies d2
							WHERE
								d2.referenced_id = d1.referenced_id
							ORDER BY
								OBJECT_NAME(d2.referencing_id)
							FOR XML PATH('''')
						  ), 1, 1, '''') AS dependent_objects_list
				FROM
					sys.sql_expression_dependencies d1
					JOIN sys.objects o ON d1.referenced_id = o.[object_id]
				GROUP BY
					o.type_desc,
					d1.referenced_id,
					d1.referenced_entity_name
				ORDER BY
					o.type_desc,
					d1.referenced_entity_name
				  '
				  INSERT INTO @dependeciasTodos
				  EXEC (@Comando)
	    
				  SET @id = @id + 1;
				END
				SELECT * FROM @dependeciasTodos

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
				  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_VisionDependencies]:<b> <br>
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