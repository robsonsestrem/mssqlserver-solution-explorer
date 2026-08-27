/*
 *
    OBJETIVO: Trigger de auditoria para operações de INSERT, UPDATE e DELETE
              na tabela CADUSUARIOS, registrando todas as alterações em
              uma tabela de log com valores antigos e novos por coluna alterada.

              *** Cuidado! ***
              Essa solução pode gerar muitos logs 
              dependendo da frequência de DML no sistema.
    PROJETO: mssqlserver-solution-explorer
 * 
 */
-- ============================================================
-- Trigger de Log DML para CADUSUARIOS 
-- Versão 1
-- ============================================================
USE YOUR_DATABASE
GO

CREATE TRIGGER tr_cadusuarios_LogUID
ON CADUSUARIOS
FOR UPDATE, DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @CampoChave       CHAR(25)
          , @action           CHAR(1)
          , @Col              INT
          , @qCols            INT
          , @NomeCol          VARCHAR(100)
          , @bitVerificador   INT
          , @Pot              INT

    SET @Col = 0

    -- ============================================================
    -- Conta quantas colunas existem na 
    -- tabela contemplada pela Trigger
    -- ============================================================
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
    -- Coloca a tabela Deleted em uma variável XML
    -- ============================================================
    DECLARE @Deleted    XML
          , @DeletedTMP XML

    SET @Deleted = (SELECT * FROM deleted FOR XML RAW, ROOT('Deleted'))

    -- ============================================================
    -- Coloca a tabela Inserted em uma variável XML
    -- ============================================================
    DECLARE @Inserted    XML
          , @InsertedTMP XML

    SET @Inserted = (SELECT * FROM inserted FOR XML RAW, ROOT('Inserted'))

    -- ============================================================
    -- Determina o tipo de operação (INSERT, UPDATE ou DELETE)
    -- ============================================================
    IF COLUMNS_UPDATED() > 0
    BEGIN
        IF EXISTS (SELECT * FROM deleted)
            SET @action = 'U'
        ELSE
            SET @action = 'I'
    END
    ELSE
    BEGIN
        SET @action = 'D'
    END

    -- ============================================================
    -- Processamento para operação de DELETE
    -- ============================================================
    IF @Action = 'D'
    BEGIN
        INSERT INTO CadusuariosLogDML
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
              GETDATE()
            , USER_NAME()
            , SUSER_NAME()
            , ORIGINAL_LOGIN()
            , PROGRAM_NAME()
            , HOST_NAME()
            , 'CADUSUARIOS'
            , @Action
            , Usucod
            , 'SystemUpdate'
            , 'Removido'
            , ''
        FROM deleted
    END
    ELSE
    BEGIN
        -- ============================================================
        -- Processamento para operações de INSERT e UPDATE
        -- ============================================================
        IF (@Action = 'I' OR @Action = 'U')
        BEGIN
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

                    INSERT INTO CadusuariosLogDML
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
                          GETDATE()
                        , USER_NAME()
                        , SUSER_NAME()
                        , ORIGINAL_LOGIN()
                        , PROGRAM_NAME()
                        , HOST_NAME()
                        , 'CADUSUARIOS'
                        , @Action
                        , UsuCod
                        , ISNULL(@NomeCol, '')
                        , ISNULL(
                          (
                              SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                              FROM @DeletedTMP.nodes('.') AS E(e)
                          ), '') AS ValueOld
                        , ISNULL(
                          (
                              SELECT E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                              FROM @InsertedTMP.nodes('.') AS E(e)
                          ), '') AS ValueNew
                    FROM inserted AS Ins
                END
            END
        END
    END
END
GO


