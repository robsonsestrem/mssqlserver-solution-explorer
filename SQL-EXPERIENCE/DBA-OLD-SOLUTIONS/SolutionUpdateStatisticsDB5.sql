/*
 *
    OBJETIVO: Atualização de estatísticas do banco de dados com FULLSCAN para tabelas
              com volume relevante de linhas e quantidade significativa de modificações.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  http://www.fabriciolima.net/blog/2011/06/29/rotina-para-atualizar-as-estatisticas-do-seu-banco-de-dados/
 *  https://learn.microsoft.com/pt-br/sql/t-sql/statements/update-statistics-transact-sql
 *  https://learn.microsoft.com/pt-br/sql/relational-databases/system-stored-procedures/sp-executesql-transact-sql
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_UpdateStatisticsDB5]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        -- Descarta a tabela temporária existente antes da criação
        IF OBJECT_ID('tempdb..#Atualiza_Estatisticas') IS NOT NULL
        BEGIN
            DROP TABLE #Atualiza_Estatisticas
        END

        -- Cria a tabela temporária para comandos de atualização
        CREATE TABLE #Atualiza_Estatisticas
        (
            Id_Estatistica INT IDENTITY(1,1)
          , Ds_Comando VARCHAR(4000)
          , Nr_Linha INT
        )

        -- Seleciona tabelas e estatísticas candidatas à atualização
        ;WITH Tamanho_Tabelas AS
        (
            SELECT
                sc.name AS [schema]
              , obj.name AS Name
              , prt.rows
            FROM sys.objects AS obj
            INNER JOIN sys.indexes AS idx
                ON obj.object_id = idx.object_id
            INNER JOIN sys.partitions AS prt
                ON obj.object_id = prt.object_id
            INNER JOIN sys.allocation_units AS alloc
                ON alloc.container_id = prt.partition_id
            INNER JOIN sys.schemas AS sc
                ON sc.schema_id = obj.schema_id
            WHERE obj.type = 'U'
            AND idx.index_id IN (0, 1)
            AND prt.rows > 1000
            GROUP BY
                sc.name
              , obj.name
              , prt.rows
        )
        INSERT INTO #Atualiza_Estatisticas
        (
            Ds_Comando
          , Nr_Linha
        )
        -- Geração do script e contagem das linhas
        SELECT
            'UPDATE STATISTICS ' + D.[schema] + '.' + B.name + ' ' + A.name + ' WITH FULLSCAN'
          , D.rows
        FROM sys.stats AS A
        INNER JOIN sys.sysobjects AS B
            ON A.object_id = B.id
        INNER JOIN sys.sysindexes AS C
            ON C.id = B.id
            AND A.name = C.Name
        INNER JOIN Tamanho_Tabelas AS D
            ON B.name = D.Name
        WHERE C.rowmodctr > 100
        AND C.rowmodctr > D.rows * 0.005 -- condição calculada para ver necessidade de atualizar
        AND SUBSTRING(B.name, 1, 3) NOT IN ('sys', 'dtp') -- nega tabelas internas
        ORDER BY D.rows

        DECLARE @Loop INT
              , @Comando NVARCHAR(4000)

        SET @Loop = 1

        BEGIN TRANSACTION

        -- Execução sequencial dos comandos gerados
        WHILE EXISTS
        (
            SELECT TOP 1 NULL
            FROM #Atualiza_Estatisticas
        )
        BEGIN
            SELECT @Comando = Ds_Comando
            FROM #Atualiza_Estatisticas
            WHERE Id_Estatistica = @Loop

            EXECUTE sp_executesql @Comando

            DELETE FROM #Atualiza_Estatisticas
            WHERE Id_Estatistica = @Loop

            SET @Loop = @Loop + 1
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- Variáveis para envio de e-mail de falha
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100) -- assunto
              , @recipients VARCHAR(100); -- destinatário

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';
        SET @corpoFalha = ''

        -- Montagem do corpo do e-mail de falha
        SELECT @corpoFalha = @corpoFalha + '
        | Falha na Procedure [sp_UpdateStatisticsDB5]:
        |
        | ---|---|---|
        |    [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
        |      [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
        |      [MESSAGE] - ' + ERROR_MESSAGE() + '
        |
        '

        SELECT @corpoFalha = @corpoFalha + ''

        -- Envio do e-mail de falha
        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients
          , @subject = @subject
          , @profile_name = 'CRAVIL'
          , @body = @corpoFalha
          , @body_format = 'HTML';
    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO