/*
 *
    OBJETIVO: Trigger de auditoria DML na tabela CADUSUARIOS, registrando inserções,
              atualizações e exclusões por coluna na tabela CadusuariosLogDML,
              além da criação da tabela de log e da rotina de retenção dos dados.
    PROJETO: mssqlserver-solution-explorer
 *
 */
USE [YOUR_DATABASE]
GO

CREATE OR ALTER TRIGGER [dbo].[tr_Cadusuarios_LogUID]
ON [dbo].[CADUSUARIOS]
WITH ENCRYPTION
FOR UPDATE, DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @contador INT
          , @action CHAR(15)
          , @Col INT
          , @qCols INT
          , @NomeCol VARCHAR(100)
          , @bitVerificador INT
          , @Pot INT

    DECLARE @Inserted XML
          , @InsertedTMP XML

    DECLARE @Deleted XML
          , @DeletedTMP XML

    SET @Col = 0

    -- Conta quantas colunas existem na tabela contemplada pela trigger
    SET @qCols =
    (
        SELECT COUNT(*)
        FROM sys.columns
        WHERE object_id =
        (
            SELECT parent_id
            FROM sys.triggers
            WHERE object_id = @@PROCID
        )
    )

    -- Coloca a tabela Deleted em uma variável XML
    -- Otimizado para não trazer a coluna 'UsuUltEntrada' (27-07-2016)
    SET @Deleted =
    (
        SELECT
            UsuCod
          , EmpCod
          , UsuFilCod
          , UsuTraCod
          , UsuSenha
          , UsuFlag1
          , UsuFlag2
          , UsuFlag3
          , UsuFlag4
          , UsuFlag5
          , UsuFlag6
          , UsuFlag7
          , UsuFlag8
          , UsuFlag9
          , UsuFlag0
          , UsuFlag10
          , UsuFlag11
          , UsuFlag12
          , UsuFlag13
          , UsuFlag14
          , UsuFlag15
          , UsuEmail
          , UsuConCod
          , UsuHisPreCod
          , UsuSenLiberacaoLimite
        --, UsuWorkstation 12/06/2017
          , UsuInativo
          , UsuFlag20
          , UsuFlag19
          , UsuFlag18
          , UsuFlag17
          , UsuFlag16
          , UsuFlag40
          , UsuFlag39
          , UsuFlag38
          , UsuFlag37
          , UsuFlag36
          , UsuFlag35
          , UsuFlag34
          , UsuFlag33
          , UsuFlag32
          , UsuFlag31
          , UsuFlag30
          , UsuFlag29
          , UsuFlag28
          , UsuFlag27
          , UsuFlag26
          , UsuFlag25
          , UsuFlag24
          , UsuFlag23
          , UsuFlag22
          , UsuFlag21
          , UsuFlag41
          , UsuFlag42
          , UsuLimLibTit
          , UsuTitAcessoRestrito
          , UsuFlagPesagem
          , UsuVerCodigo
          , UsuTipPesagem
          , UsuLimTraCredito
          , UsuSetCod
          , UsuSecCod
          , UsuCenCod
          , UsuLocBalRod
          , UsuFlag43
          , UsuDirTmp
          , UsuFlag44
          , UsuEtiZebraA
          , UsuEtiZebraB
          , UsuFlag45
          , UsuFlag46
          , UsuFlag47
          , UsuFlag48
          , UsuFlag50
          , UsuFlag49
          , UsuFlag51
          , UsuDescLim
          , UsuFlag52
          , UsuDashboard
          , UsuTipoAcesso
          , UsuAcreCredito
          , UsuFlag54
          , UsuDescValorNom
          , UsuFlag53
          , UsuFlag55
          , UsuFlag56
          , UsuFlag57
          , UsuFlag58
          , UsuFlag60
          , UsuFlag59
          , UsuFlag61
          , UsuFlag70
          , UsuFlag69
          , UsuFlag68
          , UsuFlag67
          , UsuFlag66
          , UsuFlag65
          , UsuFlag64
          , UsuFlag63
          , UsuFlag62
        FROM deleted
        FOR XML RAW, ROOT('Deleted')
    )

    -- Coloca a tabela Inserted em uma variável XML
    -- Otimizado para não trazer a coluna 'UsuUltEntrada' (27-07-2016)
    SET @Inserted =
    (
        SELECT
            UsuCod
          , EmpCod
          , UsuFilCod
          , UsuTraCod
          , UsuSenha
          , UsuFlag1
          , UsuFlag2
          , UsuFlag3
          , UsuFlag4
          , UsuFlag5
          , UsuFlag6
          , UsuFlag7
          , UsuFlag8
          , UsuFlag9
          , UsuFlag0
          , UsuFlag10
          , UsuFlag11
          , UsuFlag12
          , UsuFlag13
          , UsuFlag14
          , UsuFlag15
          , UsuEmail
          , UsuConCod
          , UsuHisPreCod
          , UsuSenLiberacaoLimite
        --, UsuWorkstation 12/06/2017
          , UsuInativo
          , UsuFlag20
          , UsuFlag19
          , UsuFlag18
          , UsuFlag17
          , UsuFlag16
          , UsuFlag40
          , UsuFlag39
          , UsuFlag38
          , UsuFlag37
          , UsuFlag36
          , UsuFlag35
          , UsuFlag34
          , UsuFlag33
          , UsuFlag32
          , UsuFlag31
          , UsuFlag30
          , UsuFlag29
          , UsuFlag28
          , UsuFlag27
          , UsuFlag26
          , UsuFlag25
          , UsuFlag24
          , UsuFlag23
          , UsuFlag22
          , UsuFlag21
          , UsuFlag41
          , UsuFlag42
          , UsuLimLibTit
          , UsuTitAcessoRestrito
          , UsuFlagPesagem
          , UsuVerCodigo
          , UsuTipPesagem
          , UsuLimTraCredito
          , UsuSetCod
          , UsuSecCod
          , UsuCenCod
          , UsuLocBalRod
          , UsuFlag43
          , UsuDirTmp
          , UsuFlag44
          , UsuEtiZebraA
          , UsuEtiZebraB
          , UsuFlag45
          , UsuFlag46
          , UsuFlag47
          , UsuFlag48
          , UsuFlag50
          , UsuFlag49
          , UsuFlag51
          , UsuDescLim
          , UsuFlag52
          , UsuDashboard
          , UsuTipoAcesso
          , UsuAcreCredito
          , UsuFlag54
          , UsuDescValorNom
          , UsuFlag53
          , UsuFlag55
          , UsuFlag56
          , UsuFlag57
          , UsuFlag58
          , UsuFlag60
          , UsuFlag59
          , UsuFlag61
          , UsuFlag70
          , UsuFlag69
          , UsuFlag68
          , UsuFlag67
          , UsuFlag66
          , UsuFlag65
          , UsuFlag64
          , UsuFlag63
          , UsuFlag62
        FROM inserted
        FOR XML RAW, ROOT('Inserted')
    )

    IF NOT EXISTS
    (
        SELECT TOP 1 NULL
        FROM inserted
    ) -- deleted
    BEGIN
        SELECT @action = 'D'
        FROM deleted

        -- Auditoria de exclusão, coluna a coluna
        WHILE (@Col < @qCols)
        BEGIN
            SET @Col = @Col + 1
            SET @Pot = (@Col - 1) % 8 + 1
            SET @Pot = POWER(2, @Pot - 1)
            SET @bitVerificador = ((@Col - 1) / 8) + 1

            SET @NomeCol =
            (
                SELECT name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT Parent_ID
                    FROM sys.triggers
                    WHERE object_id = @@PROCID
                )
                AND column_id = @Col
            )

            -- Substitui a TAG no XML da DELETED e faz a extração dos dados
            SET @DeletedTMP = REPLACE(CAST(@Deleted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            INSERT INTO DBA_PerformanceHub.LogErp.CadusuariosLogDML
            (
                DateDML
              , DatabaseUser
              , LoginUser
              , LoginUserSQLTransaction
              , ProgramName
              , HostName
              , TableName
              , TypeSQL
              , UsuCod
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
              , 'CADUSUARIOS'
              , @action
              , UsuCod
              , ISNULL(@NomeCol, '')
              , ISNULL
                (
                    (
                        SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                        FROM @DeletedTMP.nodes('.') AS E(e)
                    )
                  , ''
                ) AS ValueOld
            FROM deleted AS Ins
        END
    END
    ELSE IF NOT EXISTS
    (
        SELECT TOP 1 NULL
        FROM deleted
    ) -- inserted
    BEGIN
        SELECT @action = 'I'
        FROM inserted
    END
    ELSE
    BEGIN
        SELECT @action = 'U'
        FROM deleted
    END

    -- Auditoria de colunas atualizadas
    WHILE (@Col < @qCols)
    BEGIN
        SET @Col = @Col + 1
        SET @Pot = (@Col - 1) % 8 + 1
        SET @Pot = POWER(2, @Pot - 1)
        SET @bitVerificador = ((@Col - 1) / 8) + 1

        IF (SUBSTRING(COLUMNS_UPDATED(), @bitVerificador, 1) & @Pot > 0)
        BEGIN
            SET @NomeCol =
            (
                SELECT name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT parent_id
                    FROM sys.triggers
                    WHERE object_id = @@PROCID
                )
                AND column_id = @Col
            )

            -- Substitui a TAG no XML da DELETED e faz a extração dos dados
            SET @DeletedTMP = REPLACE(CAST(@Deleted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            -- Substitui a TAG no XML da INSERTED e faz a extração dos dados
            SET @InsertedTMP = REPLACE(CAST(@Inserted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            INSERT INTO DBA_PerformanceHub.LogErp.CadusuariosLogDML
            (
                DateDML
              , DatabaseUser
              , LoginUser
              , LoginUserSQLTransaction
              , ProgramName
              , HostName
              , TableName
              , TypeSQL
              , UsuCod
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
                  , 'CADUSUARIOS' AS TableName
                  , @action AS TypeSQL
                  , UsuCod AS UsuCod
                  , ISNULL(@NomeCol, '') AS ColumnUpdate
                  , ISNULL
                    (
                        (
                            SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                            FROM @DeletedTMP.nodes('.') AS E(e)
                        )
                      , ''
                    ) AS ValueOld
                  , ISNULL
                    (
                        (
                            SELECT E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                            FROM @InsertedTMP.nodes('.') AS E(e)
                        )
                      , ''
                    ) AS ValueNew
                FROM inserted AS Ins
            ) AS X
            WHERE X.ValueNew <> X.ValueOld
        END
    END
END
GO

-- ============================================================
-- Tabela de logs DML
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE LogErp.CadusuariosLogDML
(
    LogId INT NOT NULL IDENTITY(1,1)
  , DateDML DATETIME DEFAULT GETDATE()
  , DatabaseUser VARCHAR(100) DEFAULT USER_NAME()
  , LoginUser VARCHAR(100) DEFAULT SUSER_NAME()
  , LoginUserSQLTransaction VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
  , ProgramName VARCHAR(100) DEFAULT PROGRAM_NAME()
  , HostName VARCHAR(100) DEFAULT HOST_NAME()
  , TableName VARCHAR(30) DEFAULT 'CADUSUARIOS'
  , TypeSQL CHAR(1)
  , UsuCod CHAR(25) NOT NULL DEFAULT ''
  , ColumnUpdate SYSNAME -- tipos de dados corresponde ao varchar(128) e já seta not null também
  , ValueOld VARCHAR(100) DEFAULT ''
  , ValueNew VARCHAR(100) DEFAULT ''
  , CONSTRAINT PK_LogId PRIMARY KEY (LogId)
  , CONSTRAINT CK_TableName CHECK (TableName LIKE 'CADUSUARIOS')
  , CONSTRAINT CK_TypeSQL CHECK (TypeSQL IN ('D', 'I', 'U'))
);

-- ============================================================
-- Retenção dos dados
-- ============================================================
USE DBA_PerformanceHub
GO

-- ============================================================
-- Procedure LogErp.sp_DeleteLogCadusuarios
-- ============================================================
CREATE OR ALTER PROCEDURE LogErp.sp_DeleteLogCadusuarios
(
    @qtdadeManterDias INT = 365 -- Quantidade de dias para manter
)
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        -- Contagem de dias existentes no log
        DECLARE @qtdadeDias INT
              , @dataMin DATE

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Registros)
            FROM
            (
                SELECT COUNT(*) AS [Registros]
                FROM DBA_PerformanceHub.LogErp.CadusuariosLogDML AS t1
                GROUP BY CAST(t1.DateDML AS DATE)
            ) AS x
        )

        -- Loop de exclusão dos dias excedentes
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT CAST(DATEADD(DAY, 1,
                (
                    SELECT MIN(t1.DateDML)
                    FROM DBA_PerformanceHub.LogErp.CadusuariosLogDML AS t1
                )) AS DATE)
            )

            DELETE FROM DBA_PerformanceHub.LogErp.CadusuariosLogDML
            WHERE DateDML < @dataMin

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
          <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteLogCadusuarios]:<b> <br>
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
END
GO