-- ============================================================
-- Trigger de Log DML para CADUSUARIOS 
-- Versão 2 - com registro por coluna no DELETE)
-- ============================================================
CREATE TRIGGER [dbo].[tr_Cadusuarios_LogUID]
ON CADUSUARIOS
FOR UPDATE, DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @CampoChave       CHAR(25)
          , @action           CHAR(1)
          , @Col              INT
          , @qCols            INT
          , @NomeCol          NVARCHAR(MAX)
          , @bitVerificador   INT
          , @Pot              INT

    SET @Col = 0

    -- ============================================================
    -- Conta quantas colunas existem na 
    -- tabela contemplada pela Trigger
    -- ============================================================
    SET @qCols =
    (
        SELECT COUNT(*)
        FROM sys.columns
        WHERE object_id =
        (
            SELECT Parent_ID
            FROM sys.triggers
            WHERE object_id = @@procid
        )
    )

    -- ============================================================
    -- Coloca a tabela Deleted em uma variável XML
    -- ============================================================
    DECLARE @Deleted    XML
          , @DeletedTMP XML

    SET @Deleted = (SELECT * FROM Deleted FOR XML RAW, ROOT('Deleted'))

    -- ============================================================
    -- Coloca a tabela Inserted em uma variável XML
    -- ============================================================
    DECLARE @Inserted    XML
          , @InsertedTMP XML

    SET @Inserted = (SELECT * FROM Inserted FOR XML RAW, ROOT('Inserted'))

    -- ============================================================
    -- Determina o tipo de operação (INSERT, UPDATE ou DELETE)
    -- ============================================================
    IF COLUMNS_UPDATED() > 0
    BEGIN
        IF EXISTS (SELECT * FROM DELETED)
            SET @action = 'U'
        ELSE
            SET @action = 'I'
    END
    ELSE
    BEGIN
        SET @action = 'D'
    END

    -- ============================================================
    -- Processamento para operação de DELETE (com registro por coluna)
    -- ============================================================
    IF @Action = 'D'
    BEGIN
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

            INSERT INTO CadusuariosLogDML
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
                , @Action
                , UsuCod
                , ISNULL(@NomeCol, '')
                , ISNULL(
                  (
                      SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                      FROM @DeletedTMP.nodes('.') AS E(e)
                  ), '') AS ValueOld
            FROM deleted AS Ins
        END
    END
    ELSE
    BEGIN
        -- ============================================================
        -- Processamento para operações de INSERT e UPDATE
        -- ============================================================
        IF (@Action = 'I' OR @Action = 'U')
        BEGIN
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

                    -- ============================================================
                    -- Substitui a TAG no XML da INSERTED e faz a extração dos dados
                    -- ============================================================
                    SET @InsertedTMP = REPLACE(CAST(@Inserted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

                    INSERT INTO CadusuariosLogDML
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
                          GETDATE()
                        , USER_NAME()
                        , SUSER_NAME()
                        , ORIGINAL_LOGIN()
                        , PROGRAM_NAME()
                        , HOST_NAME()
                        , 'CADUSUARIOS'
                        , @Action
                        , UsuCod
                        , ISNULL(@NomeCol, '')
                        , ISNULL(
                          (
                              SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                              FROM @DeletedTMP.nodes('.') AS E(e)
                          ), '') AS ValueOld
                        , ISNULL(
                          (
                              SELECT E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                              FROM @InsertedTMP.nodes('.') AS E(e)
                          ), '') AS ValueNew
                    FROM inserted AS Ins
                END
            END
        END
    END
END
GO


-- ============================================================
-- Trigger de Log DML para CADUSUARIOS 
-- Versão 3 - com filtro de valores alterados
-- ============================================================
USE [YOUR_DATABASE]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TRIGGER [dbo].[tr_cadusuarios_LogUID]
ON [dbo].[CADUSUARIOS]
FOR UPDATE, DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @CampoChave       CHAR(25)
          , @action           CHAR(1)
          , @Col              INT
          , @qCols            INT
          , @NomeCol          VARCHAR(100)
          , @bitVerificador   INT
          , @Pot              INT

    SET @Col = 0

    -- ============================================================
    -- Conta quantas colunas existem na 
    -- tabela contemplada pela Trigger
    -- ============================================================
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
    -- Coloca a tabela Deleted em uma variável XML
    -- ============================================================
    DECLARE @Deleted    XML
          , @DeletedTMP XML

    SET @Deleted = (SELECT * FROM deleted FOR XML RAW, ROOT('Deleted'))

    -- ============================================================
    -- Coloca a tabela Inserted em uma variável XML
    -- ============================================================
    DECLARE @Inserted    XML
          , @InsertedTMP XML

    SET @Inserted = (SELECT * FROM inserted FOR XML RAW, ROOT('Inserted'))

    -- ============================================================
    -- Determina o tipo de operação (INSERT, UPDATE ou DELETE)
    -- ============================================================
    IF COLUMNS_UPDATED() > 0
    BEGIN
        IF EXISTS (SELECT * FROM deleted)
            SET @action = 'U'
        ELSE
            SET @action = 'I'
    END
    ELSE
    BEGIN
        SET @action = 'D'
    END

    -- ============================================================
    -- Processamento para operação de DELETE
    -- ============================================================
    IF @Action = 'D'
    BEGIN
        INSERT INTO CadusuariosLogDML
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
              GETDATE()
            , USER_NAME()
            , SUSER_NAME()
            , ORIGINAL_LOGIN()
            , PROGRAM_NAME()
            , HOST_NAME()
            , 'CADUSUARIOS'
            , @Action
            , Usucod
            , 'SystemUpdate'
            , 'Removido'
            , ''
        FROM deleted
    END
    ELSE
    BEGIN
        -- ============================================================
        -- Processamento para operações de INSERT e UPDATE
        -- ============================================================
        IF (@Action = 'I' OR @Action = 'U')
        BEGIN
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

                    INSERT INTO CadusuariosLogDML
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
                            , @Action AS TypeSQL
                            , UsuCod AS UsuCod
                            , ISNULL(@NomeCol, '') AS ColumnUpdate
                            , ISNULL(
                              (
                                  SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                                  FROM @DeletedTMP.nodes('.') AS E(e)
                              ), '') AS ValueOld
                            , ISNULL(
                              (
                                  SELECT E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)')
                                  FROM @InsertedTMP.nodes('.') AS E(e)
                              ), '') AS ValueNew
                        FROM inserted AS Ins
                    ) AS X
                    WHERE X.ValueNew <> X.ValueOld
                END
            END
        END
    END
