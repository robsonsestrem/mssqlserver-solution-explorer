/*
 *
	OBJETIVO: Análise básica de índices e estatísticas de tabelas no SQL Server,
	          incluindo listagem de colunas indexadas, verificação de fill factor,
	          alocação de espaço e inspeção de estatísticas via DBCC SHOW_STATISTICS.
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- =============================================================================
-- Lista os campos correspondentes aos índices criados em uma tabela específica
-- =============================================================================
USE [YOUR_DATABASE];
GO

SELECT
    [i].[name] AS [index_name]
  , COL_NAME([ic].[object_id], [ic].[column_id]) AS [column_name]
  , [ic].[index_column_id]
  , [ic].[key_ordinal]
  , [ic].[is_included_column]
FROM [sys].[indexes] AS [i]
INNER JOIN [sys].[index_columns] AS [ic]
    ON [i].[object_id] = [ic].[object_id]
    AND [i].[index_id] = [ic].[index_id]
WHERE [i].[object_id] = OBJECT_ID('movestoque')
ORDER BY
    [i].[name];


-- =============================================================================
-- Verifica quantos índices existem na tabela
-- =============================================================================
USE [YOUR_DATABASE];
GO

SELECT
    [i].[index_id] AS [Id]
  , [i].[name] AS [Nome]
FROM [sys].[indexes] AS [i]
INNER JOIN [sys].[tables] AS [t]
    ON [t].[object_id] = [i].[object_id]
WHERE [t].[name] = 'CONTABIL';


-- =============================================================================
-- Verifica quantas estatísticas existem na tabela
-- =============================================================================
SELECT
    [s].[stats_id] AS [Id]
  , [s].[name] AS [Nome]
FROM [sys].[stats] AS [s]
INNER JOIN [sys].[tables] AS [t]
    ON [t].[object_id] = [s].[object_id]
WHERE [t].[name] = 'CONTABIL';


-- =============================================================================
-- Verifica estatísticas para determinado campo de uma tabela
-- =============================================================================
SELECT
    [t].[name] AS [Table Name]
  , [c].[name] AS [coluna]
  , [c].[column_id]
  , [s].[name] AS [Stat Name]
  , [s].[stats_id] AS [Stat Id]
  , STATS_DATE([s].[object_id], [s].[stats_id]) AS [Last_Updated]
  , [s].[auto_created]
  , [s].[user_created]
  , [s].[has_filter]
FROM [sys].[stats] AS [s]
INNER JOIN [sys].[tables] AS [t]
    ON [s].[object_id] = [t].[object_id]
INNER JOIN [sys].[columns] AS [c]
    ON [c].[object_id] = [t].[object_id]
WHERE [t].[name] = 'MOVESTOQUE'
  AND [c].[name] IN ('NfPedCod', 'NfFilCod', 'NfDatEmis');


-- =============================================================================
-- Exibe o cabeçalho das estatísticas via DBCC
-- =============================================================================
DBCC SHOW_STATISTICS ('MOVESTOQUE', nfDatEmis) WITH STAT_HEADER;
GO

-- Consulta direta em sys.columns por object_id
SELECT *
FROM [sys].[columns] AS [t]
WHERE [t].[object_id] = 712389607;

-- Consulta em sys.tables por nome
SELECT *
FROM [sys].[tables] AS [t]
WHERE [t].[name] = 'MOVESTOQUE';


-- =============================================================================
-- Lista todas as estatísticas de uma tabela com metadados de criação
-- =============================================================================
SELECT
    [t].[name] AS [Table Name]
  , [s].[name] AS [Stat Name]
  , [s].[stats_id] AS [Stat Id]
  , STATS_DATE([s].[object_id], [s].[stats_id]) AS [Last Updated]
  , [s].[auto_created]
  , [s].[user_created]
  , [s].[has_filter]
FROM [sys].[stats] AS [s]
INNER JOIN [sys].[tables] AS [t]
    ON [s].[object_id] = [t].[object_id]
WHERE [t].[name] = 'MOVESTOQUE';


-- =============================================================================
-- Lista estatísticas da tabela com contagem de modificações (rowmodctr)
-- =============================================================================
USE [YOUR_DATABASE_TI];
GO

SELECT
    [i].[id] AS [ObjectId]
  , [t].[name] AS [TableName]
  , [i].[indid] AS [Index_Stat_Id]
  , [i].[name] AS [Nome_statistics]
  , [i].[rowmodctr] AS [Status_DML]
  , [i].[rows] AS [Total_Rows_Column]
  , [i].[dpages]
FROM [sysindexes] AS [i]
INNER JOIN [sys].[tables] AS [t]
    ON [i].[id] = [t].[object_id]
WHERE [t].[name] = 'MOVESTOQUE'
  AND [i].[rowmodctr] > 3543341
ORDER BY
    [i].[rowmodctr];


-- =============================================================================
-- Verifica o Fill Factor atual das tabelas
-- =============================================================================
SELECT
    [sys].[tables].[name] AS [tabela]
  , [sys].[indexes].[name] AS [indice]
  , [sys].[indexes].[type_desc] AS [tipo]
  , [sys].[indexes].[fill_factor]
  , [sys].[indexes].[is_padded] AS [padded]
FROM [sys].[indexes]
INNER JOIN [sys].[tables]
    ON [sys].[indexes].[object_id] = [sys].[tables].[object_id]
WHERE [sys].[indexes].[is_disabled] = 0
  AND [sys].[indexes].[type] <> 0
ORDER BY
    [tabela]
  , [tipo];


-- =============================================================================
-- Verifica a alocação de espaço da base de dados
-- =============================================================================
USE [DBA_PerformanceHub];
GO

EXEC sp_spaceused;
