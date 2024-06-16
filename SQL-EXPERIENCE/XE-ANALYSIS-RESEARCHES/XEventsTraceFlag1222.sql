
/************************************************	TRACE FLAG 1222 ************************************************/

http://www.sqlservercentral.com/blogs/zoras-sql-tips/2016/07/04/know-how-to-handle-deadlock-in-sql-server/
https://www.simple-talk.com/sql/database-administration/handling-deadlocks-in-sql-server/
https://mlanzarini.wordpress.com/2016/01/15/trace-flags/

--Retorna os recursos e os tipos de bloqueios que participam de um Deadlock e também o comando atual afetado, em um formato XML, quando ocorre Deadlock na instância.
--Serão gravadas no Log do SQL Server informações referentes a database, recurso, objeto, página, o script que estava sendo executado, o SPID da transação, tempo de espera,  
--aplicação origem da transação, hostname, loginname, dentre outros.
--Obs.: Deadlocks são situações de bloqueios permanentes onde dois ou mais processos ficam aguardando por outro recurso com lock, 
--devido a outro processo que está reservando esse recurso para si. E com isso, a transação que está aguardando o recurso, é abortada.

--Com os comandos abaixo, com DBCC (Database Consistency Checker). O primeiro exemplo está habilitando a Trace Flag 1222. 
--O segundo exemplo está desabilitando as Trace flags 1222 e 3608.
                   DBCC TRACEON (1222)

                   DBCC TRACEOFF (1222, 3608)

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- O SQL Server 2008 inclui todas as técnicas previamente discutidas para capturar gráficos de deadlock e adiciona um novo, 
-- ou seja, coletar as informações de deadlock através da sessão de eventos padrão system_health em Eventos Estendidos. 
-- Essa sessão de evento padrão (semelhante, no conceito, ao rastreamento padrão) está sendo executada por 
-- padrão em todas as instalações do SQL Server 2008 e coleta um intervalo de informações de solução de problemas úteis para erros que ocorrem no SQL Server, 
-- incluindo deadlocks. Gráficos Deadlock capturados por Eventos estendidos no 
-- SQL Server 2008 têm a capacidade exclusiva de conter informações sobre deadlocks multi-vítima (deadlocks onde mais de sessão foi morto pelo Lock Monitor para resolver o conflito).

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Abaixo, esse é um arquivo xml histórico contendo todas as informações sobre deadlocks anteriores.
-- Ajuda se você pode pegar os graficos de SQL pertinentes e obter as instruções completas sendo executadas.
SELECT CAST(CAST(st.target_data AS xml).query('RingBufferTarget/event[@name=xml_deadlock_report]/data/value/text()').value('.', 'nvarchar(MAX)') AS xml)
FROM sys.dm_xe_session_targets st
INNER JOIN sys.dm_xe_sessions s
ON st.event_session_address = s.address
WHERE s.name = 'system_health' AND st.target_name = 'ring_buffer'
FOR XML PATH('deadlock-list');


-- A sessão system_health usa um alvo ring_buffer que armazena as informações coletadas por eventos disparando na memória como um documento XML no DMV sys.dm_xe_session_targets. 
-- Esse DMV pode ser associado ao DMV sys.dm_xe_sessions para obter as informações da sessão junto com os dados armazenados no alvo ring_buffer
SELECT  CAST(target_data AS XML) AS TargetData
FROM    sys.dm_xe_session_targets st
        JOIN sys.dm_xe_sessions s ON s.address = st.event_session_address
WHERE   name = 'system_health' 


-- A consulta na Listagem 5a mostra como recuperar um gráfico de deadlock XML válido a partir da sessão padrão system_health usando XQuery, 
-- a coluna target_data e uma CROSS APPLY para obter os nós de eventos individuais.
-- Observe que, devido a alterações no gráfico deadlock para suportar deadlocks multi-vítima e para minimizar o tamanho dos dados de evento, 
-- o XML resultante não pode ser salvo como um arquivo XDL para representação gráfica.
SELECT  CAST(event_data.value('(event/data/value)[1]',
                               'varchar(max)') AS XML) AS DeadlockGraph
FROM    ( SELECT    XEvent.query('.') AS event_data
          FROM      (    -- Cast the target_data to XML 
                      SELECT    CAST(target_data AS XML) AS TargetData
                      FROM      sys.dm_xe_session_targets st
                                JOIN sys.dm_xe_sessions s
                                 ON s.address = st.event_session_address
                      WHERE     name = 'system_health'
                                AND target_name = 'ring_buffer'
                    ) AS Data -- Split out the Event Nodes 
                    CROSS APPLY TargetData.nodes('RingBufferTarget/
                                     event[@name=xml_deadlock_report]')
                    AS XEventData ( XEvent )
        ) AS tab ( event_data )
