/*
    OBJETIVO: Geração automática de tabelas de histórico para temporal tables
              (system-versioned) no SQL Server. Cria a tabela de histórico
              com Clustered Columnstore Index, índice não clusterizado nas
              colunas de período e chave única, adiciona colunas temporais
              na tabela original e ativa SYSTEM_VERSIONING via cursor dinâmico.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    http://billfellows.blogspot.ru/2017/10/temporal-table-maker.html

    AUTOR: Bill Fellows
*/
-- ============================================================
-- Bloco 1: Declaração de variáveis de controle
-- ============================================================
-- Variáveis para construção dinâmica de DDL e iteração por tabelas
DECLARE
    @query NVARCHAR(4000)
    , @targetSchema SYSNAME = 'dbo_HISTORY'
    , @tableName SYSNAME
    , @targetFileGroup SYSNAME = 'History';

-- ============================================================
-- Bloco 2: Cursor FAST_FORWARD sobre tabelas do schema 'dbo'
-- que ainda não possuem tabela de histórico correspondente
-- ============================================================
DECLARE
    CSR CURSOR
    FAST_FORWARD
    FOR
    SELECT ALL
        CONCAT(
            'SELECT * FROM '
            , S.name
            , '.'
            , T.name
        )
        , T.name
    FROM sys.schemas AS S
    INNER JOIN sys.tables AS T
        ON T.schema_id = S.schema_id
    WHERE 1 = 1
        AND S.name = 'dbo'
        AND T.name NOT IN (
            SELECT
                TI.name
            FROM sys.schemas AS SI
            INNER JOIN sys.tables AS TI
                ON TI.schema_id = SI.schema_id
            WHERE SI.name = @targetSchema
        )

OPEN CSR
FETCH NEXT FROM CSR INTO @query, @tableName;

-- ============================================================
-- Bloco 3: Loop pelo cursor, gerando o DDL completo de 
-- temporal table para cada tabela encontrada
-- ============================================================
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Constrói dinamicamente o script SQL para:
    -- 1. CREATE TABLE da tabela de histórico (com colunas da tabela original)
    -- 2. Clustered Columnstore Index na tabela de histórico
    -- 3. Nonclustered Index nas colunas de período + chave única
    -- 4. ALTER TABLE para adicionar colunas temporais com defaults
    -- 5. ALTER TABLE para ativar SYSTEM_VERSIONING
    SELECT
        CONCAT(
            'CREATE TABLE '
            , @targetSchema
            , '.'
            , @tableName
            , '('
            -- Lista de colunas da tabela original obtida via dm_exec_describe_first_result_set
            -- STUFF remove a vírgula líder do primeiro elemento concatenado
            , STUFF(
                (
                    SELECT
                        CONCAT(
                            ','
                            , DEDFRS.name
                            , ' '
                            , DEDFRS.system_type_name
                            , ' '
                            , CASE DEDFRS.is_nullable
                                WHEN 1 THEN ''
                                ELSE 'NOT '
                            END
                            , 'NULL'
                        )
                    FROM sys.dm_exec_describe_first_result_set(@query, N'', 1) AS DEDFRS
                    ORDER BY
                        DEDFRS.column_ordinal
                    FOR XML PATH('')
                )
                , 1
                , 1
                , ''
            )
            -- Colunas temporais obrigatórias na tabela de histórico
            , ', SysStartTime datetime2(7) NOT NULL'
            , ', SysEndTime datetime2(7) NOT NULL'
            , ')'
            , ' ON '
            , @targetFileGroup
            , ';'
            , CHAR(13)
            -- Clustered Columnstore Index para compressão otimizada no histórico
            , 'CREATE CLUSTERED COLUMNSTORE INDEX CCI_'
            , @targetSchema
            , '_'
            , @tableName
            , ' ON '
            , @targetSchema
            , '.'
            , @tableName
            , ' ON '
            , @targetFileGroup
            , ';'
            , CHAR(13)
            -- Nonclustered Index: colunas de período + colunas da chave única
            , 'CREATE NONCLUSTERED INDEX IX_'
            , @targetSchema
            , '_'
            , @tableName
            , '_PERIOD_COLUMNS '
            , ' ON '
            , @targetSchema
            , '.'
            , @tableName
            , '('
            , 'SysEndTime'
            , ',SysStartTime'
            -- Subquery: obtém colunas que compõem a chave única da tabela original
            , (
                SELECT
                    CONCAT(
                        ','
                        , DEDFRS.name
                    )
                FROM sys.dm_exec_describe_first_result_set(@query, N'', 1) AS DEDFRS
                WHERE DEDFRS.is_part_of_unique_key = 1
                ORDER BY
                    DEDFRS.column_ordinal
                FOR XML PATH('')
            )
            , ')'
            , ' ON '
            , @targetFileGroup
            , ';'
            , CHAR(13)
            -- Adiciona colunas temporais na tabela original com constraints DEFAULT
            , 'ALTER TABLE '
            , 'dbo'
            , '.'
            , @tableName
            , ' ADD '
            , 'SysStartTime datetime2(7) GENERATED ALWAYS AS ROW START HIDDEN'
            , ' CONSTRAINT DF_'
            , 'dbo_'
            , @tableName
            , '_SysStartTime DEFAULT SYSUTCDATETIME()'
            , ', SysEndTime datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN'
            , ' CONSTRAINT DF_'
            , 'dbo_'
            , @tableName
            , '_SysEndTime DEFAULT DATETIME2FROMPARTS(9999, 12, 31, 23,59, 59,9999999,7)'
            , ', PERIOD FOR SYSTEM_TIME (SysStartTime, SysEndTime);'
            , CHAR(13)
            -- Ativa system versioning vinculando à tabela de histórico criada
            , 'ALTER TABLE '
            , 'dbo'
            , '.'
            , @tableName
            , ' SET (SYSTEM_VERSIONING = ON (HISTORY_TABLE = '
            , @targetSchema
            , '.'
            , @tableName
            , '));'
        )
    ;

    FETCH NEXT FROM CSR INTO @query, @tableName;
END

CLOSE CSR
DEALLOCATE CSR;
