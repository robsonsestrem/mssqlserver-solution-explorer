/*
 *
    OBJETIVO: Procedure para visão geral de dependências entre objetos
              em todos os bancos de dados do servidor (exceto system databases),
              listando objetos referenciados e seus dependentes.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: sys.sql_expression_dependencies, sys.objects
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_VisionDependencies
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    BEGIN TRY
        -- ============================================================
        -- Lista de databases a serem verificadas (exceto system databases)
        -- ============================================================
        DECLARE @ListaDatabases TABLE
        (
              id   INT IDENTITY PRIMARY KEY
            , NAME VARCHAR(300)
        )

        INSERT INTO @ListaDatabases (NAME)
        SELECT NAME
        FROM master.sys.sysdatabases s
        WHERE dbid NOT IN (1, 2, 3, 4)
            AND DATABASEPROPERTYEX(NAME, 'Status') = 'ONLINE'
        ORDER BY 1

        -- ============================================================
        -- Tabela para armazenar as dependências de todos os bancos
        -- ============================================================
        DECLARE @dependeciasTodos TABLE
        (
              DatabaseName              SYSNAME
            , Referenced_Object_Type    NVARCHAR(100)
            , Referenced_Entity_Name    NVARCHAR(100)
            , Referenced_Id             INT
            , Dependent_Objects_List    NVARCHAR(MAX)
        )

        -- ============================================================
        -- Declaração de variáveis para controle do loop
        -- ============================================================
        DECLARE @id          INT
              , @cnt         INT
              , @Comando     NVARCHAR(MAX)
              , @NomeBanco   VARCHAR(300)

        SET @id = 1
        SET @cnt = (SELECT MAX(id) FROM @ListaDatabases)

        BEGIN TRANSACTION

        -- ============================================================
        -- Loop para processar cada database
        -- ============================================================
        WHILE (@id <= @cnt)
        BEGIN
            SET @NomeBanco = (SELECT NAME FROM @ListaDatabases WHERE id = @id)

            SET @Comando = '
            USE ' + @NomeBanco + '

            SELECT
                  DatabaseName = ''' + @NomeBanco + '''
                , o.type_desc AS referenced_object_type
                , d1.referenced_entity_name
                , d1.referenced_id
                , STUFF((
                      SELECT
                          '', '' + OBJECT_NAME(d2.referencing_id)
                      FROM sys.sql_expression_dependencies d2
                      WHERE d2.referenced_id = d1.referenced_id
                      ORDER BY OBJECT_NAME(d2.referencing_id)
                      FOR XML PATH('''')
                  ), 1, 1, '''') AS dependent_objects_list
            FROM sys.sql_expression_dependencies d1
                JOIN sys.objects o ON d1.referenced_id = o.[object_id]
            GROUP BY
                  o.type_desc
                , d1.referenced_id
                , d1.referenced_entity_name
            ORDER BY
                  o.type_desc
                , d1.referenced_entity_name'

            INSERT INTO @dependeciasTodos
            EXEC (@Comando)

            SET @id = @id + 1
        END

        -- ============================================================
        -- Retorna os resultados
        -- ============================================================
        SELECT *
        FROM @dependeciasTodos

        COMMIT TRANSACTION

    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Captura de exceção e montagem do e-mail de falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject    VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content=text/html; charset=windows-1252>
            </head>
            <body>
            <div align=left>'

        SELECT @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na Procedure [sp_VisionDependencies]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'

    END CATCH

    SET NOCOUNT OFF
END
GO
