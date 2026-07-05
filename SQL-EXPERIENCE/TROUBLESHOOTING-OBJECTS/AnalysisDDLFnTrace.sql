/*
    OBJETIVO: Consultar o trace padrão da instância via sys.fn_trace_gettable para identificar
              eventos DDL de criação, alteração e exclusão de objetos (EventClass 46, 47 e 164).
    PROJETO: mssqlserver-solution-explorer
    REFERÊNCIA: https://www.mssqltips.com/sqlservertip/8221/who-created-that-sql-server-object/
*/

-- ---------------------------------------------------------------------------
-- Bloco 1: Todos os eventos DDL registrados no trace padrão ativo
-- ---------------------------------------------------------------------------
DECLARE @trace_path1 NVARCHAR(260);

-- Obtém o caminho do arquivo de trace padrão da instância
SELECT @trace_path1 = path
FROM sys.traces
WHERE is_default = 1;

SELECT
    LoginName
    ,ObjectName
    ,DatabaseName
    ,ServerName
    ,ApplicationName
    ,StartTime
    ,CASE EventClass
        WHEN 164 THEN '164 - Altered'
        WHEN 46  THEN '46 - Created'
        WHEN 47  THEN '47 - Dropped'
    END AS EventClass
    ,EventSubClass
    ,EventSequence
FROM sys.fn_trace_gettable(@trace_path1, 0)
WHERE EventClass IN (46, 47, 164)
ORDER BY StartTime DESC;

-- ---------------------------------------------------------------------------
-- Bloco 2: Mesma consulta filtrada por EventSubClass = 1
-- ---------------------------------------------------------------------------
DECLARE @trace_path2 NVARCHAR(260);

-- Obtém o caminho do arquivo de trace padrão da instância
SELECT @trace_path2 = path
FROM sys.traces
WHERE is_default = 1;

SELECT
    LoginName
    ,ObjectName
    ,DatabaseName
    ,ServerName
    ,ApplicationName
    ,StartTime
    ,CASE EventClass
        WHEN 164 THEN '164 - Altered'
        WHEN 46  THEN '46 - Created'
        WHEN 47  THEN '47 - Dropped'
    END AS EventClass
    ,EventSubClass
    ,EventSequence
FROM sys.fn_trace_gettable(@trace_path2, 3)
WHERE EventClass IN (46, 47, 164)
    AND EventSubClass = 1
ORDER BY StartTime DESC;
