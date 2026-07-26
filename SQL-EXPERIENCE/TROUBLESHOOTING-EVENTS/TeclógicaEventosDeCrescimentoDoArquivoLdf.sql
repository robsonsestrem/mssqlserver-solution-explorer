/*
	OBJETIVO: Identificar eventos de crescimento automático do arquivo de log (LDF)
			  por meio do Default Trace do SQL Server, permitindo avaliar se o
			  tamanho inicial configurado é suficiente ou se precisa ser ajustado.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS E AUTORIA:
	Script cedido pela TECLÓGICA.
	Monitoramento de eventos de autogrowth para otimização do dimensionamento inicial.
*/
USE YOUR_DATABASE;
GO

-- ================================================================
-- Obter o nome do arquivo de trace atualmente ativo
-- ================================================================
DECLARE @filename NVARCHAR(1000);
DECLARE @bc       INT;
DECLARE @ec       INT;
DECLARE @bfn      VARCHAR(1000);
DECLARE @efn      VARCHAR(10);

SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1
      AND property = 2;

-- ================================================================
-- Extrair partes do nome do arquivo para obter o padrão
-- sem o número de rollover
-- ================================================================
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.', @filename);
SET @ec = CHARINDEX('_', @filename) + 1;
SET @efn = REVERSE(SUBSTRING(@filename, 1, @bc));
SET @bfn = REVERSE(SUBSTRING(@filename, @ec, LEN(@filename)));

-- ================================================================
-- Definir o nome do arquivo de trace sem o número de rollover
-- ================================================================
SET @filename = @bfn + @efn;

-- ================================================================
-- Consultar todos os arquivos de trace para eventos de autogrowth
-- ================================================================
SELECT
      ftg.StartTime
    , te.name                                                                           AS EventName
    , DB_NAME(ftg.databaseid)                                                           AS DatabaseName
    , ftg.Filename
    , (ftg.IntegerData * 8) / 1024.0                                                    AS GrowthMB
    , (ftg.duration / 1000) / 1000                                                      AS Seconds
FROM ::fn_trace_gettable(@filename, DEFAULT)                                            AS ftg
INNER JOIN sys.trace_events                                                             AS te
        ON ftg.EventClass = te.trace_event_id
WHERE ftg.EventClass = 93                                                               -- Log File Auto-grow
      AND ftg.databaseid = 5
ORDER BY
      ftg.StartTime;
