/*
    OBJETIVO: Mapear dependências entre objetos SQL Server utilizando system views,
              CTEs recursivas e stored procedures customizadas, cobrindo dependências
              diretas, schema-bound, multi-nível e por tipo de dado legado.
    PROJETO: mssqlserver-solution-explorer
    REFERÊNCIAS DE URL: 
    https://www.dirceuresende.com/blog/mapeando-dependencias-entre-objetos-sql-server/
*    
*/
-- ---------------------------------------------------------------------------
-- Bloco 1: Exemplos de uso — sp_VerifyDirectDependencies
-- Lista todas as dependências diretas de um objeto (cross-database, 1 nível)
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

EXEC Management.sp_VerifyDirectDependencies 'YOUR_DATABASE.dbo.TRANSACIONADORES';
EXEC Management.sp_VerifyDirectDependencies 'YOUR_DATABASE.dbo.tr_Transacionadores_LogUD';
EXEC Management.sp_VerifyDirectDependencies 'DBA_PerformanceHub.Management.DDLTransaction';


-- ---------------------------------------------------------------------------
-- Bloco 2: Exemplos de uso — sp_VerifyDependenciesFull
-- Procedure cross-database e multi-nível via CTE recursiva
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

EXEC Management.sp_VerifyDependenciesFull 'DBA_PerformanceHub.LogErp.TransacionadorLogDML';    -- mostra a trigger que alimenta
EXEC Management.sp_VerifyDependenciesFull 'YOUR_DATABASE.dbo.TRANSACIONADORES';
EXEC Management.sp_VerifyDependenciesFull 'YOUR_DATABASE.dbo.FILIAIS';                      -- mostra a trigger e outros
EXEC Management.sp_VerifyDependenciesFull 'DBA_PerformanceHub.Management.DDLTransaction';

-- ---------------------------------------------------------------------------
-- Bloco 3: Relatório completo de dependências
-- Uma linha por objeto com lista de dependentes separados por vírgula (STUFF/FOR XML)
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

SELECT
    DB_NAME() AS dbname
    ,o.type_desc AS referenced_object_type
    ,d1.referenced_entity_name
    ,d1.referenced_id
    ,STUFF((
        SELECT
            ', ' + OBJECT_NAME(d2.referencing_id)
        FROM sys.sql_expression_dependencies AS d2
        WHERE d2.referenced_id = d1.referenced_id
        ORDER BY OBJECT_NAME(d2.referencing_id)
        FOR XML PATH('')
    ), 1, 1, '') AS dependent_objects_list
FROM sys.sql_expression_dependencies AS d1
JOIN sys.objects AS o
    ON d1.referenced_id = o.[object_id]
GROUP BY
    o.type_desc
    ,d1.referenced_id
    ,d1.referenced_entity_name
ORDER BY
    o.type_desc
    ,d1.referenced_entity_name;


-- ---------------------------------------------------------------------------
-- Bloco 4: Dependências schema-bound (views indexadas, colunas calculadas, check constraints)
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

SELECT
    OBJECT_NAME(d.referencing_id) AS referencing_name
    ,o.type_desc AS referencing_object_type
    ,d.referencing_minor_id AS referencing_column_id
    ,cc2.name AS referencing_column_name
    ,d.referenced_entity_name
    ,d.referenced_minor_id AS referenced_column_id
    ,cc.name AS referenced_column_name
FROM sys.sql_expression_dependencies AS d
JOIN sys.all_columns AS cc
    ON d.referenced_minor_id = cc.column_id
    AND d.referenced_id = cc.[object_id]
JOIN sys.objects AS o
    ON d.referencing_id = o.[object_id]
LEFT JOIN sys.all_columns AS cc2
    ON d.referencing_minor_id = cc2.column_id
    AND d.referencing_id = cc2.[object_id]
WHERE d.is_schema_bound_reference = 1
    AND d.referencing_minor_id > 0;