END
GO


-- ============================================================
-- Tabela de LOGS
-- ============================================================
USE YOUR_DATABASE
GO

CREATE TABLE CadusuariosLogDML
(
      LogId                      INT NOT NULL IDENTITY(1, 1)
    , DateDML                    DATETIME DEFAULT GETDATE()
    , DatabaseUser               VARCHAR(100) DEFAULT USER_NAME()
    , LoginUser                  VARCHAR(100) DEFAULT SUSER_NAME()
    , LoginUserSQLTransaction    VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
    , ProgramName                VARCHAR(100) DEFAULT PROGRAM_NAME()
    , HostName                   VARCHAR(100) DEFAULT HOST_NAME()
    , TableName                  VARCHAR(30) DEFAULT 'CADUSUARIOS'
    , TypeSQL                    CHAR(1)
    , UsuCod                     CHAR(25) NOT NULL DEFAULT ''
    , ColumnUpdate               SYSNAME
    , ValueOld                   VARCHAR(100) DEFAULT ''
    , ValueNew                   VARCHAR(100) DEFAULT ''
    , CONSTRAINT PK_LogId PRIMARY KEY CLUSTERED (LogId ASC)
    , CONSTRAINT CK_TableName CHECK (TableName LIKE 'CADUSUARIOS')
    , CONSTRAINT CK_TypeSQL CHECK (TypeSQL IN ('D', 'I', 'U'))
)
GO
