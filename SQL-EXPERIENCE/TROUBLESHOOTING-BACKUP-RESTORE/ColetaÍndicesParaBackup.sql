-- Defina o nome do banco de dados que deseja verificar
USE P_HEALTHMAP_CAREPLUS_TDE;

-- Consulta o sistema de metadados para obter informações sobre índices
SELECT 
    'CREATE ' + 
    CASE 
        WHEN I.is_unique = 1 THEN 'UNIQUE ' 
        ELSE '' 
    END + 
    CASE 
        WHEN I.type = 1 THEN 'CLUSTERED ' 
        ELSE 'NONCLUSTERED ' 
    END + 
    'INDEX ' + QUOTENAME(I.name) + ' ON ' + QUOTENAME(T.name) + ' (' + 
    STUFF((
        SELECT ', ' + QUOTENAME(C.name) + 
        CASE 
            WHEN IC.is_descending_key = 1 THEN ' DESC' 
            ELSE ' ASC' 
        END
        FROM sys.index_columns IC
        JOIN sys.columns C ON C.object_id = IC.object_id AND C.column_id = IC.column_id
        WHERE IC.object_id = I.object_id AND IC.index_id = I.index_id
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ');'
FROM sys.indexes I
JOIN sys.tables T ON I.object_id = T.object_id
WHERE T.is_ms_shipped = 0; -- Ignora tabelas de sistema
