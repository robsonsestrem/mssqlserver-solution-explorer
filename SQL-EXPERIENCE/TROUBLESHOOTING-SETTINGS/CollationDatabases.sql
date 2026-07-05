/*
    OBJETIVO: Identificar colunas com collation diferente de 'SQL_Latin1_General_CP1_CI_AS'
              em todos os bancos de dados online da instância, consolidando os resultados
              via tabelas temporárias globais e SQL dinâmico.
    PROJETO: mssqlserver-solution-explorer
*/

-- ---------------------------------------------------------------------------
-- [LEGADO] Consulta ad-hoc original por Adriel (mantida como referência)
-- ---------------------------------------------------------------------------
-- SELECT
--        c.name
--        ,c.collation
--   FROM SYSCOLUMNS c
--   WHERE COLLATION <> 'SQL_Latin1_General_CP1_CI_AS';

-- ---------------------------------------------------------------------------
-- Consulta pontual: divergências de collation no banco H_HEALTHMAP_QAS
-- ---------------------------------------------------------------------------
SELECT
    TABLE_NAME
    ,COLUMN_NAME
    ,COLLATION_NAME
FROM H_HEALTHMAP_QAS.INFORMATION_SCHEMA.COLUMNS
WHERE COLLATION_NAME <> 'SQL_Latin1_General_CP1_CI_AS'
ORDER BY TABLE_NAME ASC;

-- ---------------------------------------------------------------------------
-- Consulta pontual: divergências de collation no banco XPTO
-- ---------------------------------------------------------------------------
SELECT
    TABLE_NAME
    ,COLUMN_NAME
    ,COLLATION_NAME
FROM XPTO.INFORMATION_SCHEMA.COLUMNS
WHERE COLLATION_NAME <> 'SQL_Latin1_General_CP1_CI_AS'
ORDER BY TABLE_NAME ASC;

-- ---------------------------------------------------------------------------
-- Tabela temporária global: resultado consolidado de colunas com collation divergente
-- ---------------------------------------------------------------------------
CREATE TABLE ##dados_collate
(
    id              INT          IDENTITY(1, 1) PRIMARY KEY
    ,DATABASENAME   VARCHAR(200)
    ,TABLE_NAME     VARCHAR(200)
    ,COLUMN_NAME    VARCHAR(200)
    ,COLLATION_NAME VARCHAR(200)
);

-- ---------------------------------------------------------------------------
-- Tabela temporária global: lista de bancos de dados online (state = 0)
-- ---------------------------------------------------------------------------
CREATE TABLE ##databases_online
(
    id   INT         IDENTITY(1, 1) PRIMARY KEY
    ,name VARCHAR(200)
);

-- Popula a lista com todos os bancos em estado online
INSERT INTO ##databases_online
SELECT
    d.name
FROM sys.databases AS d
WHERE d.state = 0;

-- ---------------------------------------------------------------------------
-- Iteração: percorre cada banco online e insere divergências de collation
-- ---------------------------------------------------------------------------
DECLARE @todas    INT = (SELECT COUNT(*) FROM ##databases_online);
DECLARE @contador INT = 0;

WHILE (@contador < @todas)
BEGIN
    SELECT @contador += 1;

    PRINT @contador;

    DECLARE @databasename VARCHAR(200) = (SELECT d.name FROM ##databases_online AS d WHERE d.id = @contador);

    PRINT @databasename;

    DECLARE @comando VARCHAR(MAX);

    -- Monta instrução dinâmica para consultar INFORMATION_SCHEMA do banco corrente
    SET @comando =
        '
        INSERT INTO ##dados_collate
        SELECT ''' + @databasename + ''', TABLE_NAME, COLUMN_NAME, COLLATION_NAME
        FROM ' + @databasename + '.INFORMATION_SCHEMA.COLUMNS
        WHERE COLLATION_NAME <> ''SQL_Latin1_General_CP1_CI_AS''
        ORDER BY TABLE_NAME ASC
        ';

    EXECUTE (@comando);

END;

-- ---------------------------------------------------------------------------
-- Resultado final: exibe todas as divergências de collation encontradas
-- ---------------------------------------------------------------------------
SELECT *
FROM ##dados_collate AS dc;

