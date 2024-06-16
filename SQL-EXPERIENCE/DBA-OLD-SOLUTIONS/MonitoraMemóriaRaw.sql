-- Referência -> Tiago Bonamigo
---------------------------------------------------------------------------------------------------------------
--	Então vamos entender os registros abaixo. O que acontece é que o SQL Server faz uso de
-- memória para o Buffer Pool, que é onde ele mantém uma cópia em memória de dados
-- acessados a partir de consultas feitas anteriormente para que ele não precise acessar o
-- disco/storage caso a consulta seja feita novamente. A consulta abaixo mostra quão grande é
-- o Buffer Pool para cada banco de dados.
--	Pages são as unidades de armazenamento de dados do SQL Server, e por padrão tem 8
-- KBytes. O resultado da coluna Page Reads, que pode ser Dirty ou Clean, diferencia o status
-- dos pages. Existem os que contém dados que estão alinhados com o banco de dados (clean)
-- e os que já foram modificados em memória mas ainda não em disco (dirty). Multiplicando o
-- número de pages por 8Kb e dividindo por 1024 temos o número de MBs alocados por banco.
---------------------------------------------------------------------------------------------------------------
SELECT
	CASE WHEN ([is_modified] = 1) 
		THEN 'Dirty-Está em memória, mas não em Disco' 
	ELSE 'Clean-Está na memória e no disco' END
																					AS	'Status_Páginas_Dados',
	--
	CASE WHEN ([database_id] = 32767) 
		THEN 'mssqlsystemresource' 
	ELSE DB_NAME (database_id) END													AS 'Nome_Database',
	--
	COUNT (b.page_id)																AS 'Total_Páginas',
	--
	CAST(CAST(COUNT(b.page_id) * 8 AS DECIMAL(18,2)) /1024 	AS DECIMAL(18,2))		AS 'MBs_Usados',
	--
    CAST(CAST(COUNT(b.page_id) * 8 AS DECIMAL(18,2)) /1024 /1024 AS DECIMAL(18,2))	AS 'Gbs_Usados'

FROM sys.dm_os_buffer_descriptors as b
GROUP BY [database_id], [is_modified]
ORDER BY [database_id], [is_modified]


---------------------------------------------------------------------------------------------------------------
-- https://www.sqlskills.com/blogs/jonathan/wow-an-online-calculator-to-misconfigure-your-sql-server-memory/
-- Jonathan Kehayias
---------------------------------------------------------------------------------------------------------------
SELECT  
    EventTime, 
    record.value('(/Record/ResourceMonitor/Notification)[1]', 'varchar(max)') as [Type], 
    record.value('(/Record/MemoryRecord/AvailablePhysicalMemory)[1]', 'bigint') AS [Avail Phys Mem, Kb], 
    record.value('(/Record/MemoryRecord/AvailableVirtualAddressSpace)[1]', 'bigint') AS [Avail VAS, Kb] 
FROM ( 
    SELECT 
        DATEADD (ss, (-1 * ((cpu_ticks / CONVERT (float, ( cpu_ticks / ms_ticks ))) - [timestamp])/1000), GETDATE()) AS EventTime, 
        CONVERT (xml, record) AS record 
    FROM sys.dm_os_ring_buffers 
    CROSS JOIN sys.dm_os_sys_info 
    WHERE ring_buffer_type = 'RING_BUFFER_RESOURCE_MONITOR') AS tab 
ORDER BY EventTime DESC