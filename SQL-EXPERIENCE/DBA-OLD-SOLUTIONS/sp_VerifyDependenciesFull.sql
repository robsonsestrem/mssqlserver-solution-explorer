--------------------------------------------------------------------------------------------------------------------------------
-- Refer�ncias -> https://www.dirceuresende.com/blog/mapeando-dependencias-entre-objetos-sql-server/
-- Procedure Cross-database e multi-n�vel
-- Com a procedure abaixo, que utiliza CTE e recursividade, � poss�vel listar todos os 
-- objetos dependentes com v�rios n�veis de hierarquia no banco de origem e as 
-- depend�ncias diretas (1� n�vel) e cross-database.
-- EXEMPLO DE USO
-- EXEC Management.sp_VerifyDependenciesFull 'Testes.dbo.Clientes'


--------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO
CREATE OR ALTER PROCEDURE Management.sp_VerifyDependenciesFull (
    @Ds_Objeto_Completo VARCHAR(255),
    @Ds_Tabela_Destino VARCHAR(100) = NULL
)
WITH ENCRYPTION
AS BEGIN
    SET NOCOUNT ON


    -- DECLARE @Ds_Objeto_Completo SYSNAME = 'Dacasa..Cliente', @Ds_Tabela_Destino VARCHAR(100) = '##Teste'
    
    
    DECLARE 
        @Ds_Database VARCHAR(255),
        @Ds_Schema VARCHAR(255),
        @Ds_Objeto VARCHAR(255),
        @Query NVARCHAR(MAX),
        @Tabela_Temp VARCHAR(100) = '##Lista_Dependencias_Objeto_' + CAST(CAST(RAND() * 999999 AS INT) AS VARCHAR(100)),
        @Tabela_Destino VARCHAR(100)


    SET @Tabela_Destino = (CASE WHEN @Ds_Tabela_Destino IS NULL THEN @Tabela_Temp ELSE @Ds_Tabela_Destino END)

    
    SELECT
        @Ds_Database = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 1),
        @Ds_Schema = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 2),
        @Ds_Objeto = Management.fn_ValueSeparateByVarious(@Ds_Objeto_Completo, '.', 3)

    SET @Query = N'
IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL) DROP TABLE ' + @Tabela_Destino + ';
CREATE TABLE ' + @Tabela_Destino + ' (
    database_name VARCHAR(255) NULL,
    referenced_id INT NULL,
    referenced_name VARCHAR(255) NULL,
    referencing_id INT NULL,
    referencing_name VARCHAR(255) NULL,
    NestLevel INT NULL
);'
    
    EXEC sp_executesql @Query


    SET @Query = '
USE [?];
    
WITH Arvore_Dependencias (referenced_id, referenced_name, referencing_id, referencing_name, NestLevel)
AS
(
    SELECT
        o.[object_id] AS referenced_id,
        CAST(NULL AS VARCHAR(255)) AS referenced_name,
        o.[object_id] AS referencing_id,
        CAST(NULL AS VARCHAR(255)) AS referencing_name,
        0 AS NestLevel
    FROM
        sys.objects o	WITH(NOLOCK)
    WHERE
        o.name = ''' + @Ds_Objeto + '''

    UNION ALL
    
    SELECT
        d1.referenced_id,
        CAST(d1.referenced_entity_name AS VARCHAR(255)) AS referenced_entity_name,
        d1.referencing_id,
        CAST(OBJECT_NAME(d1.referencing_id) AS VARCHAR(255)) AS referencing_name,
        1 AS NestLevel
    FROM
        sys.sql_expression_dependencies d1		WITH(NOLOCK)
    WHERE
        d1.referenced_id IS NULL
        AND d1.referenced_database_name = ''' + @Ds_Database + '''
        AND d1.referenced_schema_name = ''' + @Ds_Schema + '''
        AND d1.referenced_entity_name = ''' + @Ds_Objeto + '''
        
    UNION ALL

    SELECT
        d1.referenced_id,
        CAST(d1.referenced_entity_name AS VARCHAR(255)) AS referenced_entity_name,
        d1.referencing_id,
        CAST(OBJECT_NAME(d1.referencing_id) AS VARCHAR(255)) AS referencing_name,
        NestLevel + 1
    FROM
        sys.sql_expression_dependencies d1		WITH(NOLOCK)
        JOIN Arvore_Dependencias r ON d1.referenced_id = r.referencing_id
)
INSERT INTO ' + @Tabela_Destino + '
SELECT DISTINCT DB_NAME() AS database_name, referenced_id, referenced_name, referencing_id, referencing_name, NestLevel
FROM Arvore_Dependencias
WHERE NestLevel > 0
ORDER BY NestLevel, database_name, referencing_id
OPTION (MAXRECURSION 32);'
    
    
    EXEC sys.sp_MSforeachdb
        @command1 = @Query
    

    IF (@Ds_Tabela_Destino IS NULL)
    BEGIN

        SET @Query = '
SELECT * FROM ' + @Tabela_Destino + ' ORDER BY NestLevel, database_name, referencing_id;
IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL) DROP TABLE ' + @Tabela_Destino + ';'

        EXEC sp_executesql @Query
    END
END