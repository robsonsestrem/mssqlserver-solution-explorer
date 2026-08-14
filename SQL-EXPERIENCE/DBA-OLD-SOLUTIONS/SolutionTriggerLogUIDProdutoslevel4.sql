/*
 *
    OBJETIVO: Trigger de auditoria para operações de INSERT, UPDATE e DELETE na tabela PRODUTOSLEVEL4,
              registrando todas as alterações de preços em uma tabela de log com valores antigos
              e novos por coluna alterada.
    PROJETO: mssqlserver-solution-explorer
 * 
 */
USE [YOUR_DATABASE]
GO

CREATE OR ALTER TRIGGER [dbo].[tr_Produtoslevel4_LogUID]
ON [dbo].[PRODUTOSLEVEL4]
WITH ENCRYPTION
FOR UPDATE, DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @contador         INT
          , @action           CHAR(15)
          , @Col              INT
          , @qCols            INT
          , @NomeCol          VARCHAR(100)
          , @bitVerificador   INT
          , @Pot              INT

    DECLARE @Inserted        XML
          , @InsertedTMP     XML

    DECLARE @Deleted         XML
          , @DeletedTMP      XML

    -- ============================================================
    -- Conta quantas colunas existem 
    -- na tabela contemplada pela Trigger
    -- ============================================================
    SET @Col = 0
    SET @qCols =
    (
        SELECT COUNT(*)
        FROM sys.columns
        WHERE object_id =
        (
            SELECT parent_id
            FROM sys.triggers
            WHERE object_id = @@procid
        )
    )

    -- ============================================================
    -- Coloca a tabela Deleted em uma variável XML,
    -- para este caso selecionou-se alguns campos
    -- ============================================================
    SET @Deleted =
    (
        SELECT
              ProCod
            , ProCodPreco
            , ProDatIni
            , Final
            , ProDatAlteracao
            , ProVlrPreco
        FROM deleted
        FOR XML RAW, ROOT('Deleted')
    )

    -- ============================================================
    -- Coloca a tabela Inserted em uma variável XML, 
    -- para este caso selecionou-se alguns campos
    -- ============================================================
    SET @Inserted =
    (
        SELECT
              ProCod
            , ProCodPreco
            , ProDatIni
            , Final
            , ProDatAlteracao
            , ProVlrPreco
        FROM inserted
        FOR XML RAW, ROOT('Inserted')
    )

    -- ============================================================
    -- Processamento para operação de DELETE
    -- ============================================================
    IF NOT EXISTS (SELECT TOP 1 NULL FROM inserted)
    BEGIN
        SELECT @action = 'D' FROM deleted

        WHILE (@Col < @qCols)
        BEGIN
            SET @Col = @Col + 1
            SET @Pot = (@Col - 1) % 8 + 1
            SET @Pot = POWER(2, @Pot - 1)
            SET @bitVerificador = ((@Col - 1) / 8) + 1
            SET @NomeCol =
            (
                SELECT Name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT Parent_ID
                    FROM sys.triggers
                    WHERE object_id = @@procid
                )
                AND column_id = @Col
            )

            -- ============================================================
            -- Substitui a TAG no XML da DELETED e faz a extração dos dados
            -- ============================================================
            SET @DeletedTMP = REPLACE(CAST(@Deleted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            INSERT INTO DBA_PerformanceHub.LogErp.Produtoslevel4LogDML
            (
                  DateDML
                , DatabaseUser
                , LoginUser
                , LoginUserSQLTransaction
                , ProgramName
                , HostName
                , TableName
                , TypeSQL
                , Procod
                , CodigoFilial
                , ColumnUpdate
                , ValueOld
            )
            SELECT
                  GETDATE()
                , USER_NAME()
                , SUSER_NAME()
                , ORIGINAL_LOGIN()
                , PROGRAM_NAME()
                , HOST_NAME()
                , 'PRODUTOSLEVEL4'
                , @Action
                , ProCod
                , ProCodPreco
                , ISNULL(@NomeCol, '')
                , ISNULL(
                  (
                      SELECT E.e.value('(/Deleted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)')
                      FROM @DeletedTMP.nodes('.') AS E(e)
                  ), '') AS ValueOld
            FROM deleted AS Ins
        END
    END
    ELSE IF NOT EXISTS (SELECT TOP 1 NULL FROM deleted)
    BEGIN
        SELECT @action = 'I' FROM inserted
    END
    ELSE
    BEGIN
        SELECT @action = 'U' FROM deleted
    END

    -- ============================================================
    -- Processamento para operações de INSERT e UPDATE
    -- ============================================================
    WHILE (@Col < @qCols)
    BEGIN
        SET @Col = @Col + 1
        SET @Pot = (@Col - 1) % 8 + 1
        SET @Pot = POWER(2, @Pot - 1)
        SET @bitVerificador = ((@Col - 1) / 8) + 1

        IF (SUBSTRING(Columns_updated(), @bitVerificador, 1) & @Pot > 0)
        BEGIN
            SET @NomeCol =
            (
                SELECT Name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT parent_id
                    FROM sys.triggers
                    WHERE object_id = @@procid
                )
                AND column_id = @Col
            )

            -- ============================================================
            -- Substitui a TAG no XML da DELETED e faz a extração dos dados
            -- ============================================================
            SET @DeletedTMP = REPLACE(CAST(@Deleted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            -- ============================================================
            -- Substitui a TAG no XML da INSERTED e faz a extração dos dados
            -- ============================================================
            SET @InsertedTMP = REPLACE(CAST(@Inserted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            INSERT INTO DBA_PerformanceHub.LogErp.Produtoslevel4LogDML
            (
                  DateDML
                , DatabaseUser
                , LoginUser
                , LoginUserSQLTransaction
                , ProgramName
                , HostName
                , TableName
                , TypeSQL
                , Procod
                , CodigoFilial
                , ColumnUpdate
                , ValueOld
                , ValueNew
            )
            SELECT
                  X.DateDML
                , X.DatabaseUser
                , X.LoginUser
                , X.LoginUserSQLTransaction
                , X.ProgramName
                , X.HostName
                , X.TableName
                , X.TypeSQL
                , X.ProCod
                , X.ProCodPreco
                , X.ColumnUpdate
                , X.ValueOld
                , X.ValueNew
            FROM
            (
                SELECT
                      GETDATE() AS DateDML
                    , USER_NAME() AS DatabaseUser
                    , SUSER_NAME() AS LoginUser
                    , ORIGINAL_LOGIN() AS LoginUserSQLTransaction
                    , PROGRAM_NAME() AS ProgramName
                    , HOST_NAME() AS HostName
                    , 'PRODUTOSLEVEL4' AS TableName
                    , @Action AS TypeSQL
                    , ProCod AS ProCod
                    , ProCodPreco AS ProCodPreco
                    , ISNULL(@NomeCol, '') AS ColumnUpdate
                    , ISNULL(
                      (
                          SELECT E.e.value('(/Deleted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)')
                          FROM @DeletedTMP.nodes('.') AS E(e)
                      ), '') AS ValueOld
                    , ISNULL(
                      (
                          SELECT E.e.value('(/Inserted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)')
                          FROM @InsertedTMP.nodes('.') AS E(e)
                      ), '') AS ValueNew
                FROM inserted AS Ins
            ) AS X
            WHERE X.ValueNew <> X.ValueOld
        END
    END
END
GO

-- ============================================================
-- Tabela de logs – Local onde a trigger acima 
-- registra os dados DML da tabela PRODUTOSLEVEL4,
-- onde são registradas as mudanças de preços dos produtos
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE LogErp.Produtoslevel4LogDML
(
      LogId                      INT NOT NULL IDENTITY(1, 1)
    , DateDML                    DATETIME DEFAULT GETDATE()
    , DatabaseUser               VARCHAR(100) DEFAULT USER_NAME()
    , LoginUser                  VARCHAR(100) DEFAULT SUSER_NAME()
    , LoginUserSQLTransaction    VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
    , ProgramName                VARCHAR(100) DEFAULT PROGRAM_NAME()
    , HostName                   VARCHAR(100) DEFAULT HOST_NAME()
    , TableName                  VARCHAR(30) DEFAULT 'PRODUTOSLEVEL4'
    , TypeSQL                    CHAR(1)
    , Procod                     INT NOT NULL
    , CodigoFilial               INT NOT NULL
    , ColumnUpdate               SYSNAME
    , ValueOld                   VARCHAR(100) DEFAULT ''
    , ValueNew                   VARCHAR(100) DEFAULT ''
    , CONSTRAINT PK_ProLogId PRIMARY KEY CLUSTERED (LogId ASC)
    , CONSTRAINT CK_TableNamePro CHECK (TableName LIKE 'PRODUTOSLEVEL4')
    , CONSTRAINT CK_TypeSQLPro CHECK (TypeSQL IN ('D', 'I', 'U'))
)
GO

-- ============================================================
-- Procedure de retenção de dados - Produtoslevel4LogDML
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE LogErp.sp_DeleteLogProdutoslevel4
(
    @qtdadeManterDias INT = 365 -- Quantidade de dias para manter
)
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY

        BEGIN TRANSACTION

        -- ============================================================
        -- Bloco 01: Busca quantidade de dias distintos registrados
        -- ============================================================
        DECLARE @qtdadeDias INT
              , @dataMin    DATE

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Registros)
            FROM
            (
                SELECT COUNT(*) AS [Registros]
                FROM DBA_PerformanceHub.LogErp.Produtoslevel4LogDML AS t1
                GROUP BY CAST(t1.DateDML AS DATE)
            ) AS x
        )

        -- ============================================================
        -- Bloco 02: Loop para tratamento e exclusão dos dias excedentes
        -- ============================================================
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT CAST(DATEADD(DAY, 1, ((SELECT MIN(t1.DateDML) FROM DBA_PerformanceHub.LogErp.Produtoslevel4LogDML AS t1))) AS DATE)
            )

            DELETE FROM DBA_PerformanceHub.LogErp.Produtoslevel4LogDML
            WHERE DateDML < @dataMin

            SET @qtdadeDias = @qtdadeDias - 1
        END

        COMMIT TRANSACTION

    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Bloco 03: Captura de exceção e montagem do e-mail de falha
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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteLogProdutoslevel4]:<b> <br>
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

        -- ============================================================
        -- Bloco 04: Envio do e-mail de falha
        -- ============================================================
        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'

    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

END
GO
