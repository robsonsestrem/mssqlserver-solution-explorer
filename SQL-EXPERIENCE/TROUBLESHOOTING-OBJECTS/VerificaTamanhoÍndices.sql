/*
	OBJETIVO: Consulta o buffer pool para estimar o tamanho em cache (páginas e MB)
			  de cada índice por tabela, cruzando sys.dm_os_buffer_descriptors
			  com sys.allocation_units e sys.indexes.
	PROJETO: mssqlserver-solution-explorer
	AUTOR:   Mariana Serni Sampaio
*/

-- Quantifica páginas em cache e tamanho em MB agrupando por índice e tabela
SELECT
	 COUNT(*)            AS Total_Pginas_Cache
	,COUNT(*) / 128.0000 AS MB
	,Name                AS Tabela
	,IndexName           AS Nome_Indice
	,IndexTypeDesc       AS Tipo_Indice
FROM sys.dm_os_buffer_descriptors AS A

-- Subquery AE: resolve cada unidade de alocação para nome da tabela e do índice
INNER JOIN (

	SELECT
		 AD.Name
		,AD.index_id
		,AD.allocation_unit_id
		,AD.OBJECT_ID
		,IDX.Name      AS IndexName
		,IDX.type_desc AS IndexTypeDesc

	-- Subquery AD: unifica unidades heap/in-row (TYPE 1 e 3) com LOB (TYPE 2)
	FROM (

		-- Unidades de alocação heap e in-row data (TYPE 1 e 3)
		SELECT
			 OBJECT_NAME(OBJECT_ID) AS Name
			,index_id
			,allocation_unit_id
			,OBJECT_ID
		FROM sys.allocation_units AS AB
		INNER JOIN sys.partitions AS AC
			ON  AC.hobt_id = AB.container_id
			AND (AB.TYPE = 1 OR AB.TYPE = 3)

		UNION ALL

		-- Unidades de alocação LOB data (TYPE 2)
		SELECT
			 OBJECT_NAME(OBJECT_ID) AS name
			,index_id
			,allocation_unit_id
			,OBJECT_ID
		FROM sys.allocation_units AS AB
		INNER JOIN sys.partitions AS AC
			ON  AC.partition_id = AB.container_id
			AND AB.TYPE = 2

	) AS AD

	-- Enriquece com nome e tipo do índice a partir de sys.indexes
	LEFT JOIN sys.indexes AS IDX
		ON  IDX.index_id  = AD.index_id
		AND IDX.OBJECT_ID = AD.OBJECT_ID

) AS AE
	ON AE.allocation_unit_id = A.allocation_unit_id

-- Restringe ao banco corrente e exclui objetos de sistema sem índice nomeado
WHERE database_id = DB_ID()
	AND name NOT LIKE 'sys%'
	AND IndexName <> 'NULL'
GROUP BY
	 name
	,index_id
	,IndexName
	,IndexTypeDesc
ORDER BY Total_Pginas_Cache DESC;