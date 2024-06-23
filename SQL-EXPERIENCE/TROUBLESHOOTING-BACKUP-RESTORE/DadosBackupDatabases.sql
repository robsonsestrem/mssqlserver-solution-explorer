			DECLARE @bkp table
			(
			status			varchar(60),
			banco			varchar(60),
			tipoBkp			varchar(60),
			dataInicio		varchar(60),
			dataFinal		varchar(60),
			type			varchar(60),
			backup_finish_date varchar(60),
			recovery_model varchar(60)
			)

			;WITH cte_BackupSets
					 AS (
						 SELECT MAX(isnull([A].[backup_set_id],'')) AS [backup_set_id],
								isnull([A].[type],'') AS [type],
								isnull(UPPER(CONVERT( VARCHAR(100), [B].[name])) ,'') AS [database_name],
								MAX(isnull([A].[backup_start_date],'')) AS [backup_start_date],
								MAX(isnull([A].[backup_finish_date],'')) AS [backup_finish_date],
								isnull(b.recovery_model_desc, '') AS recovery_model
						   FROM [master].[sys].[databases] AS [B]
								LEFT JOIN [msdb].[dbo].[backupset] AS [A] ON [A].[database_name] = [B].[name]
																			 AND [A].[type] IN('D', 'I')
						  GROUP BY [B].[name],
								   [A].[type],
									b.recovery_model_desc

						 UNION

						 SELECT MAX(isnull([A].[backup_set_id],'')) AS [backup_set_id],
								isnull([A].[type],'') AS [type],
								isnull(UPPER(CONVERT( VARCHAR(100), [B].[name])),'') AS [database_name],
								MAX(isnull([A].[backup_start_date],'')) AS [backup_start_date],
								MAX(isnull([A].[backup_finish_date],'')) AS [backup_finish_date],
								isnull(B.recovery_model_desc, '') AS recovery_model
						   FROM [master].[sys].[databases] AS [B]
								LEFT JOIN [msdb].[dbo].[backupset] AS [A] ON [A].[database_name] = [B].[name]
																			 AND [A].[type] IN('L')
						  GROUP BY [B].[name],
								   [A].[type],
									B.recovery_model_desc),
					 cte_BackupFull
					 AS (SELECT MAX(isnull([backup_set_id],'')) AS [backup_set_id],
								isnull([type],'') AS [type],
								isnull([database_name],'') AS [database_name],
								MAX(isnull([backup_start_date],'')) AS [backup_start_date],
								MAX(isnull([backup_finish_date],'')) AS [backup_finish_date],
								recovery_model
						   FROM [cte_BackupSets]
						  GROUP BY [database_name],
								   [type],
								   recovery_model	)

				INSERT INTO @bkp
					 SELECT					
							IsNull(Cast(CASE
								WHEN [A].[type] = 'D' AND CAST(DATEDIFF(day, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name NOT LIKE '%homolog%' THEN 'WARNING'
								WHEN [A].[type] = 'D' AND CAST(DATEDIFF(day, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name LIKE '%homolog%'	  THEN 'DESNECESSÁRIO'
								--
								WHEN ([A].[type] = 'I') 
								AND 
								(	
									(DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) >= 2 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) <> 6) 
									 OR (DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) > 3 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) = 6)	
								) AND A.database_name NOT LIKE '%homolog%' 
								THEN 'WARNING'
								--
								WHEN ([A].[type] = 'I') 
								AND 
								(	
									(DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) >= 2 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) <> 6) 
									 OR (DATEDIFF(DAY,ISNULL([A].[backup_finish_date],''), GETDATE()) > 3 and datepart(WEEKDAY,ISNULL([A].[backup_finish_date],'')) = 6)	
								) AND A.database_name LIKE '%homolog%' 
								THEN 'DESNECESSÁRIO'
								--						
								WHEN [A].[type] = 'L' AND CAST(DATEDIFF(hour, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 and A.database_name LIKE '%homolog%' THEN 'DESNECESSÁRIO'
								WHEN [A].[type] = 'L' AND CAST(DATEDIFF(hour, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name NOT LIKE '%homolog%' 
													  and A.recovery_model <> 'SIMPLE' THEN 'WARNING'
								WHEN [A].[type] = 'L' AND CAST(DATEDIFF(hour, isnull([A].[backup_finish_date],''), GETDATE()) AS VARCHAR(10)) > 1 AND A.database_name NOT LIKE '%homolog%' 
													  and A.recovery_model = 'SIMPLE' THEN 'DESNECESSÁRIO'
								--
								WHEN ([A].[type] IS NULL OR A.type = '') AND A.recovery_model = 'SIMPLE' THEN 'DESNECESSÁRIO'
								WHEN ([A].[type] IS NULL OR A.type = '') AND A.recovery_model <> 'SIMPLE' AND A.database_name LIKE '%homolog%' THEN 'DESNECESSÁRIO'
								WHEN ([A].[type] IS NULL OR A.type = '') AND A.recovery_model <> 'SIMPLE' AND A.database_name NOT LIKE '%homolog%' THEN 'WARNING'
								ELSE 'Ok'
							END as varchar(max)), '')	as Status,																											
							--
							UPPER(cast(isnull([A].[database_name],'') as varchar(100))) AS Banco,
							--
							IsNull(Cast(CASE [A].[type]
								WHEN 'D' THEN 'Full'
								WHEN 'I' THEN 'Differential'
								WHEN 'L' THEN 'Log'
								WHEN 'F' THEN 'File or Filegroup'
								WHEN 'G' THEN 'File Differential'
								WHEN 'P' THEN 'Partial'
								WHEN 'Q' THEN 'Partial Differential'
								ELSE 'Sem Backup'
							END as varchar(max)), '')	as TipoBkp,																												
							--																																	
							IsNull(Cast(ISNULL(CONVERT( VARCHAR(50), [A].[backup_start_date]), '') as varchar(max)), '')	as dataInicio,	
							IsNull(Cast(ISNULL(CONVERT( VARCHAR(50), [A].[backup_finish_date]), '') as varchar(max)), '')	as dataFinal,
							isnull(A.type,'')  AS type,
							isnull(A.backup_finish_date,'') AS backup_finish_date,
							recovery_model
			   
					   FROM [cte_BackupFull] AS [A]
					   where A.database_name not in ('master', 'tempdb', 'model', 'msdb')

					  ORDER BY [A].[database_name],
							   [type];



SELECT * FROM @bkp

