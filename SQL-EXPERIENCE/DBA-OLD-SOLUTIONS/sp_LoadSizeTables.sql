USE YOUR_DATABASE
GO

if object_id('Management.sp_LoadTableSize') is not null
	drop procedure Management.sp_LoadSizeTables
GO

CREATE OR ALTER PROCEDURE Management.sp_LoadSizeTables
WITH ENCRYPTION
AS
BEGIN	
	SET NOCOUNT ON
	declare @Databases table(Id_Database int identity(1,1), Nm_Database varchar(120))
	declare @Total int, @i int, @Database varchar(120), @cmd varchar(8000);

	BEGIN TRY
		BEGIN TRANSACTION
			insert into @Databases(Nm_Database)
			select name
			from sys.databases
			where name not in ('master','model','tempdb', 'msdb')
			and name not like '%homolog%' 
			and state_desc = 'online'	
						
			select @Total = max(Id_Database)
			from @Databases

			set @i = 1

			if object_id('tempdb..##Tamanho_Tabelas') is not null 
						drop table ##Tamanho_Tabelas
				
			CREATE TABLE ##Tamanho_Tabelas(
				Nm_Servidor VARCHAR(256),
				Nm_Database varchar(256),
				[Nm_Schema] [varchar](8000) NULL,
				[Nm_Tabela] [varchar](8000) NULL,
				[Nm_Index] [varchar](8000) NULL,
				Nm_Drive CHAR(1),
				[Used_in_kb] [int] NULL,
				[Reserved_in_kb] [int] NULL,
				[Tbl_Rows] [bigint] NULL,
				[Type_Desc] [varchar](20) NULL
			) ON [PRIMARY]

			while (@i <= @Total)
			begin

				IF EXISTS (SELECT NULL from @Databases  where Id_Database = @i) -- caso a database foi deletada da 
																				-- tabela @databases, n�o faz nada.
				BEGIN 
		
					select @Database = Nm_Database
					from @Databases
					where Id_Database = @i
			
					set @cmd = '
						insert into ##Tamanho_Tabelas
						select @@SERVERNAME 
							, '''+@Database + ''' Nm_Database, t.schema_name, t.table_Name, t.Index_name,
							(SELECT SUBSTRING(filename,1,1) 
							FROM [' + @Database + '].sys.sysfiles 
							WHERE fileid = 1),
						sum(t.used) as used_in_kb,
						sum(t.reserved) as Reserved_in_kb,
						--case grouping (t.Index_name) when 0 then sum(t.ind_rows) else sum(t.tbl_rows) end as rows,
						 max(t.tbl_rows)  as rows,
						type_Desc
						from (
							select s.name as schema_name, 
									o.name as table_Name,
									coalesce(i.name,''heap'') as Index_name,
									p.used_page_Count*8 as used,
									p.reserved_page_count*8 as reserved, 
									p.row_count as ind_rows,
									(case when i.index_id in (0,1) then p.row_count else 0 end) as tbl_rows, 
									i.type_Desc as type_Desc
							from 
								[' + @Database + '].sys.dm_db_partition_stats p
								join [' + @Database + '].sys.objects o on o.object_id = p.object_id
								join [' + @Database + '].sys.schemas s on s.schema_id = o.schema_id
								left join [' + @Database + '].sys.indexes i on i.object_id = p.object_id and i.index_id = p.index_id
							where o.type_desc = ''user_Table'' and o.is_Ms_shipped = 0
						) as t
						group by t.schema_name, t.table_Name,t.Index_name,type_Desc
						--with rollup -- no sql server 2005, essa linha deve ser habilitada **********************************************
						--order by grouping(t.schema_name),t.schema_name,grouping(t.table_Name),t.table_Name,	grouping(t.Index_name),t.Index_name
						'

					EXEC(@cmd);
					/*print @cmd; -- para debbug
					print '
						##################################################################################
					'; -- para debbug*/
				END
		
				set @i = @i + 1
			end 
			------------------------------ foi necess�rio trabalhar com collation neste script medonho ------------------------
			INSERT INTO Management.InstanceServer(NmServidor)
			SELECT DISTINCT A.Nm_Servidor 
			FROM ##Tamanho_Tabelas A				
				LEFT JOIN Management.InstanceServer B ON A.Nm_Servidor = B.NmServidor collate Latin1_General_CI_AS
			WHERE B.NmServidor IS null
		
			INSERT INTO Management.InstanceDatabases(NmDatabase)
			SELECT DISTINCT A.Nm_Database 
			FROM ##Tamanho_Tabelas A
				LEFT JOIN Management.InstanceDatabases B ON A.Nm_Database = B.NmDatabase collate Latin1_General_CI_AS
			WHERE B.NmDatabase IS null
	
			INSERT INTO Management.InstanceTables(NmTabela)
			SELECT DISTINCT A.Nm_Tabela 
			FROM ##Tamanho_Tabelas A
				LEFT JOIN Management.InstanceTables B ON A.Nm_Tabela = B.NmTabela collate Latin1_General_CI_AS
			WHERE B.NmTabela IS null	

			insert into Management.HistorySizeTables(IdServidor,IdBaseDados,IdTabela,NmDrive,NrTamanhoTotal,
						NrTamanhoDados,NrTamanhoIndice,QtLinhas,DtReferencia)
			select B.IdServidor, D.IdBaseDados, C.IdTabela ,UPPER(A.Nm_Drive),
					sum(Reserved_in_kb)/1024.00 [Reservado (KB)], 
					sum(case when Type_Desc in ('CLUSTERED','HEAP') then Reserved_in_kb else 0 end)/1024.00 [Dados (KB)], 
					sum(case when Type_Desc in ('NONCLUSTERED') then Reserved_in_kb else 0 end)/1024.00 [Indices (KB)],
					max(Tbl_Rows) Qtd_Linhas,
					CONVERT(VARCHAR, GETDATE() ,112)
						 
			from ##Tamanho_Tabelas A
				JOIN Management.InstanceServer B ON A.Nm_Servidor = B.NmServidor		collate Latin1_General_CI_AS
				JOIN Management.InstanceTables C ON A.Nm_Tabela = C.NmTabela			collate Latin1_General_CI_AS
				JOIN Management.InstanceDatabases D ON A.Nm_Database = D.NmDatabase		collate Latin1_General_CI_AS
					LEFT JOIN Management.HistorySizeTables E ON B.IdServidor = E.IdServidor 
										AND D.IdBaseDados = E.IdBaseDados AND C.IdTabela = E.IdTabela 
										AND E.DtReferencia = CONVERT(VARCHAR, GETDATE() ,112)    
			where Nm_Index is not null	and Type_Desc is not NULL
				AND E.IdHistoricoTamanho IS NULL 
			group by B.IdServidor, D.IdBaseDados, C.IdTabela,UPPER(A.Nm_Drive), E.DtReferencia

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
			  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_LoadSizeTables]:<b> <br>
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