-- ---------------------------------------------------------------------------
-- Bloco 5: Dependências em vários níveis hierárquicos via CTE recursiva
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

WITH Arvore_Dependencias (referenced_id, referenced_name, referencing_id, referencing_name, NestLevel)
AS (
    -- Âncora: objeto raiz da hierarquia
    SELECT
        A.[object_id] AS referenced_id
        ,A.name AS referenced_name
        ,A.[object_id] AS referencing_id
        ,A.name AS referencing_name
        ,0 AS NestLevel
    FROM sys.objects AS A
    WHERE A.name = 'TRANSACIONADORES'    -- **** coloque o objeto aqui

    UNION ALL

    -- Recursão: percorre os níveis de dependência
    SELECT
        A.referenced_id
        ,OBJECT_NAME(A.referenced_id)
        ,A.referencing_id
        ,OBJECT_NAME(A.referencing_id)
        ,NestLevel + 1
    FROM sys.sql_expression_dependencies AS A
    JOIN Arvore_Dependencias AS B
        ON A.referenced_id = B.referencing_id
)
SELECT DISTINCT
    referenced_id
    ,referenced_name
    ,referencing_id
    ,referencing_name
    ,NestLevel
FROM Arvore_Dependencias
WHERE NestLevel > 0
ORDER BY
    NestLevel
    ,referencing_id;


-- ---------------------------------------------------------------------------
-- Bloco 6: Dependências por tipo de dado legado (TEXT, NTEXT, IMAGE) via CTE recursiva
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

WITH Arvore_Dependencias
AS (
    -- Âncora: objetos cujas colunas usam tipos TEXT, NTEXT ou IMAGE
    SELECT DISTINCT
        A.name
        ,A.[object_id] AS referenced_id
        ,A.name AS referenced_name
        ,A.[object_id] AS referencing_id
        ,A.name AS referencing_name
        ,0 AS NestLevel
    FROM sys.objects AS A
    JOIN sys.columns AS B
        ON A.[object_id] = B.[object_id]
    WHERE A.is_ms_shipped = 0
        AND B.system_type_id IN (34, 99, 35)    -- TEXT=34, NTEXT=99, IMAGE=35 (coloque aqui o id do tipo desejado)

    UNION ALL

    -- Recursão: percorre os dependentes dos objetos encontrados na âncora
    SELECT
        B.name
        ,A.referenced_id
        ,OBJECT_NAME(A.referenced_id)
        ,A.referencing_id
        ,OBJECT_NAME(A.referencing_id)
        ,NestLevel + 1
    FROM sys.sql_expression_dependencies AS A
    JOIN Arvore_Dependencias AS B
        ON A.referenced_id = B.referencing_id
)
SELECT
    name AS parent_object_name
    ,referenced_id
    ,referenced_name
    ,referencing_id
    ,referencing_name
    ,NestLevel
FROM Arvore_Dependencias AS t1
WHERE NestLevel > 0
ORDER BY
    name
    ,NestLevel;


-- ---------------------------------------------------------------------------
-- Bloco 7: Análise de tabelas, relacionamentos, objetos e constraints por tabela
-- REFERÊNCIA: http://www.linhadecodigo.com.br/artigo/3018/como-encontrar-objetos-no-sql-server.aspx
-- ---------------------------------------------------------------------------
USE YOUR_DATABASE;
GO

SET NOCOUNT ON;

-- Mostra todas as tabelas do schema dbo
PRINT('*********************************************************');
PRINT('MOSTRAR TODAS TABELAS DO SCHEMA VENDAS [SALES]');

SELECT
    T.NAME AS TABELAS
FROM sys.tables AS T
INNER JOIN sys.schemas AS S
    ON T.schema_id = S.schema_id
WHERE S.name = 'dbo';

DECLARE @TABELA VARCHAR(50);
SET @TABELA = '%ProdutorERP%';

