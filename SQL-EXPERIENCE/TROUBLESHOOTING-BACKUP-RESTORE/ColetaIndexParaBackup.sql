/*
    OBJETIVO: Gerar scripts de criação de índices para backup de metadados,
              consultando o sistema de metadados do SQL Server.
    PROJETO: mssqlserver-solution-explorer
*/
-- ============================================================
-- Define o contexto do banco de dados alvo
-- ============================================================
USE P_YOUR_DATABASE_TDE;
GO

-- Consulta o sistema de metadados para gerar scripts de criação de índices
SELECT 
    'CREATE ' 
    + CASE 
          WHEN I.is_unique = 1 THEN 'UNIQUE '
          ELSE ''
      END
    + CASE 
          WHEN I.type = 1 THEN 'CLUSTERED '
          ELSE 'NONCLUSTERED '
      END
    + 'INDEX ' + QUOTENAME(I.name) + ' ON ' + QUOTENAME(T.name) + ' ('
    + STUFF((
        SELECT 
            ', ' + QUOTENAME(C.name)
            + CASE 
                  WHEN IC.is_descending_key = 1 THEN ' DESC'
                  ELSE ' ASC'
              END
        FROM sys.index_columns AS IC
        INNER JOIN sys.columns AS C
            ON C.object_id = IC.object_id
            AND C.column_id = IC.column_id
        WHERE IC.object_id = I.object_id
            AND IC.index_id = I.index_id
        FOR XML PATH(''), TYPE
    ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') + ');'
FROM sys.indexes AS I
INNER JOIN sys.tables AS T
    ON I.object_id = T.object_id
WHERE T.is_ms_shipped = 0;
