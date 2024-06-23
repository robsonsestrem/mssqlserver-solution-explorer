----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Obtain live session statistics   
-- https://technet.microsoft.com/en-us/library/dd822788(v=sql.100).aspx
----------------------------------------------------------------------------------------------------------------------------------------------------------
select * from sys.server_event_sessions			-- Lista todas as definições de sessão de evento.
select * from sys.server_event_session_actions	-- Retorna uma linha para cada ação em cada evento de uma sessão de eventos.
select * from sys.server_event_session_events	-- Retorna uma linha para cada evento em uma sessão de evento.
select * from sys.server_event_session_fields	-- Retorna uma linha para cada evento de destino em uma sessão de evento.  

select * from sys.dm_os_dispatcher_pools		--Retorna informações sobre pools de distribuidor de sessão.
select * from sys.dm_xe_objects					--Retorna uma linha para cada objeto exposto por um pacote de evento.
select * from sys.dm_xe_object_columns			--Retorna as informações de esquema de todos os objetos.
select * from sys.dm_xe_packages				--Lista todos os pacotes registrados com o mecanismo de eventos estendido.
select * from sys.dm_xe_sessions				--Retorna informações sobre uma sessão de eventos estendida ativa.
select * from sys.dm_xe_session_targets			--Retorna informações sobre os destinos de sessão.
select * from sys.dm_xe_session_events			--Retorna informações sobre os eventos da sessão.
select * from sys.dm_xe_session_event_actions	--Retorna informações sobre ações da sessão de evento.
select * from sys.dm_xe_map_values				--Fornece um mapeamento de chaves numéricas internas para texto legível.
select * from sys.dm_xe_session_object_columns	--Exibe os valores de configuração para objetos que são associados a uma sessão.


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Como parar ou dropar uma XE
----------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER EVENT SESSION NOME_XE  
ON SERVER  
STATE = start;  -- ou stop
GO

DROP EVENT SESSION NOME_XE  
ON SERVER  


-- filtro para identificar tipos de waits
SELECT xmv.map_key, xmv.map_value
FROM sys.dm_xe_map_values xmv
JOIN sys.dm_xe_packages xp
    ON xmv.object_package_guid = xp.guid
WHERE xmv.name = 'wait_types'
    AND xp.name = 'sqlos'
	and xmv.map_value = 'cxpacket'	-- pegando um tipo específico, código 191
GO


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- A seguinte consulta retorna todos os eventos disponíveis:
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS package, c.event, k.keyword, c.channel, c.description
FROM
(
SELECT event_package=o.package_guid, o.description,
       event=c.object_name, channel=v.map_value
FROM sys.dm_xe_objects o
       LEFT JOIN sys.dm_xe_object_columns c ON o.name = c.object_name
       INNER JOIN sys.dm_xe_map_values v ON c.type_name = v.name
              AND c.column_value = cast(v.map_key AS nvarchar)
WHERE object_type='event' AND (c.name = 'channel' OR c.name IS NULL)
) c left join
(
       SELECT event_package=c.object_package_guid, event=c.object_name,
              keyword=v.map_value
       FROM sys.dm_xe_object_columns c INNER JOIN sys.dm_xe_map_values v
       ON c.type_name = v.name AND c.column_value = v.map_key
              AND c.type_package_guid = v.object_package_guid
       INNER JOIN sys.dm_xe_objects o ON o.name = c.object_name
              AND o.package_guid=c.object_package_guid
       WHERE object_type='event' AND c.name = 'keyword'
) k
ON
k.event_package = c.event_package AND (k.event = c.event OR k.event IS NULL)
INNER JOIN sys.dm_xe_packages p ON p.guid=c.event_package
WHERE (p.capabilities IS NULL OR p.capabilities & 1 = 0)
ORDER BY channel, keyword, event


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- O segundo tipo de coluna é a coluna de dados, que define a carga útil padrão ou o conjunto de colunas que é coletado quando o evento dispara. 
-- Essas colunas são incluídas automaticamente nos detalhes do evento quando são enviadas para os objetivos da sessão.
-- é o que vai na clásula where depois de action
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS PackageName,
              o.name AS EventName,
              c.column_id,
              c.column_type,
              c.name ColumnName
FROM sys.dm_xe_objects o
       INNER JOIN sys.dm_xe_packages p
              ON o.package_guid = p.guid
       INNER JOIN sys.dm_xe_object_columns c
              ON o.name = c.object_name
WHERE o.object_type = 'event'
  AND c.column_type = 'data'
  AND (p.capabilities IS NULL OR p.capabilities <> 1)
  and o.name like 'wait_info'
ORDER BY PackageName, EventName, column_type, column_id;


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Além das colunas do descritor e da carga útil padrão, alguns eventos também possuem um terceiro tipo de coluna, 
-- chamado uma coluna customizável que funciona de forma semelhante a um predicado leve no evento. 
-- Essas colunas são coletadas de forma semelhante a ações na sessão de eventos e têm uma despesa adicional para a coleta de dados. 
-- Como o custo para coletar esses dados pode afetar o desempenho, ele é coletado somente quando especificado explicitamente 
-- como parte da definição do evento na sessão. A seguinte consulta retorna os parâmetros personalizáveis ??para eventos:
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS PackageName,
              o.name AS EventName,
              c.column_id,
              c.column_type,
              c.name ColumnName
