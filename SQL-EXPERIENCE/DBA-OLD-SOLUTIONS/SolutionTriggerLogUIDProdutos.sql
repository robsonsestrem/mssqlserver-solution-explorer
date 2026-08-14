/*
 *
    OBJETIVO: Trigger de auditoria para operações de INSERT, UPDATE e DELETE na tabela PRODUTOS,
              registrando todas as alterações em uma tabela de log com valores antigos e novos
              por coluna alterada.
    PROJETO: mssqlserver-solution-explorer    
 *
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER TRIGGER tr_Produtos_LogUID
ON PRODUTOS
WITH ENCRYPTION
FOR DELETE, INSERT, UPDATE
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
    -- conforme campos otimizados
    -- ============================================================
    SET @Deleted =
    (
        SELECT
              [ProCod]
            , [ProNom]
            , [ProFamCod]
            , [ProGrpCod]
            , [ProSubCod]
            , [ProSituacao]
            , [ProTip]
            , [ProTipPrc]
            , [ProCodArea]
            , [ProNomRed]
            , [ProNomEmbCompra]
            , [ProQtdEmbEstoque]
            , [ProNomEmbEstoque]
            , [ProEmbConv]
            , [ProVlrPeso]
            , [ProVlrPLiq]
            , [ProNomMarFab]
            , [ProVlrIpi]
            , [ProTipIcms]
            , [ProVlrISS]
            , [ProVlrMargen]
            , [ProVasCod]
            , [ProOpeCod]
            , [ProTipFrt]
            , [ProTipFun]
            , [ProTipDev]
            , [ProTipDepFrt]
            , [ProDiaVct]
            , [ProTipOrigem]
            , [ProTipTrb]
            , [ProDatInc]
            , [ProPerPis]
            , [ProPerCofins]
            , [ProTipNota]
            , [ProClaTox]
            , [ProDesPriAtivo]
            , [ProBasPisCofins]
            , [ProAtvFim]
            , [ProFlag1]
            , [ProFlag2]
            , [ProFlag3]
            , [ProFlag4]
            , [ProFlag5]
            , [ProFlag6]
            , [ProFlag7]
            , [ProFlag8]
            , [ProFlag9]
            , [ProFlag0]
            , [ProFlag10]
            , [ProFlag11]
            , [ProFlag12]
            , [ProFlag13]
            , [ProFlag14]
            , [ProFlag15]
            , [ProTipDem]
            , [ProTraCod]
            , [ProNomCie]
            , [ProAgrCod]
            , [ProVlrDes]
            , [ProNbmCod]
            , [ProMapa]
            , [ProCodFormu]
            , [ProConcen]
            , [ProSitTrbIpi]
            , [ProSitTrbPis]
            , [ProMarVlrAgr]
            , [ProNumOnu]
            , [ProNumRis]
            , [ProFlag16]
            , [ProFlag17]
            , [ProFlag18]
            , [ProFlag19]
            , [ProFlag20]
            , [ProCtaCod]
            , [ProCenCusCod]
            , [ProCodServ]
            , [GenCod]
            , [ProLocal]
            , [ProPerFundesa]
            , [ProFlag21]
            , [ProFlag22]
            , [ProFlag23]
            , [ProFlag24]
            , [ProFlag25]
            , [ProFlag26]
            , [ProFlag27]
            , [ProFlag28]
            , [ProFlag29]
            , [ProFlag30]
            , [ProUsuCod]
            , [ProIndCod]
            , [ProGruStCod]
            , [ProStTipPreco]
            , [ProMovFilCod]
            , [ProTipPvd]
            , [ProFlag31]
            , [ProFlag32]
            , [ProFlag33]
            , [ProFlag34]
            , [ProFlag35]
            , [ProCodEAN]
            , [ProCodTipi]
            , [TabTribCod]
            , [ProQtdEmbPCP]
            , [ProUndReferencial]
            , [ProFatConversao]
            , [ProQtdMinima]
            , [ProQtdMaxima]
            , [ProDatConCom]
            , [ProClaRecCod]
            , [ProFlag36]
            , [ProFlag37]
            , [ProFlag38]
            , [ProFlag39]
            , [ProFlag40]
            , [ProFlag41]
            , [ProFlag42]
            , [ProFlag43]
            , [ProFlag44]
            , [ProFlag45]
            , [ProFlag46]
            , [ProFlag47]
            , [ProFlag48]
            , [ProFlag49]
            , [ProFlag50]
            , [ProQtdEmbVenda]
            , [ProCalibre]
            , [ProNbmExCod]
            , [ProBarDis]
            , [ProBarDisplay]
            , [ProConvDisplay]
            , [TabNutCod]
            , [ProNomEmbTributavel]
            , [ProANPCod]
            , [ProPerBonDAP]
            , [ProCodAuxInt]
            , [ProTriAlqNac]
            , [ProTriAlqImp]
            , [TabConfPisCofCod]
            , [ProCodTroca]
            , [ProQtdLiberada]
            , [ProCompImp]
            , [ProPercMarVenInd]
            , [ProLogConferido]
            , [ProNorPalTipo]
            , [ProNorPalLastro]
            , [ProNorPalCamada]
            , [ProDadEmbAltura]
            , [ProDadEmbLargura]
            , [ProDadEmbComprimento]
            , [ProTipIncLeite]
            , [ProCodVas]
            , [ClaSerCod]
            , [RecCod]
            , [ProTabComCod]
            , [ProTabComposicao]
            , [ProRecomendacao]
            , [ProUmiMax]
            , [ProImpDesc]
            , [ProClasComercial]
            , [ProTipCalcImpureza]
            , [ProDAP]
            , [ProLimVlrFix]
            , [ProFlag51]
            , [ProFlgIntacta]
            , [SimilarId]
            , [ProRefCod]
            , [CodVinculado]
            , [ProFlag52]
            , [ProFlag60]
            , [ProFlag59]
            , [ProFlag58]
            , [ProFlag57]
            , [ProFlag56]
            , [ProFlag55]
            , [ProFlag54]
            , [ProFlag53]
            , [ProFlag61]
            , [ProCodUnificado]
            , [ProFlag62]
            , [ProFlag63]
            , [ProConLeite]
            , [ProCest]
            , [ProFlag64]
        FROM deleted
        FOR XML RAW, ROOT('Deleted')
    )

    -- ============================================================
    -- Coloca a tabela Inserted em uma variável XML, 
    -- conforme campos otimizados
    -- ============================================================
    SET @Inserted =
    (
        SELECT
              [ProCod]
            , [ProNom]
            , [ProFamCod]
            , [ProGrpCod]
            , [ProSubCod]
            , [ProSituacao]
            , [ProTip]
            , [ProTipPrc]
            , [ProCodArea]
            , [ProNomRed]
            , [ProNomEmbCompra]
            , [ProQtdEmbEstoque]
            , [ProNomEmbEstoque]
            , [ProEmbConv]
            , [ProVlrPeso]
            , [ProVlrPLiq]
            , [ProNomMarFab]
            , [ProVlrIpi]
            , [ProTipIcms]
            , [ProVlrISS]
            , [ProVlrMargen]
            , [ProVasCod]
            , [ProOpeCod]
            , [ProTipFrt]
            , [ProTipFun]
            , [ProTipDev]
            , [ProTipDepFrt]
            , [ProDiaVct]
            , [ProTipOrigem]
            , [ProTipTrb]
            , [ProDatInc]
            , [ProPerPis]
            , [ProPerCofins]
            , [ProTipNota]
            , [ProClaTox]
            , [ProDesPriAtivo]
            , [ProBasPisCofins]
            , [ProAtvFim]
            , [ProFlag1]
            , [ProFlag2]
            , [ProFlag3]
            , [ProFlag4]
            , [ProFlag5]
            , [ProFlag6]
            , [ProFlag7]
            , [ProFlag8]
            , [ProFlag9]
            , [ProFlag0]
            , [ProFlag10]
            , [ProFlag11]
            , [ProFlag12]
            , [ProFlag13]
            , [ProFlag14]
            , [ProFlag15]
            , [ProTipDem]
            , [ProTraCod]
            , [ProNomCie]
            , [ProAgrCod]
            , [ProVlrDes]
            , [ProNbmCod]
            , [ProMapa]
            , [ProCodFormu]
            , [ProConcen]
            , [ProSitTrbIpi]
            , [ProSitTrbPis]
            , [ProMarVlrAgr]
            , [ProNumOnu]
            , [ProNumRis]
            , [ProFlag16]
            , [ProFlag17]
            , [ProFlag18]
            , [ProFlag19]
            , [ProFlag20]
            , [ProCtaCod]
            , [ProCenCusCod]
            , [ProCodServ]
            , [GenCod]
            , [ProLocal]
            , [ProPerFundesa]
            , [ProFlag21]
            , [ProFlag22]
            , [ProFlag23]
            , [ProFlag24]
            , [ProFlag25]
            , [ProFlag26]
            , [ProFlag27]
            , [ProFlag28]
            , [ProFlag29]
            , [ProFlag30]
            , [ProUsuCod]
            , [ProIndCod]
            , [ProGruStCod]
            , [ProStTipPreco]
            , [ProMovFilCod]
            , [ProTipPvd]
            , [ProFlag31]
            , [ProFlag32]
            , [ProFlag33]
            , [ProFlag34]
            , [ProFlag35]
            , [ProCodEAN]
            , [ProCodTipi]
            , [TabTribCod]
            , [ProQtdEmbPCP]
            , [ProUndReferencial]
            , [ProFatConversao]
            , [ProQtdMinima]
            , [ProQtdMaxima]
            , [ProDatConCom]
            , [ProClaRecCod]
            , [ProFlag36]
            , [ProFlag37]
            , [ProFlag38]
            , [ProFlag39]
            , [ProFlag40]
            , [ProFlag41]
            , [ProFlag42]
            , [ProFlag43]
            , [ProFlag44]
            , [ProFlag45]
            , [ProFlag46]
            , [ProFlag47]
            , [ProFlag48]
            , [ProFlag49]
            , [ProFlag50]
            , [ProQtdEmbVenda]
            , [ProCalibre]
            , [ProNbmExCod]
            , [ProBarDis]
            , [ProBarDisplay]
            , [ProConvDisplay]
            , [TabNutCod]
            , [ProNomEmbTributavel]
            , [ProANPCod]
            , [ProPerBonDAP]
            , [ProCodAuxInt]
            , [ProTriAlqNac]
            , [ProTriAlqImp]
            , [TabConfPisCofCod]
            , [ProCodTroca]
            , [ProQtdLiberada]
            , [ProCompImp]
            , [ProPercMarVenInd]
            , [ProLogConferido]
            , [ProNorPalTipo]
            , [ProNorPalLastro]
            , [ProNorPalCamada]
            , [ProDadEmbAltura]
            , [ProDadEmbLargura]
            , [ProDadEmbComprimento]
            , [ProTipIncLeite]
            , [ProCodVas]
            , [ClaSerCod]
            , [RecCod]
            , [ProTabComCod]
            , [ProTabComposicao]
            , [ProRecomendacao]
            , [ProUmiMax]
            , [ProImpDesc]
            , [ProClasComercial]
            , [ProTipCalcImpureza]
            , [ProDAP]
            , [ProLimVlrFix]
            , [ProFlag51]
            , [ProFlgIntacta]
            , [SimilarId]
            , [ProRefCod]
            , [CodVinculado]
            , [ProFlag52]
            , [ProFlag60]
            , [ProFlag59]
            , [ProFlag58]
            , [ProFlag57]
            , [ProFlag56]
            , [ProFlag55]
            , [ProFlag54]
            , [ProFlag53]
            , [ProFlag61]
            , [ProCodUnificado]
            , [ProFlag62]
            , [ProFlag63]
            , [ProConLeite]
            , [ProCest]
            , [ProFlag64]
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

            INSERT INTO DBA_PerformanceHub.LogErp.ProdutosLogDML
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
                , 'PRODUTOS'
                , @Action
                , ProCod
                , ISNULL(@NomeCol, '')
                , ISNULL(
                  (
                      SELECT E.e.value('(/Deleted/row[@ProCod = sql:column(INS.Procod)]/@Col)[1]', 'varchar(100)')
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

            INSERT INTO DBA_PerformanceHub.LogErp.ProdutosLogDML
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
                , X.UsuCod
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
                    , 'PRODUTOS' AS TableName
                    , @Action AS TypeSQL
                    , ProCod AS UsuCod
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
-- registra os dados DML da tabela PRODUTOS
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE LogErp.ProdutosLogDML
(
      LogId                      INT NOT NULL IDENTITY(1, 1)
    , DateDML                    DATETIME DEFAULT GETDATE()
    , DatabaseUser               VARCHAR(100) DEFAULT USER_NAME()
    , LoginUser                  VARCHAR(100) DEFAULT SUSER_NAME()
    , LoginUserSQLTransaction    VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
    , ProgramName                VARCHAR(100) DEFAULT PROGRAM_NAME()
    , HostName                   VARCHAR(100) DEFAULT HOST_NAME()
    , TableName                  VARCHAR(10) DEFAULT 'PRODUTOS'
    , TypeSQL                    CHAR(1)
    , Procod                     INT NOT NULL
    , ColumnUpdate               SYSNAME
    , ValueOld                   VARCHAR(100) DEFAULT ''
    , ValueNew                   VARCHAR(100) DEFAULT ''
    , CONSTRAINT PK_ProdutosId PRIMARY KEY CLUSTERED (LogId ASC)
    , CONSTRAINT CK_TableNameProdutos CHECK (TableName LIKE 'PRODUTOS')
    , CONSTRAINT CK_TypeSQLProdutos CHECK (TypeSQL IN ('D', 'I', 'U'))
)
GO

-- ============================================================
-- Procedure de retenção de dados - ProdutosLogDML
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE LogErp.sp_DeleteLogProdutos
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
                FROM DBA_PerformanceHub.LogErp.ProdutosLogDML AS t1
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
                SELECT CAST(DATEADD(DAY, 1, ((SELECT MIN(t1.DateDML) FROM DBA_PerformanceHub.LogErp.ProdutosLogDML AS t1))) AS DATE)
            )

            DELETE FROM DBA_PerformanceHub.LogErp.ProdutosLogDML
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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteLogProdutos]:<b> <br>
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
