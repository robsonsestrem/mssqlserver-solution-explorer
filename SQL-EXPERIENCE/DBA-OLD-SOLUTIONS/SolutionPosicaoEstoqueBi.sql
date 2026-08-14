/*
 *
    OBJETIVO: Rotinas de carga do histórico de posição de estoque no BI,
              incluindo processamento diário, fechamento de 2017,
              retrocesso de janeiro de 2018, análise e retenção dos dados.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/pt-br/sql/t-sql/statements/insert-transact-sql
 *  https://learn.microsoft.com/pt-br/sql/t-sql/language-elements/try-catch-transact-sql
 */
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE Bi.sp_PosicaoEstoqueBi
(
    @limite SMALLINT = 1 -- quantas iterações
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @execucao DATETIME
          , @datalimite DATETIME
          , @hoje DATETIME

    SET @hoje = CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)

    -- Coleta última data processada e define a próxima data de cálculo
    SET @execucao =
    (
        SELECT MAX(t1.[DataRotina] + 1)
        FROM DBA_PerformanceHub.Bi.Execucao AS t1
        WHERE t1.Descricao LIKE '%HistoricoPosicaoEstoque%'
    )

    -- Define limite para o laço
    SET @datalimite = DATEADD(DAY, @limite, @execucao)

    WHILE (@execucao < @datalimite AND @execucao < @hoje)
    BEGIN
        -- Registro de execução
        INSERT INTO DBA_PerformanceHub.Bi.Execucao
        (
            DataInsercao
          , Descricao
          , DataRotina
        )
        VALUES
        (
            GETDATE()
          , 'INSERT TABELA HistoricoPosicaoEstoque'
          , @execucao
        )

        -- Carga do histórico de posição de estoque
        INSERT INTO DBA_PerformanceHub.Bi.HistoricoPosicaoEstoque
        (
            Filial
          , NomeFilial
          , DataEmissao
          , CodigoProduto
          , NomeProduto
          , Codigofamilia
          , NomeFamilia
          , CodigoGrupo
          , NomeGrupo
          , CodigoSubgrupo
          , NomeSubgrupo
          , CustoMercadoriaVendida
          , Estoque
          , CustoTotal
        )
        SELECT DISTINCT
            t1.CodigoFilial AS Filial
          , t6.FilNom AS Nome_Filial
          , t1.DataEmissao AS Posicao
          , t1.CodigoProduto AS Codigo_Produto
          , t2.ProNom AS Nome_Produto
          , t1.Codigofamilia AS Codigo_Familia
          , t3.FamNom AS Nome_Familia
          , t1.CodigoGrupo AS Codigo_Grupo
          , t4.GrpNom AS Nome_Grupo
          , t1.CodigoSubgrupo AS Codigo_Subgrupo
          , t5.SubNom AS Nome_Subgrupo
          , t1.CustoMercadoriaVendida
          , t1.Estoque
          , t1.CustoTotal
        FROM DBA_PerformanceHub.Bi.HistoricoCMV AS t1 WITH(NOLOCK)
        INNER JOIN YOUR_DATABASE.dbo.PRODUTOS AS t2 WITH(NOLOCK)
            ON t2.ProCod = t1.CodigoProduto
        INNER JOIN YOUR_DATABASE.dbo.FAMILIAS AS t3 WITH(NOLOCK)
            ON t3.FamCod = t2.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.GRUPOS AS t4 WITH(NOLOCK)
            ON t4.GrpCod = t2.ProGrpCod
            AND t4.FamCod = t2.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.SUBGRUPOS AS t5 WITH(NOLOCK)
            ON t5.FamCod = t2.ProFamCod
            AND t5.GrpCod = t2.ProGrpCod
            AND t5.SubCod = t2.ProSubCod
        INNER JOIN YOUR_DATABASE.dbo.FILIAIS AS t6 WITH(NOLOCK)
            ON t6.FilCod = t1.CodigoFilial
        WHERE t1.DataEmissao = @execucao

        UNION ALL

        -- Produtos sem histórico na data, com custo calculado pela função
        SELECT
            x.FilCod
          , t7.FilNom
          , @execucao AS Posicao
          , x.ProCod
          , t3.ProNom
          , t4.FamCod
          , t4.FamNom
          , t5.GrpCod
          , t5.GrpNom
          , t6.SubCod
          , t6.SubNom
          , t2.CustoMedioUnitario
          , t2.Estoque
          , t2.CustoTotal
        FROM
        (
            SELECT
                t2.FilCod
              , t1.ProCod
            FROM YOUR_DATABASE.dbo.PRODUTOS AS t1 WITH(NOLOCK)
            CROSS APPLY YOUR_DATABASE.dbo.FILIAIS AS t2 WITH(NOLOCK)
            WHERE t1.ProSituacao NOT LIKE 'n'
            AND t2.filflag2 = 0 -- filiais ativas
            AND t2.FilCod NOT IN (61, 90)
            EXCEPT
            SELECT DISTINCT
                t1.CodigoFilial
              , t1.CodigoProduto
            FROM DBA_PerformanceHub.Bi.HistoricoCMV AS t1 WITH(NOLOCK)
            WHERE t1.DataEmissao = @execucao
        ) AS x
        CROSS APPLY YOUR_DATABASE.dbo.GetCustoMercadoria(x.FilCod, x.ProCod, @execucao) AS t2
        INNER JOIN YOUR_DATABASE.dbo.PRODUTOS AS t3 WITH(NOLOCK)
            ON t3.ProCod = x.ProCod
        INNER JOIN YOUR_DATABASE.dbo.FAMILIAS AS t4 WITH(NOLOCK)
            ON t4.FamCod = t3.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.GRUPOS AS t5 WITH(NOLOCK)
            ON t5.GrpCod = t3.ProGrpCod
            AND t5.FamCod = t3.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.SUBGRUPOS AS t6 WITH(NOLOCK)
            ON t6.FamCod = t3.ProFamCod
            AND t6.GrpCod = t3.ProGrpCod
            AND t6.SubCod = t3.ProSubCod
        INNER JOIN YOUR_DATABASE.dbo.FILIAIS AS t7 WITH(NOLOCK)
            ON t7.FilCod = x.FilCod

        -- Incremento da data de execução
        SET @execucao = DATEADD(DAY, 1, @execucao)
    END

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET NOCOUNT OFF
END
GO

