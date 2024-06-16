--É um script que irá armazenar diariamente o tamanho das tabelas de todas as bases de dados e, com isso, 
--você conseguirá monitorar o quanto suas tabelas e base estão crescendo por dia, por mês ou por ano.
--Essa informação é fundamental para você realizar um planejamento de espaço em disco do seu ambiente e 
--definir quando será necessário realizar um novo investimento na compra de mais disco.
--Para criar essa rotina, basta abrir o arquivo abaixo na base que deseja criar esse log e executar o script:
--O script vai criar as tabelas abaixo:
--BaseDados
--Tabela
--Servidor
--Historico_Tamanho_Tabela
--A view para facilitar a visualização das informações:

--vwTamanho_Tabela
--E a procedure que fará a carga dos dados nas Tabelas:

--stpCarga_Tamanhos_Tabelas
--Depois de executar o script, basta criar um job para executar a procedure stpCarga_Tamanhos_Tabelas diariamente.

/******************************************************************************************************************************/
USE Maintenance
GO

if object_id('Management.HistorySizeTables') is not null
	drop table Management.HistorySizeTables

if object_id('Management.InstanceDatabases') is not null
	drop table Management.InstanceDatabases

if object_id(' Management.InstanceTables') is not null
	drop table  Management.InstanceTables

if object_id('Management.InstanceServer') is not null
	drop table Management.InstanceServer
-------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Management.[InstanceTables](
	[IdTabela] [int] IDENTITY(1,1) NOT NULL,
	[NmTabela] [varchar](1000) NULL,
 CONSTRAINT [PK_Tabelas] PRIMARY KEY CLUSTERED 
(
	[IdTabela] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
-------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Management.[InstanceServer](
	[IdServidor] [smallint] IDENTITY(1,1) NOT NULL,
	[NmServidor] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Servidores] PRIMARY KEY CLUSTERED 
(
	[IdServidor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
-------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Management.[InstanceDatabases](
	[IdBaseDados] [int] IDENTITY(1,1) NOT NULL,
	[NmDatabase] [varchar](100) NULL,
 CONSTRAINT [PK_BaseDeDados] PRIMARY KEY CLUSTERED 
(
	[IdBaseDados] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
-------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Management.[HistorySizeTables](
	[IdHistoricoTamanho] [int] IDENTITY(1,1) NOT NULL,
	[IdServidor] [smallint] NULL,
	[IdBaseDados] [int] NULL,
	[IdTabela] [int] NULL,
	[NmDrive] [char](1) NULL,
	[NrTamanhoTotal] [numeric](9, 2) NULL,
	[NrTamanhoDados] [numeric](9, 2) NULL,
	[NrTamanhoIndice] [numeric](9, 2) NULL,
	[QtLinhas] [bigint] NULL,
	[DtReferencia] [date] NULL,
 CONSTRAINT [PK_Historico_Tamanho_Tabelas] PRIMARY KEY CLUSTERED 
(
	[IdHistoricoTamanho] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

ALTER TABLE Management.[HistorySizeTables]  WITH CHECK ADD  CONSTRAINT [FK_Id_BaseDado] FOREIGN KEY([IdBaseDados])
REFERENCES Management.[InstanceDatabases] ([IdBaseDados])
GO

ALTER TABLE Management.[HistorySizeTables] CHECK CONSTRAINT [FK_Id_BaseDado]
GO

ALTER TABLE Management.[HistorySizeTables]  WITH CHECK ADD  CONSTRAINT [FK_Id_Servidores] FOREIGN KEY([IdServidor])
REFERENCES Management.[InstanceServer] ([IdServidor])
GO

ALTER TABLE Management.[HistorySizeTables] CHECK CONSTRAINT [FK_Id_Servidores]
GO

ALTER TABLE Management.[HistorySizeTables]  WITH CHECK ADD  CONSTRAINT [FK_Id_Tabelas] FOREIGN KEY([IdTabela])
REFERENCES Management.[InstanceTables] ([IdTabela])
GO

ALTER TABLE Management.[HistorySizeTables] CHECK CONSTRAINT [FK_Id_Tabelas]
GO


/******************************************************************************************************************************/
USE Maintenance
GO

if object_id('Management.vw_SizeTables') is not null
	drop view Management.vw_SizeTables
GO

create view Management.vw_SizeTables
WITH ENCRYPTION
AS
select A.DtReferencia, B.NmServidor, C.NmDatabase,D.NmTabela ,A.NmDrive, A.NrTamanhoTotal, A.NrTamanhoDados,
	A.NrTamanhoIndice, A.QtLinhas
from Management.HistorySizeTables A
	join Management.InstanceServer B on A.IdServidor = B.IdServidor
	join Management.InstanceDatabases C on A.IdBaseDados = C.IdBaseDados
	join Management.InstanceTables D on A.IdTabela = D.IdTabela	
GO


/******************************************************************************************************************************/
USE Maintenance
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
																				-- tabela @databases, não faz nada.
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
			------------------------------ foi necessário trabalhar com collation neste script medonho ------------------------
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
		      , @recipients VARCHAR(100);		-- destinatário				
		SET @subject = 'Falha na execução de Procedure: '+@@SERVERNAME;
		SET @recipients = 'robson@cravil.com.br';
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


/******************************************************************************************************************************/

----------------------------------------------------------------------------------------------
-- Carga diária para saber qual tamanho atual (Mb)
----------------------------------------------------------------------------------------------
EXECUTE Management.sp_LoadSizeTables


----------------------------------------------------------------------------------------------
-- Visualização diária com a View
----------------------------------------------------------------------------------------------

SELECT top 30 v.DtReferencia,
			  v.NmDatabase,
			  v.NmDrive,
			  v.NmServidor,
			  v.NmTabela,
			  (cast(v.NrTamanhoDados as varchar)+ ' Mb') + ' -> ' + (cast((v.NrTamanhoDados / 1024) as varchar)+ ' Gb') as TotalDados,			  
			  v.NrTamanhoIndice,
			  v.NrTamanhoTotal,
			  v.QtLinhas

FROM Management.vw_SizeTables as v
ORDER BY NrTamanhoTotal desc


--Outra forma de tratar a collation
/*
SELECT ID
FROM ItemsTable
INNER JOIN AccountsTable
WHERE ItemsTable.Collation1Col COLLATE DATABASE_DEFAULT
= AccountsTable.Collation2Col COLLATE DATABASE_DEFAULT
*/