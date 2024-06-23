IF OBJECT_ID('temdb..#TRIGGERS_DATABASE') IS NOT NULL 
    DROP TABLE #TRIGGERS_DATABASE
GO

-- Declaração de variáveis
DECLARE @TriggerName NVARCHAR(128);
--DECLARE @TriggerSchema NVARCHAR(128);
DECLARE @TableName NVARCHAR(128);
--DECLARE @TableSchema NVARCHAR(128);
DECLARE @TriggerDefinition NVARCHAR(MAX);

CREATE TABLE #TRIGGERS_DATABASE (
  [TRIGGER] NVARCHAR(128)
, [TABLE] NVARCHAR(128)
, [DEFINITION] NVARCHAR(MAX)
)

-- Cursor para iterar sobre todas as triggers
DECLARE TriggerCursor CURSOR FOR
SELECT
    tr.name AS TriggerName,
    --sch.name AS TriggerSchema,
    tab.name AS TableName
    --tab_sch.name AS TableSchema
FROM
    sys.triggers AS tr
    INNER JOIN sys.tables AS tab ON tr.parent_id = tab.object_id
    --INNER JOIN sys.schemas AS sch ON tr.parent_id = sch.schema_id
    --INNER JOIN sys.schemas AS tab_sch ON tab.schema_id = tab_sch.schema_id;

-- Abrir o cursor
OPEN TriggerCursor;

-- Loop pelo cursor
FETCH NEXT FROM TriggerCursor INTO @TriggerName, @TableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Obter a definição da trigger
    SET @TriggerDefinition = OBJECT_DEFINITION(OBJECT_ID('dbo.' + @TriggerName));

    INSERT INTO #TRIGGERS_DATABASE ([TRIGGER], [TABLE], [DEFINITION])
    VALUES (@TriggerName, @TableName, @TriggerDefinition)

    -- Imprimir o script de criação da trigger
--    PRINT '-- =============================================';
--    PRINT '-- Trigger: ' + @TriggerSchema + '.' + @TriggerName;
--    PRINT '-- Tabela: ' + @TableSchema + '.' + @TableName;
--    PRINT '-- =============================================';
--    PRINT @TriggerDefinition;
--    PRINT 'GO';
--    PRINT '';

    -- Buscar a próxima trigger
    FETCH NEXT FROM TriggerCursor INTO @TriggerName, @TableName;
END

-- Fechar e desalocar o cursor
CLOSE TriggerCursor;
DEALLOCATE TriggerCursor;


-- EXPORTA PRA EXCEL E GG
SELECT * FROM #TRIGGERS_DATABASE td



