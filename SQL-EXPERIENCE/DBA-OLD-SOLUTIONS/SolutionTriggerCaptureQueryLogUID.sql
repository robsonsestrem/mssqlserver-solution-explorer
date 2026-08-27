/*
 *
    OBJETIVO: Soluções de trigger para captura da query executada em alterações
              na tabela CADUSUARIOS, registrando operações DML e comando no log.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/pt-br/sql/t-sql/statements/create-trigger-transact-sql
 *  https://learn.microsoft.com/pt-br/sql/t-sql/statements/dbcc-inputbuffer-transact-sql
 */
USE [YOUR_DATABASE]
GO

-- ============================================================
-- Trigger tr_CapturaQuery_LogUID
-- Captura a query da sessão atual 
-- via DBCC INPUTBUFFER e registra DML.
-- ============================================================
CREATE OR ALTER TRIGGER [dbo].[tr_CapturaQuery_LogUID]
ON [dbo].[CADUSUARIOS]
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @Action CHAR(1)

    -- Cria tabela temporária para receber o resultado do DBCC INPUTBUFFER
    CREATE TABLE #log
    (
        eventtype VARCHAR(MAX)
      , parameters INT
      , text VARCHAR(MAX)
    )

    INSERT INTO #log
    EXEC('DBCC INPUTBUFFER(@@SPID)')

    -- Define o tipo de operação DML com base nas tabelas inserted e deleted
    IF COLUMNS_UPDATED() > 0 -- insert or update
    BEGIN
        IF EXISTS
        (
            SELECT *
            FROM DELETED
        ) -- update
        BEGIN
            SET @Action = 'U'
        END
        ELSE
        BEGIN
            SET @Action = 'I'
        END
    END
    ELSE -- delete
    BEGIN
        SET @Action = 'D'
    END

    -- Registro de exclusão
    IF @Action = 'D'
    BEGIN
        INSERT INTO dbo.CadusuariosLogDML
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
          , Query
        )
        SELECT
            GETDATE()
          , USER_NAME()
          , SUSER_NAME()
          , ORIGINAL_LOGIN()
          , @Action
          , PROGRAM_NAME()
          , HOST_NAME()
          , 'CADUSUARIOS'
          , UsuCod
          , (
                SELECT text
                FROM #log
            )
        FROM deleted
    END
    ELSE
    BEGIN
        -- Registro de inserção ou atualização
        IF (@Action = 'I' OR @Action = 'U')
        BEGIN
            INSERT INTO dbo.CadusuariosLogDML
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
              , Query
            )
            SELECT
                GETDATE()
              , USER_NAME()
              , SUSER_NAME()
              , ORIGINAL_LOGIN()
              , @Action
              , PROGRAM_NAME()
              , HOST_NAME()
              , 'CADUSUARIOS'
              , UsuCod
              , (
                    SELECT text
                    FROM #log
                )
            FROM inserted
        END
    END
END
GO


-- ============================================================
-- Trigger tr_CapturaQuery_LogUID2
-- Versão alternativa que usa DMVs 
-- para obter a query e o horário da sessão.
-- ============================================================
CREATE OR ALTER TRIGGER tr_CapturaQuery_LogUID2
ON CADUSUARIOS
FOR UPDATE, DELETE, INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @CampoChave CHAR(25)
          , @Tp_Alteracao CHAR(1)

    -- Cria tabela temporária para receber o resultado do DBCC INPUTBUFFER
    CREATE TABLE #log
    (
        eventtype VARCHAR(MAX)
      , parameters INT
      , text VARCHAR(MAX)
    )

    INSERT INTO #log
    EXEC('DBCC INPUTBUFFER(@@SPID)')

    -- Define o tipo de operação DML
    IF NOT EXISTS
    (
        SELECT TOP 1 NULL
        FROM inserted
    ) -- deleted
    BEGIN
        SELECT
            @Tp_Alteracao = 'D'
          , @CampoChave = UsuCod
        FROM deleted
    END
    ELSE IF NOT EXISTS
    (
        SELECT TOP 1 NULL
        FROM deleted
    ) -- inserted
    BEGIN
        SELECT
            @Tp_Alteracao = 'I'
          , @CampoChave = UsuCod
        FROM inserted
    END
    ELSE
    BEGIN
        SELECT
            @Tp_Alteracao = 'U'
          , @CampoChave = UsuCod -- update
        FROM deleted
    END

    -- Registro da operação com horário de início da sessão
    INSERT INTO CadusuariosLogDML
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
      , Query
    )
    SELECT
        B.start_time
      , USER_NAME()
      , SUSER_NAME()
      , ORIGINAL_LOGIN()
      , @Tp_Alteracao
      , PROGRAM_NAME()
      , HOST_NAME()
      , 'CADUSUARIOS'
      , @CampoChave
      , (
            SELECT text
            FROM #log
        )
    FROM sys.dm_exec_sessions AS A
    INNER JOIN sys.dm_exec_requests AS B
        ON A.session_id = B.session_id
    INNER JOIN sys.dm_exec_connections AS C
        ON B.session_id = C.session_id
    WHERE A.session_id = @@SPID
END
GO

-- ============================================================
-- Tabela de logs DML
-- ============================================================
USE YOUR_DATABASE
GO

CREATE TABLE CadusuariosLogDML
(
    LogId INT NOT NULL IDENTITY(1,1)
  , DateDML DATETIME DEFAULT GETDATE()
  , DatabaseUser VARCHAR(100) DEFAULT USER_NAME()
  , LoginUser VARCHAR(100) DEFAULT SUSER_NAME()
  , LoginUserSQLTransaction VARCHAR(100) DEFAULT ORIGINAL_LOGIN()
  , TypeSQL CHAR(1)
  , ProgramName VARCHAR(100) DEFAULT PROGRAM_NAME()
  , HostName VARCHAR(100) DEFAULT HOST_NAME()
  , TableName VARCHAR(30) DEFAULT 'CADUSUARIOS'
  , UsuCod CHAR(25) NOT NULL DEFAULT ''
  , Query NVARCHAR(MAX) DEFAULT ''
  , CONSTRAINT PK_LogId PRIMARY KEY (LogId)
  , CONSTRAINT CK_TableName CHECK (TableName LIKE 'CADUSUARIOS')
  , CONSTRAINT CK_TypeSQL CHECK (TypeSQL IN ('D', 'I', 'U'))
);
