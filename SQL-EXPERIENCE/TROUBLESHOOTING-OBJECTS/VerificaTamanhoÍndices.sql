--------------------------------------------------------------------------------------------------------
-- Mariana Serni Sampaio
--------------------------------------------------------------------------------------------------------
SELECT COUNT(*) AS Total_Pginas_Cache,
       COUNT(*)/128.0000 MB,
       Name AS Tabela, 
	   IndexName AS Nome_Indice,
       IndexTypeDesc AS Tipo_Indice
  FROM sys.dm_os_buffer_descriptors AS A
	INNER JOIN (SELECT AD.Name, AD.index_id, AD.allocation_unit_id, AD.OBJECT_ID,
				       IDX.Name IndexName, IDX.type_desc IndexTypeDesc
				  FROM (SELECT OBJECT_NAME(OBJECT_ID) AS Name,	
				               index_id, allocation_unit_id, OBJECT_ID
					      FROM sys.allocation_units AS AB
							INNER JOIN sys.partitions AS AC 
							        ON AC.hobt_id = AB.container_id
								   AND (AB.TYPE = 1 OR AB.TYPE = 3)
							UNION ALL
						SELECT OBJECT_NAME(OBJECT_ID) AS name,
   							   index_id, allocation_unit_id, OBJECT_ID
						  FROM sys.allocation_units AS AB
							INNER JOIN sys.partitions AS AC 
									ON AC.partition_id = AB.container_id
								   AND AB.TYPE = 2) AS AD
							 LEFT JOIN sys.indexes IDX 
									ON IDX.index_id = AD.index_id
								   AND IDX.OBJECT_ID = AD.OBJECT_ID) AS AE 
		ON AE.allocation_unit_id = A.allocation_unit_id 
WHERE database_id = DB_ID() 
  AND name NOT LIKE 'sys%' AND IndexName <> 'NULL'
GROUP BY name, index_id, IndexName, IndexTypeDesc
ORDER BY Total_Pginas_Cache DESC;