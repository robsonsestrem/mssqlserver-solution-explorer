USE Maintenance
GO
CREATE OR ALTER PROCEDURE Management.sp_LoadFragmentationIndexDefault
WITH ENCRYPTION
AS  
  SET NOCOUNT ON
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
 
	  CREATE TABLE #ListaDatabases
	  (
		  id int IDENTITY PRIMARY KEY,
		  NAME varchar(300)
	  )
 
	  INSERT INTO #ListaDatabases  ( NAME )
		 SELECT NAME
		 FROM master.sys.sysdatabases s
		 WHERE dbid IN (5, 7, 9, 11, 12, 14, 16, 18) -- bases de produção menos o gescooper que é 6 no server novo
		 AND DATABASEPROPERTYEX(NAME, 'Status') = 'ONLINE'
		 ORDER  BY 1 
 
	  DECLARE
		 @id int,
		 @cnt int,
		 @Comando nvarchar(max),
		 @NomeBanco varchar(300);
	  
	  SET @id = 1
	  SET @cnt = (SELECT MAX(id) FROM #ListaDatabases)

	  -- VALIDAÇÃO PARA NÃO FAZER MAIS DE UMA INSERÇÃO DIÁRIA
	  SELECT COUNT(*) FROM Maintenance.Management.HistoryIndexFragmentation as h
	  WHERE h.DateReference >= cast(floor(cast(GETDATE() as float)) as datetime)
	  and h.DatabaseName <> 'gescooper90'
	  IF(@@ROWCOUNT > 0)
		BEGIN 
			delete from Maintenance.Management.HistoryIndexFragmentation
			where DateReference >= cast(floor(cast(GETDATE() as float)) as datetime)
			and DatabaseName <> 'gescooper90'
		END
	  --
	  BEGIN TRY
		BEGIN TRANSACTION

		  WHILE @id <= @cnt
			BEGIN
			  SET @NomeBanco = (SELECT NAME FROM #ListaDatabases WHERE id = @id)
          
			  SET @Comando =
				'SELECT
				   GETDATE()
				  ,InstanceName = ''' + @@SERVERNAME + '''
				  ,db_id('''+@NomeBanco+''')
				  ,DatabaseName = ''' + @NomeBanco + '''
				  , sc.name as NameSchema
				  , t.name  as NameTable
				  , a.index_id
				  , i.name  as NameIndex			
				  , a.index_type_desc
				  , i.fill_factor
				  ,ROUND(a.avg_fragmentation_in_percent,2) as Fragmentation
				  ,ROUND(a.avg_page_space_used_in_percent,2)
				  ,a.index_level
				  ,a.index_depth
				  ,a.alloc_unit_type_desc
				  ,a.page_count
				  ,a.record_count
				  ,a.fragment_count	
				  ,t.is_ms_shipped
				  ,[Usage] = (s.user_seeks + s.user_scans + s.user_lookups)
				  ,s.user_seeks
				  ,s.user_scans
				  ,s.user_lookups
				  ,i.is_primary_key
				  FROM
					[' + @NomeBanco + '].sys.dm_db_index_usage_stats s
					INNER JOIN [' + @NomeBanco + '].sys.indexes i
							ON s.[object_id] = i.[object_id]
						   AND s.index_id = i.index_id
					INNER JOIN [' + @NomeBanco + '].sys.dm_db_index_physical_stats( DB_ID(''' + @NomeBanco + '''), null, null, null, ''detailed'' ) a
							ON s.[object_id] = a.[object_id]
						   AND s.index_id = a.index_id
					INNER JOIN [' + @NomeBanco + '].sys.tables t
							ON i.object_id = t.object_id
					INNER JOIN [' + @NomeBanco + '].sys.schemas sc
							ON t.schema_id = sc.schema_id
				WHERE
				  i.name IS NOT NULL -- HEAP INDEX 
				  and s.database_id = DB_ID(''' + @NomeBanco + ''')
				  and a.database_id = DB_ID(''' + @NomeBanco + ''') 
				ORDER BY
				  t.name, a.index_id'
 
			  INSERT INTO Management.HistoryIndexFragmentation
			  (
			    DateReference
				, ServerName
				, DatabaseId
				, DatabaseName
				, SchemaName
				, TableName
				, IndexId_id
				, IndexName
				, IndexTypeDesc
				, [FillFactor]
				, AvgFragmentationInPercent
				, AvgPageSpaceUsedInPercent
				, IndexLevel
				, IndexDepth
				, AllocUnitTypeDesc
				, [PageCount]
				, RecordCount
				, FragmentCount
				, IsMsShipped
				, IndexUsage
				, IndexUserSeeks
				, IndexUserScans
				, IndexUserLookups
				, IsPrimaryKey
			  )
			  EXEC (@Comando)
	    
			  SET @id = @id + 1;
			END -- fim while
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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_LoadFragmentationIndexDefault]:<b> <br>
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

  DROP TABLE #ListaDatabases  
  SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
  SET NOCOUNT OFF
  
GO