USE DBA_PerformanceHub
GO

-- ============================================================
-- Procedure Bi.sp_PosicaoEstoqueBi_2017
-- ============================================================
CREATE OR ALTER PROCEDURE Bi.sp_PosicaoEstoqueBi_2017
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @execucao DATETIME
          , @datalimite DATETIME
          , @limite SMALLINT

    -- Coleta última data processada e define a próxima data de cálculo
    SET @execucao =
    (
        SELECT MAX(t1.[DataRotina] + 1)
        FROM DBA_PerformanceHub.Bi.Execucao AS t1
        WHERE t1.Descricao LIKE '%HistoricoPosicaoEstoque_2017%'
    )

    -- Controle para inserir o mês fechado
    SET @limite = DAY(EOMONTH(@execucao))

    -- Define limite para o laço
    SET @datalimite = DATEADD(DAY, @limite, @execucao)

    WHILE (@execucao < @datalimite)
    BEGIN
        -- Registro de execução
        INSERT INTO DBA_PerformanceHub.Bi.Execucao
        (
            DataInsercao
          , Descricao
          , DataRotina
        )
        VALUES
        (
            GETDATE()
          , 'INSERT TABELA HistoricoPosicaoEstoque_2017'
          , @execucao
        )

        -- Carga do histórico de posição de estoque de 2017
        INSERT INTO DBA_PerformanceHub.Bi.HistoricoPosicaoEstoque
        (
            Filial
          , NomeFilial
          , DataEmissao
          , CodigoProduto
          , NomeProduto
          , Codigofamilia
          , NomeFamilia
          , CodigoGrupo
          , NomeGrupo
          , CodigoSubgrupo
          , NomeSubgrupo
          , CustoMercadoriaVendida
          , Estoque
          , CustoTotal
        )
        SELECT DISTINCT
            t1.CodigoFilial AS Filial
          , t6.FilNom AS Nome_Filial
          , t1.DataEmissao AS Posicao
          , t1.CodigoProduto AS Codigo_Produto
          , t2.ProNom AS Nome_Produto
          , t1.Codigofamilia AS Codigo_Familia
          , t3.FamNom AS Nome_Familia
          , t1.CodigoGrupo AS Codigo_Grupo
          , t4.GrpNom AS Nome_Grupo
          , t1.CodigoSubgrupo AS Codigo_Subgrupo
          , t5.SubNom AS Nome_Subgrupo
          , t1.CustoMercadoriaVendida
          , t1.Estoque
          , t1.CustoTotal
        FROM DBA_PerformanceHub.Bi.HistoricoCMV AS t1 WITH(NOLOCK)
        INNER JOIN YOUR_DATABASE.dbo.PRODUTOS AS t2 WITH(NOLOCK)
            ON t2.ProCod = t1.CodigoProduto
        INNER JOIN YOUR_DATABASE.dbo.FAMILIAS AS t3 WITH(NOLOCK)
            ON t3.FamCod = t2.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.GRUPOS AS t4 WITH(NOLOCK)
            ON t4.GrpCod = t2.ProGrpCod
            AND t4.FamCod = t2.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.SUBGRUPOS AS t5 WITH(NOLOCK)
            ON t5.FamCod = t2.ProFamCod
            AND t5.GrpCod = t2.ProGrpCod
            AND t5.SubCod = t2.ProSubCod
        INNER JOIN YOUR_DATABASE.dbo.FILIAIS AS t6 WITH(NOLOCK)
            ON t6.FilCod = t1.CodigoFilial
        WHERE t1.DataEmissao = @execucao

        UNION ALL

        -- Produtos sem histórico na data, com custo calculado pela função
        SELECT
            x.FilCod
          , t7.FilNom
          , @execucao AS Posicao
          , x.ProCod
          , t3.ProNom
          , t4.FamCod
          , t4.FamNom
          , t5.GrpCod
          , t5.GrpNom
          , t6.SubCod
          , t6.SubNom
          , t2.CustoMedioUnitario
          , t2.Estoque
          , t2.CustoTotal
        FROM
        (
            SELECT
                t2.FilCod
              , t1.ProCod
            FROM YOUR_DATABASE.dbo.PRODUTOS AS t1 WITH(NOLOCK)
            CROSS APPLY YOUR_DATABASE.dbo.FILIAIS AS t2 WITH(NOLOCK)
            WHERE t1.ProSituacao NOT LIKE 'n'
            AND t2.filflag2 = 0 -- filiais ativas
            AND t2.FilCod NOT IN (61, 90)
            EXCEPT
            SELECT DISTINCT
                t1.CodigoFilial
              , t1.CodigoProduto
            FROM DBA_PerformanceHub.Bi.HistoricoCMV AS t1 WITH(NOLOCK)
            WHERE t1.DataEmissao = @execucao
        ) AS x
        CROSS APPLY YOUR_DATABASE.dbo.GetCustoMercadoria(x.FilCod, x.ProCod, @execucao) AS t2
        INNER JOIN YOUR_DATABASE.dbo.PRODUTOS AS t3 WITH(NOLOCK)
            ON t3.ProCod = x.ProCod
        INNER JOIN YOUR_DATABASE.dbo.FAMILIAS AS t4 WITH(NOLOCK)
            ON t4.FamCod = t3.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.GRUPOS AS t5 WITH(NOLOCK)
            ON t5.GrpCod = t3.ProGrpCod
            AND t5.FamCod = t3.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.SUBGRUPOS AS t6 WITH(NOLOCK)
            ON t6.FamCod = t3.ProFamCod
            AND t6.GrpCod = t3.ProGrpCod
            AND t6.SubCod = t3.ProSubCod
        INNER JOIN YOUR_DATABASE.dbo.FILIAIS AS t7 WITH(NOLOCK)
            ON t7.FilCod = x.FilCod

        -- Incremento da data de execução
        SET @execucao = DATEADD(DAY, 1, @execucao)
    END

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET NOCOUNT OFF
END
GO

-- ============================================================
-- Inserção para 2018
-- ============================================================
USE DBA_PerformanceHub
GO

-- ============================================================
-- Procedure Bi.sp_PosicaoEstoque_012018
-- ============================================================
CREATE OR ALTER PROCEDURE Bi.sp_PosicaoEstoque_012018
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @execucao DATETIME
          , @datalimite DATETIME
          , @limite SMALLINT = -5 -- dias a retroagir

    -- Coleta primeira data processada de 2018 e define retrocesso
    SET @execucao =
    (
        SELECT MIN(t1.[DataRotina]) - 1
        FROM DBA_PerformanceHub.Bi.Execucao AS t1
        WHERE t1.Descricao LIKE '%HistoricoPosicaoEstoque%'
        AND YEAR(t1.DataRotina) = 2018
    )

    -- Define limite para o laço
    SET @datalimite = DATEADD(DAY, @limite, @execucao)

    WHILE (@execucao > @datalimite)
    BEGIN
        -- Registro de execução
        INSERT INTO DBA_PerformanceHub.Bi.Execucao
        (
            DataInsercao
          , Descricao
          , DataRotina
        )
        VALUES
        (
            GETDATE()
          , 'INSERT TABELA HistoricoPosicaoEstoque'
          , @execucao
        )

        -- Carga do histórico de posição de estoque
        INSERT INTO DBA_PerformanceHub.Bi.HistoricoPosicaoEstoque
        (
            Filial
          , NomeFilial
          , DataEmissao
          , CodigoProduto
          , NomeProduto
          , Codigofamilia
          , NomeFamilia
          , CodigoGrupo
          , NomeGrupo
          , CodigoSubgrupo
          , NomeSubgrupo
          , CustoMercadoriaVendida
          , Estoque
          , CustoTotal
        )
        SELECT DISTINCT
            t1.CodigoFilial AS Filial
          , t6.FilNom AS Nome_Filial
          , t1.DataEmissao AS Posicao
          , t1.CodigoProduto AS Codigo_Produto
          , t2.ProNom AS Nome_Produto
          , t1.Codigofamilia AS Codigo_Familia
          , t3.FamNom AS Nome_Familia
          , t1.CodigoGrupo AS Codigo_Grupo
          , t4.GrpNom AS Nome_Grupo
          , t1.CodigoSubgrupo AS Codigo_Subgrupo
          , t5.SubNom AS Nome_Subgrupo
          , t1.CustoMercadoriaVendida
          , t1.Estoque
          , t1.CustoTotal
        FROM DBA_PerformanceHub.Bi.HistoricoCMV AS t1 WITH(NOLOCK)
        INNER JOIN YOUR_DATABASE.dbo.PRODUTOS AS t2 WITH(NOLOCK)
            ON t2.ProCod = t1.CodigoProduto
        INNER JOIN YOUR_DATABASE.dbo.FAMILIAS AS t3 WITH(NOLOCK)
            ON t3.FamCod = t2.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.GRUPOS AS t4 WITH(NOLOCK)
            ON t4.GrpCod = t2.ProGrpCod
            AND t4.FamCod = t2.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.SUBGRUPOS AS t5 WITH(NOLOCK)
            ON t5.FamCod = t2.ProFamCod
            AND t5.GrpCod = t2.ProGrpCod
            AND t5.SubCod = t2.ProSubCod
        INNER JOIN YOUR_DATABASE.dbo.FILIAIS AS t6 WITH(NOLOCK)
            ON t6.FilCod = t1.CodigoFilial
        WHERE t1.DataEmissao = @execucao

        UNION ALL

        -- Produtos sem histórico na data, com custo calculado pela função
        SELECT
            x.FilCod
          , t7.FilNom
          , @execucao AS Posicao
          , x.ProCod
          , t3.ProNom
          , t4.FamCod
          , t4.FamNom
          , t5.GrpCod
          , t5.GrpNom
          , t6.SubCod
          , t6.SubNom
          , t2.CustoMedioUnitario
          , t2.Estoque
          , t2.CustoTotal
        FROM
        (
            SELECT
                t2.FilCod
              , t1.ProCod
            FROM YOUR_DATABASE.dbo.PRODUTOS AS t1 WITH(NOLOCK)
            CROSS APPLY YOUR_DATABASE.dbo.FILIAIS AS t2 WITH(NOLOCK)
            WHERE t1.ProSituacao NOT LIKE 'n'
            AND t2.filflag2 = 0 -- filiais ativas
            AND t2.FilCod NOT IN (61, 90)
            EXCEPT
            SELECT DISTINCT
                t1.CodigoFilial
              , t1.CodigoProduto
            FROM DBA_PerformanceHub.Bi.HistoricoCMV AS t1 WITH(NOLOCK)
            WHERE t1.DataEmissao = @execucao
        ) AS x
        CROSS APPLY YOUR_DATABASE.dbo.GetCustoMercadoria(x.FilCod, x.ProCod, @execucao) AS t2
        INNER JOIN YOUR_DATABASE.dbo.PRODUTOS AS t3 WITH(NOLOCK)
            ON t3.ProCod = x.ProCod
        INNER JOIN YOUR_DATABASE.dbo.FAMILIAS AS t4 WITH(NOLOCK)
            ON t4.FamCod = t3.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.GRUPOS AS t5 WITH(NOLOCK)
            ON t5.GrpCod = t3.ProGrpCod
            AND t5.FamCod = t3.ProFamCod
        INNER JOIN YOUR_DATABASE.dbo.SUBGRUPOS AS t6 WITH(NOLOCK)
            ON t6.FamCod = t3.ProFamCod
            AND t6.GrpCod = t3.ProGrpCod
            AND t6.SubCod = t3.ProSubCod
        INNER JOIN YOUR_DATABASE.dbo.FILIAIS AS t7 WITH(NOLOCK)
            ON t7.FilCod = x.FilCod

        -- Decremento da data de execução
        SET @execucao = DATEADD(DAY, -1, @execucao)
    END

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET NOCOUNT OFF
END
GO

