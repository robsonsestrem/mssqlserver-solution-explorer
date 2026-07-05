/*
    OBJETIVO: Buscar e armazenar a definição de todas as triggers do banco de dados corrente,
              iterando via cursor e consolidando nome, tabela-pai e body em tabela temporária.
    PROJETO: mssqlserver-solution-explorer
*/

-- ---------------------------------------------------------------------------
-- Limpeza: remove a tabela temporária caso já exista de execução anterior
-- ---------------------------------------------------------------------------
IF OBJECT_ID('temdb..#TRIGGERS_DATABASE') IS NOT NULL
    DROP TABLE #TRIGGERS_DATABASE;
GO

-- ---------------------------------------------------------------------------
-- Declaração de variáveis de trabalho do cursor
-- ---------------------------------------------------------------------------
DECLARE @TriggerName       NVARCHAR(128);
--DECLARE @TriggerSchema   NVARCHAR(128);
DECLARE @TableName         NVARCHAR(128);
--DECLARE @TableSchema     NVARCHAR(128);
DECLARE @TriggerDefinition NVARCHAR(MAX);

-- ---------------------------------------------------------------------------
-- Tabela temporária: armazena nome, tabela-pai e definição de cada trigger
-- ---------------------------------------------------------------------------
CREATE TABLE #TRIGGERS_DATABASE (
    [TRIGGER]     NVARCHAR(128)
    ,[TABLE]      NVARCHAR(128)
    ,[DEFINITION] NVARCHAR(MAX)
);

-- ---------------------------------------------------------------------------
-- Cursor: itera sobre todas as triggers do banco corrente
-- ---------------------------------------------------------------------------
DECLARE TriggerCursor CURSOR FOR
SELECT
    tr.name AS TriggerName
    --,sch.name AS TriggerSchema
    ,tab.name AS TableName
    --,tab_sch.name AS TableSchema
FROM sys.triggers AS tr
INNER JOIN sys.tables AS tab
    ON tr.parent_id = tab.object_id;
    --INNER JOIN sys.schemas AS sch
    --    ON tr.parent_id = sch.schema_id
    --INNER JOIN sys.schemas AS tab_sch
    --    ON tab.schema_id = tab_sch.schema_id

-- Abre o cursor e posiciona na primeira trigger
OPEN TriggerCursor;

FETCH NEXT FROM TriggerCursor INTO @TriggerName, @TableName;

-- ---------------------------------------------------------------------------
-- Loop: processa cada trigger até esgotar o cursor
-- ---------------------------------------------------------------------------
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Obtém a definição da trigger pelo seu OBJECT_ID
    SET @TriggerDefinition = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @TriggerName));

    INSERT INTO #TRIGGERS_DATABASE ([TRIGGER], [TABLE], [DEFINITION])
    VALUES (@TriggerName, @TableName, @TriggerDefinition);

    -- Comentado: bloco de impressão do script de criação da trigger
    --    PRINT '-- =============================================';
    --    PRINT '-- Trigger: ' + @TriggerSchema + '.' + @TriggerName;
    --    PRINT '-- Tabela: ' + @TableSchema + '.' + @TableName;
    --    PRINT '-- =============================================';
    --    PRINT @TriggerDefinition;
    --    PRINT 'GO';
    --    PRINT '';

    -- Avança para a próxima trigger
    FETCH NEXT FROM TriggerCursor INTO @TriggerName, @TableName;
END;

-- Libera os recursos do cursor
CLOSE TriggerCursor;
DEALLOCATE TriggerCursor;

-- ---------------------------------------------------------------------------
-- Resultado: exibe todas as triggers coletadas (export / análise)
-- ---------------------------------------------------------------------------
SELECT *
FROM #TRIGGERS_DATABASE AS td;




