/*
    OBJETIVO:    Gerar o dicionário de dados do banco, listando schema, tabela, coluna,
                 tipo de dado (com precisão/escala), nullable, default, PK, FK, UK,
                 check constraint, colunas computadas e comentários (extended properties).
    PROJETO:     mssqlserver-solution-explorer
    REFERÊNCIA:  https://dataedo.com/blog/useful-sql-server-data-dictionary-queries-every-dba-should-have
                 https://dhiegopiroto.wordpress.com/2012/10/11/dicionario-de-dados-diretamente-pelo-sql-server/
*/

USE DBA_PerformanceHub;
GO

-- ---------------------------------------------------------------------------
-- Dicionário de dados: colunas, tipos, constraints e comentários por tabela
-- ---------------------------------------------------------------------------
SELECT
     SCHEMA_NAME(tab.schema_id)  AS schema_name
    ,tab.name                    AS table_name
    ,col.name                    AS column_name
    ,t.name                      AS data_type
    ,t.name +
     CASE WHEN t.is_user_defined = 0 THEN
               ISNULL('(' +
               CASE WHEN t.name IN ('binary', 'char', 'nchar',
                         'varchar', 'nvarchar', 'varbinary') THEN
                         CASE col.max_length
                              WHEN -1 THEN 'MAX'
                              ELSE
                                   CASE WHEN t.name IN ('nchar',
                                             'nvarchar') THEN
                                             CAST(col.max_length / 2
                                             AS VARCHAR(4))
                                        ELSE CAST(col.max_length
                                             AS VARCHAR(4))
                                   END
                         END
                    WHEN t.name IN ('datetime2', 'datetimeoffset',
                         'time') THEN
                         CAST(col.scale AS VARCHAR(4))
                    WHEN t.name IN ('decimal', 'numeric') THEN
                          CAST(col.precision AS VARCHAR(4)) + ', ' +
                          CAST(col.scale AS VARCHAR(4))
               END + ')', '')
          ELSE ':' +
               (SELECT c_t.name +
                       ISNULL('(' +
                       CASE WHEN c_t.name IN ('binary', 'char',
                                 'nchar', 'varchar', 'nvarchar',
                                 'varbinary') THEN
                                  CASE c.max_length
                                       WHEN -1 THEN 'MAX'
                                       ELSE
                                            CASE WHEN t.name IN
                                                      ('nchar',
                                                      'nvarchar') THEN
                                                      CAST(c.max_length / 2
                                                      AS VARCHAR(4))
                                                 ELSE CAST(c.max_length
                                                      AS VARCHAR(4))
                                            END
                                  END
                            WHEN c_t.name IN ('datetime2',
                                 'datetimeoffset', 'time') THEN
                                 CAST(c.scale AS VARCHAR(4))
                            WHEN c_t.name IN ('decimal', 'numeric') THEN
                                 CAST(c.precision AS VARCHAR(4)) + ', '
                                 + CAST(c.scale AS VARCHAR(4))
                       END + ')', '')
                  FROM sys.columns AS c
                       INNER JOIN sys.types AS c_t
                           ON c.system_type_id = c_t.user_type_id
                 WHERE c.object_id    = col.object_id
                   AND c.column_id    = col.column_id
                   AND c.user_type_id = col.user_type_id
               )
     END                         AS data_type_ext
    ,CASE WHEN col.is_nullable = 0 THEN 'N'
          ELSE 'Y'
     END                         AS nullable
    ,CASE WHEN def.definition IS NOT NULL THEN def.definition
          ELSE ''
     END                         AS default_value
    ,CASE WHEN pk.column_id IS NOT NULL THEN 'PK'
          ELSE ''
     END                         AS primary_key
    ,CASE WHEN fk.parent_column_id IS NOT NULL THEN 'FK'
          ELSE ''
     END                         AS foreign_key
    ,CASE WHEN uk.column_id IS NOT NULL THEN 'UK'
          ELSE ''
     END                         AS unique_key
    ,CASE WHEN ch.check_const IS NOT NULL THEN ch.check_const
          ELSE ''
     END                         AS check_contraint
    ,cc.definition               AS computed_column_definition
    ,ep.value                    AS comments
FROM sys.tables AS tab
     LEFT JOIN sys.columns AS col
         ON tab.object_id = col.object_id
     LEFT JOIN sys.types AS t
         ON col.user_type_id = t.user_type_id
     LEFT JOIN sys.default_constraints AS def
         ON def.object_id = col.default_object_id
     -- Subquery: identifica colunas que pertencem à chave primária
     LEFT JOIN (
               SELECT index_columns.object_id
                     ,index_columns.column_id
                 FROM sys.index_columns
                      INNER JOIN sys.indexes
                          ON index_columns.object_id = indexes.object_id
                         AND index_columns.index_id  = indexes.index_id
                WHERE indexes.is_primary_key = 1
               ) AS pk
         ON col.object_id = pk.object_id
        AND col.column_id = pk.column_id
     -- Subquery: identifica colunas que participam de chaves estrangeiras
     LEFT JOIN (
               SELECT fc.parent_column_id
                     ,fc.parent_object_id
                 FROM sys.foreign_keys AS f
                      INNER JOIN sys.foreign_key_columns AS fc
                          ON f.object_id = fc.constraint_object_id
                GROUP BY fc.parent_column_id
                        ,fc.parent_object_id
               ) AS fk
         ON fk.parent_object_id = col.object_id
        AND fk.parent_column_id = col.column_id
     -- Subquery: identifica colunas com check constraints
     LEFT JOIN (
               SELECT c.parent_column_id
                     ,c.parent_object_id
                     ,'Check' AS check_const
                 FROM sys.check_constraints AS c
                GROUP BY c.parent_column_id
                        ,c.parent_object_id
               ) AS ch
         ON col.column_id = ch.parent_column_id
        AND col.object_id = ch.parent_object_id
     -- Subquery: identifica colunas que pertencem a unique constraints
     LEFT JOIN (
               SELECT index_columns.object_id
                     ,index_columns.column_id
                 FROM sys.index_columns
                      INNER JOIN sys.indexes
                          ON indexes.index_id  = index_columns.index_id
                         AND indexes.object_id = index_columns.object_id
                WHERE indexes.is_unique_constraint = 1
                GROUP BY index_columns.object_id
                        ,index_columns.column_id
               ) AS uk
         ON col.column_id = uk.column_id
        AND col.object_id = uk.object_id
     LEFT JOIN sys.extended_properties AS ep
         ON tab.object_id = ep.major_id
        AND col.column_id = ep.minor_id
        AND ep.name       = 'MS_Description'
        AND ep.class_desc = 'OBJECT_OR_COLUMN'
     LEFT JOIN sys.computed_columns AS cc
         ON tab.object_id = cc.object_id
        AND col.column_id = cc.column_id
ORDER BY schema_name
        ,table_name
        ,column_name;