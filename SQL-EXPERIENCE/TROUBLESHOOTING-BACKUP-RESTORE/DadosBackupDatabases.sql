/*
    OBJETIVO: Analisar a situação dos backups (Full, Differential e Log) de todos os
              bancos de dados do usuário, classificando o status de cada um com base
              na data do último backup e no modelo de recuperação, gerando alertas
              de WARNING para backups críticos e DESNECESSÁRIO para homologação.
    PROJETO: mssqlserver-solution-explorer
*/
DECLARE @bkp TABLE
(
    Status              VARCHAR(60),
    Banco               VARCHAR(60),
    TipoBkp             VARCHAR(60),
    DataInicio          VARCHAR(60),
    DataFinal           VARCHAR(60),
    Type                VARCHAR(60),
    Backup_Finish_Date  VARCHAR(60),
    Recovery_Model      VARCHAR(60)
);

;WITH cte_BackupSets
AS (
    SELECT
        MAX(ISNULL(A.backup_set_id, ''))            AS backup_set_id
      , ISNULL(A.type, '')                          AS type
      , ISNULL(UPPER(CONVERT(VARCHAR(100), B.name)), '') AS database_name
      , MAX(ISNULL(A.backup_start_date, ''))        AS backup_start_date
      , MAX(ISNULL(A.backup_finish_date, ''))       AS backup_finish_date
      , ISNULL(B.recovery_model_desc, '')           AS recovery_model
    FROM
        master.sys.databases AS B
        LEFT JOIN msdb.dbo.backupset AS A
            ON A.database_name = B.name
               AND A.type IN ('D', 'I')
    GROUP BY
        B.name
      , A.type
      , B.recovery_model_desc

    UNION

    SELECT
        MAX(ISNULL(A.backup_set_id, ''))            AS backup_set_id
      , ISNULL(A.type, '')                          AS type
      , ISNULL(UPPER(CONVERT(VARCHAR(100), B.name)), '') AS database_name
      , MAX(ISNULL(A.backup_start_date, ''))        AS backup_start_date
      , MAX(ISNULL(A.backup_finish_date, ''))       AS backup_finish_date
      , ISNULL(B.recovery_model_desc, '')           AS recovery_model
    FROM
        master.sys.databases AS B
        LEFT JOIN msdb.dbo.backupset AS A
            ON A.database_name = B.name
               AND A.type IN ('L')
    GROUP BY
        B.name
      , A.type
      , B.recovery_model_desc
)
, cte_BackupFull
AS (
    SELECT
        MAX(ISNULL(backup_set_id, ''))              AS backup_set_id
      , ISNULL(type, '')                            AS type
      , ISNULL(database_name, '')                   AS database_name
      , MAX(ISNULL(backup_start_date, ''))          AS backup_start_date
      , MAX(ISNULL(backup_finish_date, ''))         AS backup_finish_date
      , recovery_model
    FROM
        cte_BackupSets
    GROUP BY
        database_name
      , type
      , recovery_model
)