-- Relacionamentos de 1º nível da tabela
PRINT('*********************************************************');
PRINT('RELACIONAMENTOS DE 1 NIVEL DA TABELA');

SELECT
    PK.TABLE_NAME AS PAI
    ,FK.TABLE_NAME AS FILHO
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS C
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS PK
    ON C.CONSTRAINT_NAME = PK.CONSTRAINT_NAME
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS FK
    ON C.UNIQUE_CONSTRAINT_NAME = FK.CONSTRAINT_NAME
WHERE FK.TABLE_NAME = REPLACE(@TABELA, '%', '')
    OR PK.TABLE_NAME = REPLACE(@TABELA, '%', '');

-- Todos os objetos que referenciam a tabela
PRINT('*********************************************************');
PRINT('TODOS OS OBJETOS DA TABELA');

SELECT
    O.NAME AS NOME
    ,REPLACE(O.type_desc, '_', ' ') AS TIPO
FROM SYS.OBJECTS AS O
INNER JOIN SYSCOMMENTS AS C
    ON O.object_id = C.ID
WHERE C.TEXT LIKE @TABELA;

-- Todas as constraints da tabela
PRINT('*********************************************************');
PRINT('TODAS AS CONSTRAINTS DA TABELA');

SELECT
    O2.NAME AS TABELA
    ,CL.NAME AS COLUNA
    ,O.NAME AS [CONSTRAINT]
    ,COM.TEXT AS CONDIÇÃO
FROM SYSCONSTRAINTS AS C
INNER JOIN SYSOBJECTS AS O
    ON O.ID = C.CONSTID
INNER JOIN SYSOBJECTS AS O2
    ON O2.ID = C.ID
INNER JOIN SYSCOLUMNS AS CL
    ON CL.ID = O2.ID
    AND CL.COLID = C.COLID
INNER JOIN SYSCOMMENTS AS COM
    ON O.ID = COM.ID
WHERE O2.NAME LIKE REPLACE(@TABELA, '%', '')
    AND O2.XTYPE = 'U'
ORDER BY
    O2.NAME
    ,CL.NAME
    ,O.NAME;

SET NOCOUNT OFF;


-- =========================================================================
-- Procedure para identificar todas as dependências diretas de um objeto
-- SQL Server, listando os objetos que fazem referência a ele,
-- com suporte a consultas cross-database.
-- EXEMPLO DE USO:
-- EXEC Management.sp_VerifyDirectDependencies 'Testes.dbo.Clientes'
-- =========================================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_VerifyDirectDependencies
(
    @Ds_Objeto_Completo VARCHAR(255)
  , @Ds_Tabela_Destino  VARCHAR(100) = NULL
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    -- ============================================================
    -- DECLARE @Ds_Objeto_Completo SYSNAME = 'Dacasa..Cliente'
    --       , @Ds_Tabela_Destino VARCHAR(100) = '##Teste'
    -- ============================================================

    DECLARE @Ds_Database     VARCHAR(255)
          , @Ds_Schema       VARCHAR(255)
          , @Ds_Objeto       VARCHAR(255)
          , @Query           NVARCHAR(MAX)
          , @Tabela_Temp     VARCHAR(100) = '##Lista_Dependencias_Objeto_' + CAST(CAST(RAND() * 999999 AS INT) AS VARCHAR(100))
          , @Tabela_Destino  VARCHAR(100)

    SET @Tabela_Destino = CASE
                              WHEN @Ds_Tabela_Destino IS NULL THEN @Tabela_Temp
                              ELSE @Ds_Tabela_Destino
                          END

    -- ============================================================
    -- Extrai os componentes do nome do objeto (database, schema, objeto)
    -- ============================================================
    SELECT
          @Ds_Database = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 1)
        , @Ds_Schema   = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 2)
        , @Ds_Objeto   = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 3)

    -- ============================================================
    -- Criação da tabela temporária para armazenar as dependências
    -- ============================================================
    SET @Query = N'
IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL)
    DROP TABLE ' + @Tabela_Destino + ';

CREATE TABLE ' + @Tabela_Destino + ' (
      referencing_database     VARCHAR(MAX)
    , referencing_schema       VARCHAR(MAX)
    , referencing_object_name  VARCHAR(MAX)
    , referenced_server        VARCHAR(MAX)
    , referenced_database      VARCHAR(MAX)
    , referenced_schema        VARCHAR(MAX)
    , referenced_object_name   VARCHAR(MAX)
);'

    EXEC sp_executesql @Query

    -- ============================================================
    -- Lista de databases a serem verificadas (exceto system databases)
    -- ============================================================
    IF OBJECT_ID('tempdb..#Databases') IS NOT NULL
        DROP TABLE #databases

    CREATE TABLE #databases
    (
          database_id    INT
        , database_name  SYSNAME
    )

    INSERT INTO #databases (database_id, database_name)
    SELECT database_id, name
    FROM sys.databases WITH(NOLOCK)
    WHERE database_id > 4

    -- ============================================================
    -- Loop para verificar dependências em cada database
    -- ============================================================
    DECLARE @database_id   INT
          , @database_name SYSNAME

    WHILE (SELECT COUNT(*) FROM #databases) > 0
    BEGIN
        SELECT TOP 1
              @database_id   = database_id
            , @database_name = database_name
        FROM #databases

        SET @Query = '
INSERT INTO ' + @Tabela_Destino + '
SELECT
      DB_NAME(' + CONVERT(VARCHAR, @database_id) + ')
    , OBJECT_SCHEMA_NAME(referencing_id, ' + CONVERT(VARCHAR, @database_id) + ')
    , OBJECT_NAME(referencing_id, ' + CONVERT(VARCHAR, @database_id) + ')
    , referenced_server_name
    , ISNULL(referenced_database_name, DB_NAME(' + CONVERT(VARCHAR, @database_id) + '))
    , referenced_schema_name
    , referenced_entity_name
FROM ' + QUOTENAME(@database_name) + '.sys.sql_expression_dependencies WITH(NOLOCK)
WHERE referenced_entity_name = ''' + @Ds_Objeto + ''';'

        EXEC sys.sp_executesql @Query

        DELETE FROM #databases
        WHERE database_id = @database_id
    END

    -- ============================================================
    -- Retorna os resultados e limpa a tabela temporária
    -- ============================================================
    IF (@Ds_Tabela_Destino IS NULL)
    BEGIN
        SET @Query = '
SELECT *
FROM ' + @Tabela_Destino + ';

IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL)
    DROP TABLE ' + @Tabela_Destino + ';'

        EXEC sp_executesql @Query
    END

    SET NOCOUNT OFF
END
GO


