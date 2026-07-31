/*
 *
	OBJETIVO: Análise de erros de login e conectividade no SQL Server utilizando
			  o ring buffer RING_BUFFER_CONNECTIVITY, extraindo informações detalhadas
			  sobre tentativas de conexão, tempos de login, erros de rede e desconexões.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://community.spiceworks.com/topic/1824729-ring_buffer_connectivity-question
 */
-- ============================================================
-- Consulta ao Ring Buffer de Conectividade para diagnóstico de erros de login
-- ============================================================

WITH connectivity_ring_buffer AS
(
    SELECT
        record.value('(Record/@id)[1]', 'int') AS id,
        record.value('(Record/@type)[1]', 'varchar(50)') AS type,
        record.value('(Record/ConnectivityTraceRecord/RecordType)[1]', 'varchar(50)') AS RecordType,
        record.value('(Record/ConnectivityTraceRecord/RecordSource)[1]', 'varchar(50)') AS RecordSource,
        record.value('(Record/ConnectivityTraceRecord/Spid)[1]', 'int') AS Spid,
        record.value('(Record/ConnectivityTraceRecord/SniConnectionId)[1]', 'uniqueidentifier') AS SniConnectionId,
        record.value('(Record/ConnectivityTraceRecord/SniProvider)[1]', 'int') AS SniProvider,
        record.value('(Record/ConnectivityTraceRecord/OSError)[1]', 'int') AS OSError,
        record.value('(Record/ConnectivityTraceRecord/SniConsumerError)[1]', 'int') AS SniConsumerError,
        record.value('(Record/ConnectivityTraceRecord/State)[1]', 'int') AS State,
        record.value('(Record/ConnectivityTraceRecord/RemoteHost)[1]', 'varchar(50)') AS RemoteHost,
        record.value('(Record/ConnectivityTraceRecord/RemotePort)[1]', 'varchar(50)') AS RemotePort,
        record.value('(Record/ConnectivityTraceRecord/LocalHost)[1]', 'varchar(50)') AS LocalHost,
        record.value('(Record/ConnectivityTraceRecord/LocalPort)[1]', 'varchar(50)') AS LocalPort,
        record.value('(Record/ConnectivityTraceRecord/RecordTime)[1]', 'datetime') AS RecordTime,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/TotalLoginTimeInMilliseconds)[1]', 'bigint') AS TotalLoginTimeInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/LoginTaskEnqueuedInMilliseconds)[1]', 'bigint') AS LoginTaskEnqueuedInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/NetworkWritesInMilliseconds)[1]', 'bigint') AS NetworkWritesInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/NetworkReadsInMilliseconds)[1]', 'bigint') AS NetworkReadsInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/SslProcessingInMilliseconds)[1]', 'bigint') AS SslProcessingInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/SspiProcessingInMilliseconds)[1]', 'bigint') AS SspiProcessingInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/LoginTimers/LoginTriggerAndResourceGovernorProcessingInMilliseconds)[1]', 'bigint') AS LoginTriggerAndResourceGovernorProcessingInMilliseconds,
        record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferError)[1]', 'int') AS TdsInputBufferError,
        record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsOutputBufferError)[1]', 'int') AS TdsOutputBufferError,
        record.value('(Record/ConnectivityTraceRecord/TdsBuffersInformation/TdsInputBufferBytes)[1]', 'int') AS TdsInputBufferBytes,
        record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/PhysicalConnectionIsKilled)[1]', 'int') AS PhysicalConnectionIsKilled,
        record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/DisconnectDueToReadError)[1]', 'int') AS DisconnectDueToReadError,
        record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NetworkErrorFoundInInputStream)[1]', 'int') AS NetworkErrorFoundInInputStream,
        record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/ErrorFoundBeforeLogin)[1]', 'int') AS ErrorFoundBeforeLogin,
        record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/SessionIsKilled)[1]', 'int') AS SessionIsKilled,
        record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalDisconnect)[1]', 'int') AS NormalDisconnect
        -- record.value('(Record/ConnectivityTraceRecord/TdsDisconnectFlags/NormalLogout)[1]', 'int') AS NormalLogout
    FROM
    (
        SELECT CAST(record AS XML) AS record
        FROM sys.dm_os_ring_buffers
        WHERE ring_buffer_type = 'RING_BUFFER_CONNECTIVITY'
    ) AS tab
)
SELECT
    c.*,
    text
FROM connectivity_ring_buffer AS c
LEFT JOIN sys.messages AS m
    ON c.SniConsumerError = m.message_id
    AND m.language_id = 1033
-- WHERE recordtype IN ('ConnectionClose', 'Error')
ORDER BY c.id ASC
GO
