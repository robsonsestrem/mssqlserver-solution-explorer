------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/como-identificar-apagar-e-recriar-foreign-keys-fk-de-uma-tabela-no-sql-server/
-- Gera os scripts de DROP e de CREATE das FK's *01
------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[stpRecria_FK_Tabela]
    @Database [sysname],
    @Objeto [sysname] = NULL,
    @Schema [sysname] = NULL
WITH EXECUTE AS CALLER
AS
BEGIN        

    DECLARE @Db_Id sysname = (SELECT database_id FROM sys.databases WHERE name = @Database)
    DECLARE @query VARCHAR(MAX), @cmd VARCHAR(MAX)

    SET @query = '
    SELECT 
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto.name + ''] DROP CONSTRAINT ['' + FK.name  + '']'' AS Dropar_FKs
    FROM 
        ' + @Database + '.sys.foreign_keys				AS FK
        JOIN ' + @Database + '.sys.foreign_key_columns	AS FK_Coluna ON FK.object_id = FK_Coluna.constraint_object_id
        JOIN ' + @Database + '.sys.objects				AS objeto ON FK.parent_object_id = objeto.object_id
        JOIN ' + @Database + '.sys.schemas				AS schema_ori ON objeto.schema_id = schema_ori.schema_id'


    IF (@Objeto IS NOT NULL)
    BEGIN

        SET @query = @query + '
    WHERE
        objeto.name = ''' + @Objeto + ''''

    END


    IF (@Schema IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
    WHERE 1=1'

        SET @query = @query + '
        AND schema_ori.name = ''' + @Schema + ''''

    END


    EXEC(@query)
------------------------------------------------------------------------------------------------------------------------------------------------------------
    -- 
    -- RECREATE CONSTRAINTS
    --
------------------------------------------------------------------------------------------------------------------------------------------------------------
    SET @query = '
    SELECT 
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto.name + ''] '' + 
        ''ADD CONSTRAINT ['' + fk.name + ''] FOREIGN KEY ('' + colunas.name + '') '' + 
        ''REFERENCES ['' + schema_ref.name + ''].['' + objeto_ref.name + ''] ('' + colunas_ref.name + '')'' as Recriar_FKs
    FROM 
        ' + @Database + '.sys.foreign_keys AS fk
        JOIN ' + @Database + '.sys.foreign_key_columns AS fc ON fk.object_id = fc.constraint_object_id

        JOIN ' + @Database + '.sys.objects objeto ON fk.parent_object_id = objeto.object_id
        JOIN ' + @Database + '.sys.columns colunas ON fc.parent_column_id = colunas.column_id AND fk.parent_object_id = colunas.object_id
        JOIN ' + @Database + '.sys.schemas schema_ori ON objeto.schema_id = schema_ori.schema_id

        JOIN ' + @Database + '.sys.objects objeto_ref ON fc.referenced_object_id = objeto_ref.object_id
        JOIN ' + @Database + '.sys.columns colunas_ref ON fc.referenced_column_id = colunas_ref.column_id AND fk.referenced_object_id = colunas_ref.object_id
        JOIN ' + @Database + '.sys.schemas schema_ref ON objeto_ref.schema_id = schema_ref.schema_id'

    IF (@Objeto IS NOT NULL)
    BEGIN

        SET @query = @query + '
    WHERE
        objeto.name = ''' + @Objeto + ''''

    END

    IF (@Schema IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
    WHERE 1=1'

        SET @query = @query + '
        AND schema_ori.name = ''' + @Schema + ''''

    END

    EXEC(@query)
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/como-identificar-apagar-e-recriar-foreign-keys-fk-de-uma-tabela-no-sql-server/
-- Gera os scripts de DROP e de CREATE das FK's *02
------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[stpRecria_FK]
    @Database [sysname],
    @Objeto [sysname] = NULL,
    @Schema [sysname] = 'dbo'
WITH EXECUTE AS CALLER
AS
BEGIN
    
    DECLARE @Db_Id sysname = (SELECT database_id FROM sys.databases WHERE name = @Database)
    DECLARE @query VARCHAR(MAX), @cmd VARCHAR(MAX)

    SET @query = '
    SELECT
        FK.name AS Ds_Nome_FK,
        schema_ori.name + ''.'' + objeto_ori.name AS Ds_Objeto,
        coluna_ori.name AS Ds_Coluna,
        schema_dest.name + ''.'' + objeto_dest.name AS Ds_Objeto_Referencia,
        coluna_dest.name AS Ds_Coluna_Referencia,
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto_ori.name + ''] DROP CONSTRAINT ['' + FK.name  + '']'' AS Dropar_FK,
        ''ALTER TABLE [' + @Database + '].['' + schema_ori.name + ''].['' + objeto_ori.name + ''] ADD CONSTRAINT ['' + FK.name + ''] FOREIGN KEY ('' + coluna_ori.name + '') REFERENCES [' + @Database + '].['' + schema_dest.name + ''].['' + objeto_dest.name + ''] ('' + coluna_dest.name + '')'' AS Criar_FK
    FROM 
        [' + @Database + '].sys.foreign_keys				    AS FK			WITH(NOLOCK)
        JOIN [' + @Database + '].sys.foreign_key_columns	    AS FK_Coluna	WITH(NOLOCK)	ON FK.object_id = FK_Coluna.constraint_object_id
    
        JOIN [' + @Database + '].sys.objects				    AS objeto_ori	WITH(NOLOCK)	ON FK.parent_object_id = objeto_ori.object_id
        JOIN [' + @Database + '].sys.objects				    AS objeto_dest	WITH(NOLOCK)	ON FK.referenced_object_id = objeto_dest.object_id

        JOIN [' + @Database + '].sys.schemas				    AS schema_ori	WITH(NOLOCK)	ON objeto_ori.schema_id = schema_ori.schema_id
        JOIN [' + @Database + '].sys.schemas				    AS schema_dest	WITH(NOLOCK)	ON FK.schema_id = schema_dest.schema_id
    
        JOIN [' + @Database + '].sys.columns				    AS coluna_ori	WITH(NOLOCK)	ON FK_Coluna.parent_object_id = coluna_ori.object_id AND FK_Coluna.parent_column_id = coluna_ori.column_id
        JOIN [' + @Database + '].sys.columns				    AS coluna_dest	WITH(NOLOCK)	ON FK_Coluna.referenced_object_id = coluna_dest.object_id AND FK_Coluna.referenced_column_id = coluna_dest.column_id'

    IF (NULLIF(LTRIM(RTRIM(@Objeto)), '') IS NOT NULL)
    BEGIN

        SET @query = @query + '
    WHERE
        objeto_dest.name = ''' + @Objeto + ''''

    END

    IF (NULLIF(LTRIM(RTRIM(@Schema)), '') IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
    WHERE 1=1'

        SET @query = @query + '
        AND schema_ori.name = ''' + @Schema + ''''

    END
    SET @query = @query + '
    ORDER BY
        schema_ori.name, objeto_dest.name'

    EXEC(@query)
END
GO


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gera os scripts de DROP e de CREATE das FK's Compostas
------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [dbo].[stpRecria_FK_Composta] (
    @Database [sysname],
    @Objeto [sysname] = NULL,
    @Schema [sysname] = 'dbo'
)
AS
BEGIN
    
    DECLARE @query VARCHAR(MAX), @cmd VARCHAR(MAX) = '
    
;WITH CTE
AS (
    SELECT
        FK.[object_id] AS Id_FK,
        FK.[name] AS Ds_Nome_FK,
        schema_ori.[name] AS Ds_Schema_Origem,
        schema_dest.[name] AS Ds_Schema_Destino,
        objeto_ori.[object_id] AS Id_Objeto_Origem,
        objeto_dest.[object_id] AS Id_Objeto_Destino,
        objeto_ori.[name] AS Ds_Tabela,
        objeto_dest.[name] AS Ds_Tabela_Referencia,
        schema_ori.[name] + ''.'' + objeto_ori.[name] AS Ds_Objeto,
        schema_dest.[name] + ''.'' + objeto_dest.[name] AS Ds_Objeto_Referencia,

        STUFF((
            SELECT '', '' + ISNULL(C1.[name], '''')
            FROM [' + @Database + '].sys.foreign_keys A1 WITH(NOLOCK)
            JOIN [' + @Database + '].sys.foreign_key_columns B1 WITH(NOLOCK) ON A1.[object_id] = B1.constraint_object_id
            JOIN [' + @Database + '].sys.columns C1 WITH(NOLOCK) ON B1.parent_object_id = C1.[object_id] AND B1.parent_column_id = C1.column_id
            WHERE ISNULL(C1.[object_id], '''') = ISNULL(objeto_ori.[object_id], '''')
            AND ISNULL(A1.[object_id], '''') = ISNULL(FK.[object_id], '''')
            ORDER BY C1.[name]
            FOR XML PATH('''')), 1, 2, ''''
        ) AS Colunas_Origem,

        STUFF((
            SELECT '', '' + ISNULL(C1.[name], '''')
            FROM [' + @Database + '].sys.foreign_keys A1 WITH(NOLOCK)
            JOIN [' + @Database + '].sys.foreign_key_columns B1 WITH(NOLOCK) ON A1.[object_id] = B1.constraint_object_id
            JOIN [' + @Database + '].sys.columns C1 WITH(NOLOCK) ON B1.referenced_object_id = C1.[object_id] AND B1.referenced_column_id = C1.column_id
            WHERE ISNULL(C1.[object_id], '''') = ISNULL(objeto_dest.[object_id], '''')
            AND ISNULL(A1.[object_id], '''') = ISNULL(FK.[object_id], '''')
            ORDER BY C1.[name]
            FOR XML PATH('''')), 1, 2, ''''
        ) AS Colunas_Destino
    FROM 
        [' + @Database + '].sys.foreign_keys				    AS FK			WITH(NOLOCK)
        JOIN [' + @Database + '].sys.foreign_key_columns	    AS FK_Coluna	WITH(NOLOCK)	ON FK.[object_id] = FK_Coluna.constraint_object_id
    
        JOIN [' + @Database + '].sys.objects				    AS objeto_ori	WITH(NOLOCK)	ON FK.parent_object_id = objeto_ori.[object_id]
        JOIN [' + @Database + '].sys.objects				    AS objeto_dest	WITH(NOLOCK)	ON FK.referenced_object_id = objeto_dest.[object_id]

        JOIN [' + @Database + '].sys.schemas				    AS schema_ori	WITH(NOLOCK)	ON objeto_ori.[schema_id] = schema_ori.[schema_id]
        JOIN [' + @Database + '].sys.schemas				    AS schema_dest	WITH(NOLOCK)	ON FK.[schema_id] = schema_dest.[schema_id]
    
        JOIN [' + @Database + '].sys.columns				    AS coluna_ori	WITH(NOLOCK)	ON FK_Coluna.parent_object_id = coluna_ori.[object_id] AND FK_Coluna.parent_column_id = coluna_ori.column_id
    GROUP BY
        FK.[object_id],
        FK.[name],
        objeto_ori.[object_id],
        objeto_dest.[object_id],
        schema_ori.[name],
        schema_dest.[name],
        schema_ori.[name] + ''.'' + objeto_ori.[name],
        schema_dest.[name] + ''.'' + objeto_dest.[name],
        objeto_ori.[name],
        objeto_dest.[name]
)
SELECT 
    CTE.Ds_Nome_FK,
    CTE.Ds_Objeto,
    CTE.Ds_Objeto_Referencia,
    CTE.Colunas_Origem,
    CTE.Colunas_Destino,
    ''ALTER TABLE [' + @Database + '].['' + CTE.Ds_Schema_Origem + ''].['' + CTE.Ds_Tabela + ''] DROP CONSTRAINT ['' + CTE.Ds_Nome_FK  + '']'' AS Dropar_FK,
    ''ALTER TABLE [' + @Database + '].['' + CTE.Ds_Schema_Origem + ''].['' + CTE.Ds_Tabela + ''] ADD CONSTRAINT ['' + CTE.Ds_Nome_FK + ''] FOREIGN KEY ('' + CTE.Colunas_Origem + '') REFERENCES [' + @Database + '].['' + CTE.Ds_Schema_Destino + ''].['' + CTE.Ds_Tabela_Referencia + ''] ('' + CTE.Colunas_Destino + '')'' AS Criar_FK
FROM 
    CTE'

    IF (NULLIF(LTRIM(RTRIM(@Objeto)), '') IS NOT NULL)
    BEGIN

        SET @query = @query + '
WHERE
    Ds_Tabela_Referencia = ''' + @Objeto + ''''

    END  

    IF (NULLIF(LTRIM(RTRIM(@Schema)), '') IS NOT NULL)
    BEGIN

        IF (@Objeto IS NULL) 
            SET @query = @query + ' 
WHERE 
    1=1'

        SET @query = @query + '
    AND Ds_Schema_Origem = ''' + @Schema + ''''

    END
    
    SET @query = @query + '
ORDER BY
    Ds_Objeto_Referencia,
    Ds_Nome_FK'
    
    EXEC(@query)
END
GO


