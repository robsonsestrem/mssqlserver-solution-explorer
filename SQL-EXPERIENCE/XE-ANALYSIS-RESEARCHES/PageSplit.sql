-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Referências
-- Vitor Fava
-----------------------------------------------------------------------------------------------------------------------------------------------------
--Infos do evento transaction_log
SELECT
oc.name,
oc.type_name,
oc.description
FROM
sys.dm_xe_packages AS p
INNER JOIN
sys.dm_xe_objects AS o
ON
p.guid = o.package_guid
INNER JOIN
sys.dm_xe_object_columns AS oc
ON
oc.object_name = o.name
AND
oc.object_package_guid = o.package_guid
WHERE
o.name = 'transaction_log'
AND
oc.column_type = 'data';
 
--Definindo o valor do filtro
SELECT
*
FROM
sys.dm_xe_map_values
WHERE
name = 'log_op'
AND
map_value = 'LOP_DELETE_SPLIT';


-----------------------------------------------------------------------------------------------------------------------------------------------------
--Criando sessão de monitoração
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT SESSION [XE_MONITOR_PAGE_SPLIT]
ON    SERVER
ADD EVENT sqlserver.transaction_log(
WHERE operation = 11
)
ADD TARGET package0.histogram(
SET filtering_event_name =
'sqlserver.transaction_log',
source_type = 0,
source = 'alloc_unit_id');
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Simulação
-- Criacao da tabela TBTeste
CREATE TABLE TBTeste
( Codigo UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID() PRIMARY KEY,
Valor INT NOT NULL DEFAULT (RAND()*1000),
DataAlteracao DATETIME2 NOT NULL DEFAULT CURRENT_TIMESTAMP);
GO
 
--Gerando um mid-split
CREATE INDEX IDX_01 ON TBTeste (Valor);
GO
--Gerando um end-split
CREATE INDEX IDX_02 ON TBTeste (DataAlteracao);
GO
 
--Inserindo valores na tabela TBTeste
WHILE 1=1
BEGIN
INSERT INTO dbo.TBTeste DEFAULT VALUES;
WAITFOR DELAY '00:00:00.005';
END
GO


-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Selecionando o objeto com maior número de page splits
-----------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
o.name AS table_name,
i.name AS index_name,
tab.split_count,
i.fill_factor
FROM (    SELECT
n.value('(value)[1]', 'bigint') AS alloc_unit_id,
n.value('(@count)[1]', 'bigint') AS split_count
FROM
(SELECT CAST(target_data as XML) target_data
FROM sys.dm_xe_sessions AS s
JOIN sys.dm_xe_session_targets t
ON s.address = t.event_session_address
WHERE s.name = 'XE_MONITOR_PAGE_SPLIT'
AND t.target_name = 'histogram' ) as tab
CROSS APPLY target_data.nodes('HistogramTarget/Slot') as q(n)
) AS tab
JOIN sys.allocation_units AS au
ON tab.alloc_unit_id = au.allocation_unit_id
JOIN sys.partitions AS p
ON au.container_id = p.partition_id
JOIN sys.indexes AS i
ON p.object_id = i.object_id
AND p.index_id = i.index_id
JOIN sys.objects AS o
ON p.object_id = o.object_id
WHERE o.is_ms_shipped = 0;