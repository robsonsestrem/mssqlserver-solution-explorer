/*
    OBJETIVO: Criar uma auditoria para monitorar criação, modificação e exclusão
              de jobs no SQL Server Agent, incluindo alterações de status,
              schedules e associações, armazenando os eventos na tabela
              Job_Audit com informações do usuário, host, query executada
              e situação (habilitado/desabilitado).
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    https://www.dirceuresende.com/blog/como-criar-uma-auditoria-para-monitorar-criacao-modificacao-exclusao-de-jobs-no-sql-server/
*/
USE DBA_PerformanceHub;
GO

-- ============================================================
-- Tabela de histórico de auditoria de jobs
-- ============================================================

CREATE TABLE Management.Job_Audit
(
    Id_Auditoria    INT             IDENTITY(1, 1) NOT NULL
  , Dt_Evento       DATETIME        NULL          DEFAULT (GETDATE())
  , Ds_Usuario      VARCHAR(50)     NULL
  , Ds_Job          SYSNAME         NULL
  , Ds_Hostname     VARCHAR(50)     NULL
  , Ds_Query        VARCHAR(MAX)    NULL
  , Fl_Situacao     TINYINT         NULL
  , CONSTRAINT PK_Job_Audit PRIMARY KEY CLUSTERED (Id_Auditoria ASC)
);


-- ============================================================
-- Triggers de auditoria (criadas no banco msdb)
-- ============================================================

USE msdb;
GO

-- ============================================================
-- Trigger para auditoria de jobs (sysjobs)
-- ============================================================
IF (SELECT COUNT(*) FROM sys.triggers WHERE name = 'trgJobs_Status') > 0
    DROP TRIGGER dbo.trgJobs_Status;
GO