-- =========================================================================
-- Procedure cross-database e multi-nível para mapeamento de dependências
-- entre objetos do SQL Server usando CTE recursiva.
-- Procedure Management.sp_VerifyDependenciesFull
-- Exemplo de uso:
-- EXEC Management.sp_VerifyDependenciesFull 'Testes.dbo.Clientes'
-- =========================================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_VerifyDependenciesFull
(
    @Ds_Objeto_Completo VARCHAR(255)
  , @Ds_Tabela_Destino VARCHAR(100) = NULL
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    -- Exemplo de execução local:
    -- DECLARE @Ds_Objeto_Completo SYSNAME = 'Dacasa..Cliente', @Ds_Tabela_Destino VARCHAR(100) = '##Teste'

    -- ============================================================
    -- Bloco 01: Variáveis de apoio e resolução do objeto informado
    -- ============================================================
    DECLARE @Ds_Database VARCHAR(255)
          , @Ds_Schema VARCHAR(255)
          , @Ds_Objeto VARCHAR(255)
          , @Query NVARCHAR(MAX)
          , @Tabela_Temp VARCHAR(100) = '##Lista_Dependencias_Objeto_' + CAST(CAST(RAND() * 999999 AS INT) AS VARCHAR(100))
          , @Tabela_Destino VARCHAR(100)

    SET @Tabela_Destino =
    (
        CASE
            WHEN @Ds_Tabela_Destino IS NULL THEN @Tabela_Temp
            ELSE @Ds_Tabela_Destino
        END
    )

    SELECT
        @Ds_Database = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 1)
      , @Ds_Schema = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 2)
      , @Ds_Objeto = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 3)

    -- ============================================================
    -- Bloco 02: Criação da tabela de destino das dependências
    -- ============================================================
    SET @Query = N'
    IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL) DROP TABLE ' + @Tabela_Destino + ';
    CREATE TABLE ' + @Tabela_Destino + '
    (
        database_name VARCHAR(255) NULL
      , referenced_id INT NULL
      , referenced_name VARCHAR(255) NULL
      , referencing_id INT NULL
      , referencing_name VARCHAR(255) NULL
      , NestLevel INT NULL
    );'

    EXEC sp_executesql @Query

    -- ============================================================
    -- Bloco 03: Varredura das dependências em todos os bancos
    -- ============================================================
    SET @Query = '
    USE [?];
    WITH Arvore_Dependencias
    (
        referenced_id
      , referenced_name
      , referencing_id
      , referencing_name
      , NestLevel
    )
    AS
    (
        SELECT
            o.[object_id] AS referenced_id
          , CAST(NULL AS VARCHAR(255)) AS referenced_name
          , o.[object_id] AS referencing_id
          , CAST(NULL AS VARCHAR(255)) AS referencing_name
          , 0 AS NestLevel
        FROM sys.objects AS o WITH(NOLOCK)
        WHERE o.name = ''' + @Ds_Objeto + '''
        UNION ALL
        SELECT
            d1.referenced_id
          , CAST(d1.referenced_entity_name AS VARCHAR(255)) AS referenced_entity_name
          , d1.referencing_id
          , CAST(OBJECT_NAME(d1.referencing_id) AS VARCHAR(255)) AS referencing_name
          , 1 AS NestLevel
        FROM sys.sql_expression_dependencies AS d1 WITH(NOLOCK)
        WHERE d1.referenced_id IS NULL
        AND d1.referenced_database_name = ''' + @Ds_Database + '''
        AND d1.referenced_schema_name = ''' + @Ds_Schema + '''
        AND d1.referenced_entity_name = ''' + @Ds_Objeto + '''
        UNION ALL
        SELECT
            d1.referenced_id
          , CAST(d1.referenced_entity_name AS VARCHAR(255)) AS referenced_entity_name
          , d1.referencing_id
          , CAST(OBJECT_NAME(d1.referencing_id) AS VARCHAR(255)) AS referencing_name
          , NestLevel + 1
        FROM sys.sql_expression_dependencies AS d1 WITH(NOLOCK)
        INNER JOIN Arvore_Dependencias AS r
            ON d1.referenced_id = r.referencing_id
    )
    INSERT INTO ' + @Tabela_Destino + '
    SELECT DISTINCT
        DB_NAME() AS database_name
      , referenced_id
      , referenced_name
      , referencing_id
      , referencing_name
      , NestLevel
    FROM Arvore_Dependencias
    WHERE NestLevel > 0
    ORDER BY NestLevel, database_name, referencing_id
    OPTION (MAXRECURSION 32);'

    EXEC sys.sp_MSforeachdb
        @command1 = @Query

    -- ============================================================
    -- Bloco 04: Apresentação e descarte da tabela temporária
    -- ============================================================
    IF (@Ds_Tabela_Destino IS NULL)
    BEGIN
        SET @Query = '
        SELECT *
        FROM ' + @Tabela_Destino + '
        ORDER BY NestLevel, database_name, referencing_id;
        IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL) DROP TABLE ' + @Tabela_Destino + ';'

        EXEC sp_executesql @Query
    END
END
GO







