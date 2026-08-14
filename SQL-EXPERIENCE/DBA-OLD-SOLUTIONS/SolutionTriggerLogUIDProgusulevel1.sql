/*
 *
    OBJETIVO: Trigger de auditoria para operações de INSERT e DELETE na tabela PROGUSULEVEL1,
              registrando permissões de usuários em programas em uma tabela de log.
    PROJETO: mssqlserver-solution-explorer
 * 
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER TRIGGER [dbo].[tr_ProgUsulevel1_LogID]
ON [dbo].[PROGUSULEVEL1]
WITH ENCRYPTION
FOR DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Tp_Alteracao CHAR(1)

    -- ============================================================
    -- Processamento para operação de DELETE
    -- ============================================================
    IF NOT EXISTS (SELECT TOP 1 NULL FROM inserted)
    BEGIN
        SET @Tp_Alteracao = 'D'

        INSERT INTO DBA_PerformanceHub.LogErp.ProgUsuLevel1LogDML
        (
              DateDML
            , DatabaseUser
            , LoginUser
            , LoginUserSQLTransaction
            , TypeSQL
            , ProgramName
            , HostName
            , TableName
            , UsuCod
            , PrgCod1
        )
        SELECT
              GETDATE()
            , USER_NAME()
            , SUSER_NAME()
            , ORIGINAL_LOGIN()
            , @Tp_Alteracao
            , PROGRAM_NAME()
            , HOST_NAME()
            , 'PROGUSULEVEL1'
            , UsuCod
            , PrgCod1
        FROM deleted
    END
    -- ============================================================
    -- Processamento para operação de INSERT
    -- ============================================================
    ELSE IF NOT EXISTS (SELECT TOP 1 NULL FROM deleted)
    BEGIN
        SET @Tp_Alteracao = 'I'

        INSERT INTO DBA_PerformanceHub.LogErp.ProgUsuLevel1LogDML
        (
              DateDML
            , DatabaseUser
            , LoginUser
            , LoginUserSQLTransaction
            , TypeSQL
            , ProgramName
            , HostName
            , TableName
            , UsuCod
            , PrgCod1
        )
        SELECT
              GETDATE()
            , USER_NAME()
            , SUSER_NAME()
            , ORIGINAL_LOGIN()
            , @Tp_Alteracao
            , PROGRAM_NAME()
            , HOST_NAME()
            , 'PROGUSULEVEL1'
            , UsuCod
            , PrgCod1
        FROM inserted
    END
END
GO

-- ============================================================
-- Tabela de logs
-- Obs.: o que defini se tem acesso ou não é o TypeSQL (I, D)
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE LogErp.ProgUsuLevel1LogDML
(
      LogId                      INT NOT NULL IDENTITY(1, 1)
    , DateDML                    DATETIME DEFAULT GETDATE()
    , DatabaseUser               VARCHAR(100) DEFAULT USER_NAME()
    , LoginUser                  VARCHAR(100) DEFAULT SUSER_NAME()
    , LoginUserSQLTransaction    VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
    , TypeSQL                    CHAR(1)
    , ProgramName                VARCHAR(100) DEFAULT PROGRAM_NAME()
    , HostName                   VARCHAR(100) DEFAULT HOST_NAME()
    , TableName                  VARCHAR(30) DEFAULT 'PROGUSULEVEL1'
    , UsuCod                     CHAR(25) NOT NULL DEFAULT ''
    , PrgCod1                    VARCHAR(100) DEFAULT ''
    , CONSTRAINT PK_LogIdProgUsu PRIMARY KEY CLUSTERED (LogId ASC)
    , CONSTRAINT CK_TableNameProgusu CHECK (TableName LIKE 'PROGUSULEVEL1')
    , CONSTRAINT CK_TypeSQLProgUsu CHECK (TypeSQL IN ('D', 'I'))
)
GO

-- ============================================================
-- Procedure de retenção de dados - ProgUsuLevel1LogDML
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE LogErp.sp_DeleteLogProgUsuLevel1
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
                FROM DBA_PerformanceHub.LogErp.ProgUsuLevel1LogDML AS t1
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
                SELECT CAST(DATEADD(DAY, 1, ((SELECT MIN(t1.DateDML) FROM DBA_PerformanceHub.LogErp.ProgUsuLevel1LogDML AS t1))) AS DATE)
            )

            DELETE FROM DBA_PerformanceHub.LogErp.ProgUsuLevel1LogDML
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
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteLogProgUsuLevel1]:<b> <br>
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