CREATE TRIGGER trgJobs_Status ON sysjobs
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserName VARCHAR(50) = SYSTEM_USER;
    DECLARE @HostName VARCHAR(50) = HOST_NAME();
    DECLARE @JobName SYSNAME;
    DECLARE @New_Enabled INT;
    DECLARE @Old_Enabled INT;
    DECLARE @ExecStr VARCHAR(100);
    DECLARE @Qry VARCHAR(MAX);

    SELECT @New_Enabled = Enabled FROM Inserted;
    SELECT @Old_Enabled = Enabled FROM Deleted;
    SELECT @JobName = Name FROM Deleted;

    IF (@JobName IS NULL)
        SELECT @JobName = Name FROM Inserted;

    -- Identificando a query executada
    CREATE TABLE #inputbuffer
    (
        EventType   NVARCHAR(60)
      , Parameters  INT
      , EventInfo   VARCHAR(MAX)
    );

    SET @ExecStr = 'DBCC INPUTBUFFER(' + STR(@@SPID) + ')';

    INSERT INTO #inputbuffer
    EXEC (@ExecStr);

    SET @Qry = (SELECT EventInfo FROM #inputbuffer);

    -- Verifica se houve alteração de status
    IF (@New_Enabled != @Old_Enabled)
    BEGIN
        IF (@New_Enabled = 1)
        BEGIN
            INSERT INTO DBA_PerformanceHub.Management.Job_Audit
            (
                Ds_Usuario
              , Ds_Job
              , Ds_Hostname
              , Ds_Query
              , Fl_Situacao
            )
            SELECT
                @UserName
              , @JobName
              , @HostName
              , @Qry
              , 1;  -- Habilitado
        END;

        IF (@New_Enabled = 0)
        BEGIN
            INSERT INTO DBA_PerformanceHub.Management.Job_Audit
            (
                Ds_Usuario
              , Ds_Job
              , Ds_Hostname
              , Ds_Query
              , Fl_Situacao
            )
            SELECT
                @UserName
              , @JobName
              , @HostName
              , @Qry
              , 0;  -- Desabilitado
        END;
    END
    ELSE
    BEGIN
        INSERT INTO DBA_PerformanceHub.Management.Job_Audit
        (
            Ds_Usuario
          , Ds_Job
          , Ds_Hostname
          , Ds_Query
        )
        SELECT
            @UserName
          , @JobName
          , @HostName
          , @Qry;
    END;
END;
GO


-- ============================================================
-- Trigger para auditoria de schedules (sysschedules)
-- ============================================================
IF (SELECT COUNT(*) FROM sys.triggers WHERE name = 'trgAudit_Schedules') > 0
    DROP TRIGGER dbo.trgAudit_Schedules;
GO

CREATE TRIGGER trgAudit_Schedules ON dbo.sysschedules
AFTER UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserName VARCHAR(50) = SYSTEM_USER;
    DECLARE @HostName VARCHAR(50) = HOST_NAME();
    DECLARE @JobName VARCHAR(MAX) = '';
    DECLARE @ExecStr VARCHAR(100);
    DECLARE @Qry VARCHAR(MAX);

    IF ((SELECT COUNT(*) FROM Inserted) > 0)
    BEGIN
        SELECT
            @JobName += (CASE WHEN @JobName != '' THEN ' | ' ELSE '' END) + A.name
        FROM
            msdb.dbo.sysjobs AS A
            INNER JOIN msdb.dbo.sysjobschedules AS B
                ON A.job_id = B.job_id
            INNER JOIN Inserted AS C
                ON B.schedule_id = C.schedule_id;
    END
    ELSE
    BEGIN
        SELECT
            @JobName += (CASE WHEN @JobName != '' THEN ' | ' ELSE '' END) + A.name
        FROM
            msdb.dbo.sysjobs AS A
            INNER JOIN msdb.dbo.sysjobschedules AS B
                ON A.job_id = B.job_id
            INNER JOIN Deleted AS C
                ON B.schedule_id = C.schedule_id;
    END;

    -- Identificando a query executada
    CREATE TABLE #inputbuffer
    (
        EventType   NVARCHAR(60)
      , Parameters  INT
      , EventInfo   VARCHAR(MAX)
    );

    SET @ExecStr = 'DBCC INPUTBUFFER(' + STR(@@SPID) + ')';

    INSERT INTO #inputbuffer
    EXEC (@ExecStr);

    SET @Qry = (SELECT EventInfo FROM #inputbuffer);

    IF (@JobName != '')
    BEGIN
        INSERT INTO DBA_PerformanceHub.Management.Job_Audit
        (
            Ds_Usuario
          , Ds_Job
          , Ds_Hostname
          , Ds_Query
        )
        SELECT
            @UserName
          , @JobName
          , @HostName
          , @Qry;
    END;
END;
GO

ALTER TABLE dbo.sysschedules ENABLE TRIGGER trgAudit_Schedules;
GO


-- ============================================================
-- Trigger para auditoria de associação job-schedule (sysjobschedules)
-- ============================================================
IF (SELECT COUNT(*) FROM sys.triggers WHERE name = 'trgAudit_Jobs_Schedules') > 0
    DROP TRIGGER dbo.trgAudit_Jobs_Schedules;
GO

CREATE TRIGGER trgAudit_Jobs_Schedules ON dbo.sysjobschedules
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @UserName VARCHAR(50) = SYSTEM_USER;
    DECLARE @HostName VARCHAR(50) = HOST_NAME();
    DECLARE @JobName SYSNAME;
    DECLARE @ExecStr VARCHAR(100);
    DECLARE @Qry VARCHAR(MAX);

    IF ((SELECT COUNT(*) FROM Inserted) > 0)
    BEGIN
        SELECT TOP 1
            @JobName = A.name
        FROM
            msdb.dbo.sysjobs AS A
            INNER JOIN Inserted AS B
                ON A.job_id = B.job_id;
    END
    ELSE
    BEGIN
        SELECT TOP 1
            @JobName = A.name
        FROM
            msdb.dbo.sysjobs AS A
            INNER JOIN Deleted AS B
                ON A.job_id = B.job_id;
    END;

    -- Identificando a query executada
    CREATE TABLE #inputbuffer
    (
        EventType   NVARCHAR(60)
      , Parameters  INT
      , EventInfo   VARCHAR(MAX)
    );

    SET @ExecStr = 'DBCC INPUTBUFFER(' + STR(@@SPID) + ')';

    INSERT INTO #inputbuffer
    EXEC (@ExecStr);

    SET @Qry = (SELECT EventInfo FROM #inputbuffer);

    INSERT INTO DBA_PerformanceHub.Management.Job_Audit
    (
        Ds_Usuario
      , Ds_Job
      , Ds_Hostname
      , Ds_Query
    )
    SELECT
        @UserName
      , @JobName
      , @HostName
      , @Qry;
END;
GO

ALTER TABLE dbo.sysjobschedules ENABLE TRIGGER trgAudit_Jobs_Schedules;
GO