-- ============================================================
-- Análise dos dados
-- ============================================================
USE DBA_PerformanceHub
GO

SELECT
    x.Data
  , COUNT(*) AS DadosTotais
FROM
(
    SELECT CAST(t1.DataEmissao AS DATE) AS [Data]
    FROM bi.HistoricoPosicaoEstoque AS t1
    WHERE t1.DataEmissao >= '20180101'
    AND t1.DataEmissao < '20180701'
) AS x
GROUP BY x.Data
ORDER BY x.Data DESC
GO

-- ============================================================
-- Retenção dos dados
-- ============================================================
USE DBA_PerformanceHub
GO

-- ============================================================
-- Procedure Bi.sp_DeletePosicaoEstoque
-- ============================================================
CREATE OR ALTER PROCEDURE Bi.sp_DeletePosicaoEstoque
(
    @qtdadeManterDias INT = 60 -- Quantidade de dias para manter conforme data de emissão
)
WITH ENCRYPTION
AS
BEGIN
    SET STATISTICS TIME ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        -- Contagem de dias existentes no histórico
        DECLARE @qtdadeDias INT
              , @dataMin DATETIME

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Data) AS TotalDias
            FROM
            (
                SELECT COUNT(*) AS [Data]
                FROM bi.HistoricoPosicaoEstoque AS t1
                GROUP BY CAST(t1.DataEmissao AS DATE)
            ) AS x
        )

        -- Loop de exclusão dos dias excedentes
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT MIN(t1.DataEmissao) AS dataMin
                FROM Bi.HistoricoPosicaoEstoque AS t1
            )

            DELETE FROM bi.historicoposicaoestoque
            WHERE dataemissao <= @dataMin

            SET @qtdadeDias -= 1
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
        SET @corpoFalha = '
        <html>
        <head>
        <meta http-equiv=Content-Type content=text/html; charset=windows-1252>
        </head>
        <body>
        <div align=left>'

                -- Montagem do corpo do e-mail de falha
        SELECT @corpoFalha = @corpoFalha + '
        <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
         <tr height=20 style=height:20.0pt>
          <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeletePosicaoEstoque]:<b> <br>
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

        -- Envio do e-mail de falha
        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients
          , @subject = @subject
          , @profile_name = 'CRAVIL'
          , @body = @corpoFalha
          , @body_format = 'HTML';
    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
    SET STATISTICS TIME OFF
END
GO