INSERT INTO @bkp
SELECT
    ISNULL(CAST
    (
        CASE
            -- Full backup - produção
            WHEN A.type = 'D'
                 AND CAST(DATEDIFF(DAY, ISNULL(A.backup_finish_date, ''), GETDATE()) AS VARCHAR(10)) > 1
                 AND A.database_name NOT LIKE '%homolog%'
                THEN 'WARNING'
            WHEN A.type = 'D'
                 AND CAST(DATEDIFF(DAY, ISNULL(A.backup_finish_date, ''), GETDATE()) AS VARCHAR(10)) > 1
                 AND A.database_name LIKE '%homolog%'
                THEN 'DESNECESSÁRIO'

            -- Differential backup - produção
            WHEN A.type = 'I'
                 AND
                 (
                     (DATEDIFF(DAY, ISNULL(A.backup_finish_date, ''), GETDATE()) >= 2
                      AND DATEPART(WEEKDAY, ISNULL(A.backup_finish_date, '')) <> 6)
                     OR
                     (DATEDIFF(DAY, ISNULL(A.backup_finish_date, ''), GETDATE()) > 3
                      AND DATEPART(WEEKDAY, ISNULL(A.backup_finish_date, '')) = 6)
                 )
                 AND A.database_name NOT LIKE '%homolog%'
                THEN 'WARNING'
            WHEN A.type = 'I'
                 AND
                 (
                     (DATEDIFF(DAY, ISNULL(A.backup_finish_date, ''), GETDATE()) >= 2
                      AND DATEPART(WEEKDAY, ISNULL(A.backup_finish_date, '')) <> 6)
                     OR
                     (DATEDIFF(DAY, ISNULL(A.backup_finish_date, ''), GETDATE()) > 3
                      AND DATEPART(WEEKDAY, ISNULL(A.backup_finish_date, '')) = 6)
                 )
                 AND A.database_name LIKE '%homolog%'
                THEN 'DESNECESSÁRIO'

            -- Log backup - homologação
            WHEN A.type = 'L'
                 AND CAST(DATEDIFF(HOUR, ISNULL(A.backup_finish_date, ''), GETDATE()) AS VARCHAR(10)) > 1
                 AND A.database_name LIKE '%homolog%'
                THEN 'DESNECESSÁRIO'

            -- Log backup - produção (FULL recovery model)
            WHEN A.type = 'L'
                 AND CAST(DATEDIFF(HOUR, ISNULL(A.backup_finish_date, ''), GETDATE()) AS VARCHAR(10)) > 1
                 AND A.database_name NOT LIKE '%homolog%'
                 AND A.recovery_model <> 'SIMPLE'
                THEN 'WARNING'

            -- Log backup - produção (SIMPLE recovery model)
            WHEN A.type = 'L'
                 AND CAST(DATEDIFF(HOUR, ISNULL(A.backup_finish_date, ''), GETDATE()) AS VARCHAR(10)) > 1
                 AND A.database_name NOT LIKE '%homolog%'
                 AND A.recovery_model = 'SIMPLE'
                THEN 'DESNECESSÁRIO'

            -- Sem backup - SIMPLE recovery model
            WHEN (A.type IS NULL OR A.type = '')
                 AND A.recovery_model = 'SIMPLE'
                THEN 'DESNECESSÁRIO'

            -- Sem backup - homologação (FULL/LOG recovery model)
            WHEN (A.type IS NULL OR A.type = '')
                 AND A.recovery_model <> 'SIMPLE'
                 AND A.database_name LIKE '%homolog%'
                THEN 'DESNECESSÁRIO'

            -- Sem backup - produção (FULL/LOG recovery model)
            WHEN (A.type IS NULL OR A.type = '')
                 AND A.recovery_model <> 'SIMPLE'
                 AND A.database_name NOT LIKE '%homolog%'
                THEN 'WARNING'

            ELSE 'Ok'
        END AS VARCHAR(MAX)
    ), '')                                                                      AS Status
  , UPPER(CAST(ISNULL(A.database_name, '') AS VARCHAR(100)))                    AS Banco
  , ISNULL(CAST
    (
        CASE A.type
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Differential'
            WHEN 'L' THEN 'Log'
            WHEN 'F' THEN 'File or Filegroup'
            WHEN 'G' THEN 'File Differential'
            WHEN 'P' THEN 'Partial'
            WHEN 'Q' THEN 'Partial Differential'
            ELSE 'Sem Backup'
        END AS VARCHAR(MAX)
    ), '')                                                                      AS TipoBkp
  , ISNULL(CAST(ISNULL(CONVERT(VARCHAR(50), A.backup_start_date), '') AS VARCHAR(MAX)), '') AS DataInicio
  , ISNULL(CAST(ISNULL(CONVERT(VARCHAR(50), A.backup_finish_date), '') AS VARCHAR(MAX)), '') AS DataFinal
  , ISNULL(A.type, '')                                                          AS Type
  , ISNULL(A.backup_finish_date, '')                                            AS Backup_Finish_Date
  , A.recovery_model                                                            AS Recovery_Model
FROM
    cte_BackupFull AS A
WHERE
    A.database_name NOT IN ('master', 'tempdb', 'model', 'msdb')
ORDER BY
    A.database_name
  , A.type;

SELECT
    Status
  , Banco
  , TipoBkp
  , DataInicio
  , DataFinal
  , Type
  , Backup_Finish_Date
  , Recovery_Model
FROM
    @bkp;
