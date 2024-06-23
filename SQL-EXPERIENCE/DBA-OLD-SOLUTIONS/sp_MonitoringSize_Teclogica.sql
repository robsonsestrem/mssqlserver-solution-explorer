-------------------------------------------------------------------------------------------------------------------------------------------
-- Busca dados de utilização do initial file dos datafiles em relação ao limite proposto
-------------------------------------------------------------------------------------------------------------------------------------------
;with datafiles
as
(
	SELECT
	B.database_id AS database_id,
	B.[name] AS [database_name],
	A.state_desc,
	A.[type_desc],
	A.[file_id],
	A.[name] as file_name_logic,
	A.physical_name as file_name_physical,
						
	CAST(A.size / 128 AS NUMERIC(18, 2)) AS size_MB,
	CAST(A.max_size / 128 AS NUMERIC(18, 2)) AS max_size_MB,
	-- caso tenha tamanho de arquivo maior que o disco, ou limite não definido, etc...
	CAST(
		(CASE
			WHEN A.growth <= 0 THEN A.size / 128
			WHEN A.max_size <= 0 THEN C.total_bytes / 1048576.0 --1073741824.0
			WHEN A.max_size / 128 / 1024.0 > C.total_bytes / 1048576.0 THEN C.total_bytes / 1048576.0
				ELSE A.max_size / 128
				END) AS NUMERIC(18, 2)) AS max_real_size_MB																			
	FROM
	sys.master_files        A   WITH(NOLOCK)
	JOIN sys.databases      B   WITH(NOLOCK)    ON  A.database_id = B.database_id
	CROSS APPLY sys.dm_os_volume_stats(A.database_id, A.[file_id]) C
)
select *
-- percentual de utilização do limite proposto nos datafiles, ou seja, tamanho reservado em relação ao limite
, cast((t2.size_MB / t2.max_real_size_MB) * 100 as NUMERIC(18,2)) as Percentual
from datafiles as t2
-- filtrar para os arquivos mdf/ndf ou somente para os arquivos ldf (logs)
where t2.type_desc = 'ROWS'	-- LOG


-------------------------------------------------------------------------------------------------------------------------------------------
-- Busca percentual livre nos arquivos de logs
-------------------------------------------------------------------------------------------------------------------------------------------
if(OBJECT_ID('tempdb..##tempPercFreeFile') is not null) 
drop table ##tempPercFreeFile

create table ##tempPercFreeFile(
			DatabaseName sysname, 
			LogicalName sysname, 
			PhysicalName nvarchar(100), 
			Size_Mb decimal(18 , 2),					
			SpaceFree_Mb decimal(18 , 2), 
			PercFreeFile decimal(18 , 2), 
			[Type_desc] varchar(20)
			);   
			EXEC sp_msforeachdb '
			Use [?];
			insert into ##tempPercFreeFile(DatabaseName , 
							   LogicalName , 
							   physicalName , 
							   size_Mb ,							  				  
							   SpaceFree_Mb , 
							   PercFreeFile , 
							   [Type_desc])
			   select DB_NAME() AS DatabaseName , 
				   Name , 
				   physical_name , 
				   CAST(CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2) AS decimal(18 , 2)) AS nvarchar) as Size_MB , 	   	          
				   --
				   CAST(CAST(ROUND(CAST(size AS decimal) * 8.0 / 1024.0 , 2) AS decimal(18 , 2)) - 
				   CAST(FILEPROPERTY(name , ''SpaceUsed'') * 8.0 / 1024.0 AS decimal(18 , 2)) AS nvarchar) AS SpaceFree_MB ,
				   --
				   cast(round(
				   (CAST(size * 8.0 / 1024.0 AS decimal(18 , 2)) -  
				    CAST(FILEPROPERTY(name , ''SpaceUsed'') * 8.0 / 1024.0  AS decimal(18 , 2))
				   ) * 100 / 
				   CAST(size * 8.0 / 1024.0 AS decimal(18 , 2))
				   , 2) as decimal(18,2)) AS PercFreeFile ,
				   [type_desc]				 				   				   
				from sys.database_files
				where [type_desc] = ''LOG'''

select * from ##tempPercFreeFile





