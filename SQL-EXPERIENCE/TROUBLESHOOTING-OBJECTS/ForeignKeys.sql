/*
    OBJETIVO:    Listar todas as foreign keys do banco com mapeamento de tabela origem/destino
                 e colunas participantes; e buscar dependências de FK por tabela referenciada.
    PROJETO:     mssqlserver-solution-explorer
    REFERÊNCIA:  https://dataedo.com/kb/query/sql-server/list-foreign-keys
*/

-- ---------------------------------------------------------------------------
-- Bloco 1: Inventário completo de foreign keys com colunas participantes
-- ---------------------------------------------------------------------------
SELECT
     SCHEMA_NAME(fk_tab.schema_id) + '.' + fk_tab.name AS foreign_table
    ,'>-'                                               AS rel
    ,SCHEMA_NAME(pk_tab.schema_id) + '.' + pk_tab.name AS primary_table
    ,SUBSTRING(column_names, 1, LEN(column_names) - 1) AS [fk_columns]
    ,fk.name                                            AS fk_constraint_name
FROM sys.foreign_keys AS fk
INNER JOIN sys.tables AS fk_tab
    ON fk_tab.object_id = fk.parent_object_id
INNER JOIN sys.tables AS pk_tab
    ON pk_tab.object_id = fk.referenced_object_id
CROSS APPLY (
    SELECT col.[name] + ', '
    FROM sys.foreign_key_columns AS fk_c
         INNER JOIN sys.columns AS col
             ON fk_c.parent_object_id = col.object_id
            AND fk_c.parent_column_id = col.column_id
    WHERE fk_c.parent_object_id     = fk_tab.object_id
      AND fk_c.constraint_object_id = fk.object_id
    ORDER BY col.column_id
    FOR XML PATH ('')
) AS D (column_names)
ORDER BY
     SCHEMA_NAME(fk_tab.schema_id) + '.' + fk_tab.name
    ,SCHEMA_NAME(pk_tab.schema_id) + '.' + pk_tab.name;

-- ---------------------------------------------------------------------------
-- Bloco 2: Busca de dependências de FK por tabela referenciada
-- ---------------------------------------------------------------------------
SELECT
     obj.name  AS FK_NAME
    ,sch.name  AS [schema_name]
    ,tab1.name AS [table]
    ,col1.name AS [column]
    ,tab2.name AS [referenced_table]
    ,col2.name AS [referenced_column]
FROM sys.foreign_key_columns AS fkc
INNER JOIN sys.objects AS obj
    ON obj.object_id = fkc.constraint_object_id
INNER JOIN sys.tables AS tab1
    ON tab1.object_id = fkc.parent_object_id
INNER JOIN sys.schemas AS sch
    ON tab1.schema_id = sch.schema_id
INNER JOIN sys.columns AS col1
    ON col1.column_id = parent_column_id
   AND col1.object_id = tab1.object_id
INNER JOIN sys.tables AS tab2
    ON tab2.object_id = fkc.referenced_object_id
INNER JOIN sys.columns AS col2
    ON col2.column_id = referenced_column_id
   AND col2.object_id = tab2.object_id
WHERE tab2.name LIKE '%AVALS%';