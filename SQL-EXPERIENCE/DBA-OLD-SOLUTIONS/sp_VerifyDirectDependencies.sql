-----------------------------------------------------------------------------------------------------------------------------------------------
-- Refer�ncias -> https://www.dirceuresende.com/blog/mapeando-dependencias-entre-objetos-sql-server/
-- Essa procedure lista todas as depend�ncias diretas de um objeto, de modo cross-database
-- EXEMPLO DE USO
-- EXEC Management.sp_VerifyDirectDependencies 'Testes.dbo.Clientes'


-----------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO
CREATE OR ALTER PROCEDURE Management.sp_VerifyDirectDependencies (
    @Ds_Objeto_Completo VARCHAR(255),
    @Ds_Tabela_Destino VARCHAR(100) = NULL
)
WITH ENCRYPTION
AS
BEGIN
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
    referencing_database varchar(max),
    referencing_schema varchar(max),
    referencing_object_name varchar(max),
    referenced_server varchar(max),
    referenced_database varchar(max),
    referenced_schema varchar(max),
    referenced_object_name varchar(max)
);'
    
    EXEC sp_executesql @Query
    
    
    IF (OBJECT_ID('tempdb..#Databases') IS NOT NULL) DROP TABLE #databases
    CREATE TABLE #databases (
        database_id int, 
        database_name sysname
    );

    
    -- ignore systems databases
    INSERT INTO #databases(database_id, database_name)
    SELECT database_id, name FROM sys.databases	WITH(NOLOCK)
    WHERE database_id > 4;  


    DECLARE 
        @database_id int, 
        @database_name sysname


    WHILE (SELECT COUNT(*) FROM #databases) > 0 
    BEGIN
    
    
        SELECT TOP 1 
            @database_id = database_id, 
            @database_name = database_name 
        FROM 
            #databases;


        SET @Query = '
INSERT INTO ' + @Tabela_Destino + ' 
SELECT
    DB_NAME(' + convert(varchar,@database_id) + '), 
    OBJECT_SCHEMA_NAME(referencing_id,' + convert(varchar,@database_id) +'), 
    OBJECT_NAME(referencing_id,' + convert(varchar,@database_id) + '), 
    referenced_server_name,
    ISNULL(referenced_database_name, db_name(' + convert(varchar,@database_id) + ')),
    referenced_schema_name,
    referenced_entity_name
FROM 
    ' + QUOTENAME(@database_name) + '.sys.sql_expression_dependencies	WITH(NOLOCK)
WHERE
    referenced_entity_name = ''' + @Ds_Objeto + ''';'

        
        EXEC sys.sp_executesql @Query


        DELETE FROM #databases WHERE database_id = @database_id;

        
    END	
    
    
    
    IF (@Ds_Tabela_Destino IS NULL)
    BEGIN

        SET @Query = '
SELECT * FROM ' + @Tabela_Destino + ';
IF (OBJECT_ID(''tempdb..' + @Tabela_Destino + ''') IS NOT NULL) DROP TABLE ' + @Tabela_Destino + ';'

        EXEC sp_executesql @Query


    END
    
    
END;

