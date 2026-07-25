/*
    OBJETIVO: Monitorar eventos de shrink de dados e logs no SQL Server
              através do trace padrão, identificando quando comandos DBCC
              SHRINK foram executados e seus respectivos detalhes.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- SQL Server Data and Log File Shrinks
-- ============================================================

DECLARE @path NVARCHAR(260);

SELECT
    @path = path
FROM
    sys.traces
WHERE
    is_default = 1;

-- Database: Data & Log File Shrink
SELECT
    TextData
  , Duration
  , StartTime
  , EndTime
  , SPID
  , ApplicationName
  , LoginName
FROM
    sys.fn_trace_gettable(@path, DEFAULT)
WHERE
    EventClass IN (116)
    AND TextData LIKE 'DBCC%shrink%'
ORDER BY
    StartTime DESC;