FROM sys.dm_xe_objects o
       INNER JOIN sys.dm_xe_packages p
              ON o.package_guid = p.guid
       INNER JOIN sys.dm_xe_object_columns c
              ON o.name = c.object_name
WHERE o.object_type = 'event'
  --AND c.column_type = 'customizable'
  AND (p.capabilities IS NULL OR p.capabilities <> 1)
  and o.name like 'error_reported'
ORDER BY PackageName, EventName, column_type, column_id;


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cada evento possui um conjunto de colunas que podem ser encontradas na tabela sys.dm_xe_object_columns. 
-- Existem três tipos de colunas que podem existir para um evento. O primeiro tipo é uma coluna de somente 
-- leitura que é um conjunto de colunas de descritor que fornecem informações sobre o evento, como ID de evento, UUID, versão, canal e palavra-chave.
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS PackageName,
              o.name AS EventName,
              c.column_id,
              c.column_type,
              c.name ColumnName,
              c.column_value,
              c.description
FROM sys.dm_xe_objects o
       INNER JOIN sys.dm_xe_packages p
              ON o.package_guid = p.guid
       INNER JOIN sys.dm_xe_object_columns c
              ON o.name = c.object_name
WHERE o.object_type = 'event'
  --AND c.column_type = 'readonly'
  AND (p.capabilities IS NULL OR p.capabilities <> 1)
  and o.name like 'error_reported'
ORDER BY PackageName, EventName, column_type, column_id;


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- O exemplo a seguir demonstra como as visualizações do catálogo podem ser usadas para 
-- recuperar a definição da sessão padrão system_health que vem instalada com o SQL Server 2008.
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT name,
              event_retention_mode_desc AS event_retention_mode,
              max_dispatch_latency,
              max_memory,
              max_event_size,
              memory_partition_mode_desc AS memory_partition_mode,
              track_causality,
              startup_state
FROM sys.server_event_sessions
WHERE name = 'system_health'
SELECT package, e.name, predicate,
(
SELECT package + '.' + name + ', '
FROM sys.server_event_session_actions a
WHERE a.event_session_id = e.event_session_id
  AND a.event_id = e.event_id
ORDER BY package, name
FOR XML PATH('')
) AS Actions
FROM sys.server_event_session_events e
INNER JOIN sys.server_event_sessions es ON e.event_session_id = es.event_session_id
WHERE es.name = 'system_health';
SELECT package, t.name,
(
SELECT name + '=' + cast(value AS varchar) + ', '
FROM sys.server_event_session_fields f
WHERE f.event_session_id = t.event_session_id
  AND f.object_id = t.target_id
FOR XML PATH('')
) AS options
FROM sys.server_event_session_targets t
INNER JOIN sys.server_event_sessions es ON t.event_session_id = es.event_session_id
WHERE es.name = 'system_health';


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- A seguinte consulta retorna todos os destinos disponíveis no servidor (targets)
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS PackageName,
       o.name AS TargetName,
       o.description AS TargetDescription
FROM sys.dm_xe_objects o
       INNER JOIN sys.dm_xe_packages p
              ON o.package_guid = p.guid
WHERE o.object_type = 'target'
  AND (p.capabilities IS NULL OR p.capabilities <> 1)
ORDER BY PackageName, TargetName;


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Cada alvo possui uma lista de colunas de parâmetros que podem ser usadas para configurar o alvo. Algumas das colunas são obrigatórias, 
-- enquanto outras são opcionais. A seguinte consulta retorna os parâmetros para os destinos disponíveis no servidor:
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS PackageName,
              o.name AS TargetName,
              c.name AS ParameterName,
              c.type_name AS ParameterType,
              case c.capabilities_desc
                     when 'mandatory' then 'yes'
                     else 'no'
              end AS [Required]
FROM sys.dm_xe_objects o
       INNER JOIN sys.dm_xe_packages p
              ON o.package_guid = p.guid
       INNER JOIN sys.dm_xe_object_columns c
              ON o.name = c.object_name
WHERE o.object_type = 'target'
  AND (p.capabilities IS NULL OR p.capabilities <> 1)
ORDER BY PackageName, TargetName, [Required] desc;


----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Como as ações executam de forma síncrona, elas devem ser usadas somente quando necessário para 
-- capturar as informações adicionais necessárias. Certas ações, como o package0.debug_break, 
-- não devem ser usadas em ambientes de produção, a menos que seja direcionado pela equipe CSS como 
-- parte de um incidente de suporte aberto. A seguinte consulta retorna as ações disponíveis no servidor:
----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT p.name AS PackageName,
       o.name AS ActionName,
       o.description AS ActionDescription
FROM sys.dm_xe_objects o
       INNER JOIN sys.dm_xe_packages p
              ON o.package_guid = p.guid
WHERE o.object_type = 'action'
  AND (p.capabilities IS NULL OR p.capabilities & 1 = 0)
  and p.name = 'sqlserver'
ORDER BY PackageName, ActionName;