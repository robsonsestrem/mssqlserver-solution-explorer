/*
 *
	OBJETIVO: Análise de tendência de requisições lentas (Slow Requests) capturadas via SQL Trace,
	          segmentando por usuários e tarefas/serviços para identificação de gargalos de performance.
	PROJETO: mssqlserver-solution-explorer
 */
-- ============================================================
-- Tendência de Requisições Lentas (Slow Request Trend)
-- ============================================================

-- ============================================================
-- Consulta 1: Análise de requisições lentas para USUÁRIOS
-- Exclui logins de sistema, tarefas automatizadas e serviços internos
-- ============================================================
DECLARE @Dt_Inicial DATETIME = '20180101';
DECLARE @Dt_Final DATETIME = GETDATE();

SELECT
    CONVERT(VARCHAR(10), [y].[StartTime], 103) AS [StartTime]
  , [y].[DataBaseName]
  , COUNT([y].[TextData]) AS [QTD]
  , CAST(AVG([y].[Duration]) AS NUMERIC(15, 2)) AS [MediaSegundos]
  , CAST(MAX([y].[Duration]) / 60 AS NUMERIC(15, 2)) AS [TopDurationMinutes]
FROM (
    SELECT
        [x].[DataBaseName]
      , [x].[Duration]
      , [x].[LoginName]
      , [x].[RotinasGuru]
      , [x].[StartTime]
      , [x].[TextData]
    FROM (
        SELECT
            [t].[DatabaseName]
          , CASE
                WHEN [t].[LoginName] = 'guru' AND [t].[DataBaseName] = 'YOUR_DATABASE' THEN 'guruadm'
                WHEN [t].[LoginName] = 'guru' AND [t].[DataBaseName] <> 'YOUR_DATABASE' THEN 'guruUser'
                ELSE 'outros'
            END AS [RotinasGuru]
          , [t].[LoginName]
          , [t].[StartTime]
          , [t].[Duration]
          , [t].[TextData]
        FROM [YOUR_DATABASE].[Management].[TraceSlowQuery] AS [t] WITH (NOLOCK)
        WHERE [t].[Starttime] BETWEEN @Dt_Inicial AND @Dt_Final
          AND [t].[Duration] >= 30.00
          AND [t].[LoginName] NOT IN (
              'CRAVIL\Nfe'
            , 'CRAVIL\Task'
            , 'CRAVIL\administrator'
            , 'CRAVIL\backupexec'
            , 'CRAVIL\sqlserver'
            , 'CRAVIL\vcenter'
            , 'NT SERVICE\MSSQLSERVER'
            , 'NT SERVICE\SQLSERVERAGENT'
            , 'NT AUTHORITY\SYSTEM'
            , 'sa'
            , 'admcravil'
            , 'YOUR_DATABASE'
            , 'CRAVIL\domo'
            , 'admrobson'
            , 'admadriana'
            , 'CRAVIL\TI-01'
            , 'CRAVIL\TI-02'
            , 'CRAVIL\TI-03'
            , 'CRAVIL\TI-04'
            , 'CRAVIL\TI-05'
            , 'CRAVIL\adm1'
            , 'CRAVIL\adm2'
            , 'CRAVIL\adm3'
            , 'CRAVIL\adm4'
            , 'CRAVIL\adm5'
            , 'CRAVIL\adm6'
            , 'agrosystem'
            , 'dbarobson'
            , 'CRAVIL\rdorneldba'
            , 'CRAVIL\rdornel'
            , 'CRAVIL\Teclogica'
            , 'CRAVIL\consultorpgi'
            , 'CRAVIL\Altovale'
            , 'CRAVIL\Maxprotection'
            , 'CRAVIL\Infogen03'
            , 'CRAVIL\Infogen02'
            , 'CRAVIL\Infogen01'
            , 'infadriano'
            , 'infedivaldo'
            , 'infedivan'
            , 'CRAVIL\Networkbrasil'
            , 'infeliezer'
            , 'infivan'
            , 'infjehan'
            , 'infjoabel'
            , 'infmarcelo'
            , 'inftiago'
            , 'infogenbi'
            , 'suptcadm'
            , 'vpxuser'
            , 'sqlmdsmon'
          )
          AND [t].[ApplicationName] NOT IN (
              'Microsoft SQL Server Management Studio - Query'
            , '%DatabaseMail - DatabaseMail%'
          )
          AND [t].[DataBaseName] = 'YOUR_DATABASE'
    ) AS [x]
    WHERE [x].[RotinasGuru] <> 'guruadm'
) AS [y]
GROUP BY
    CONVERT(VARCHAR(10), [y].[StartTime], 103)
  , [y].[DatabaseName];


-- ============================================================
-- Consulta 2: Análise de requisições lentas para TAREFAS/SERVIÇOS
-- Foca apenas em logins de sistema e automatizações
-- O login 'guru' é tratado como serviço (padrão das databases guru5 e guru6)
-- Objetivo direcionado para YOUR_DATABASE90
-- ============================================================
DECLARE @Dt_Inicial DATETIME = '20180101';
DECLARE @Dt_Final DATETIME = GETDATE();

SELECT
    CONVERT(VARCHAR(10), [t].[StartTime], 103) AS [StartTime]
  , [t].[DatabaseName]
  , COUNT([t].[TextData]) AS [QTD]
  , CAST(AVG([t].[Duration]) / 60 AS NUMERIC(15, 2)) AS [AverageMinutes]
  , CAST(MAX([t].[Duration]) / 60 AS NUMERIC(15, 2)) AS [TopDurationMinutes]
FROM [YOUR_DATABASE].[Management].[TraceSlowQuery] AS [t] WITH (NOLOCK)
WHERE [t].[Starttime] BETWEEN @Dt_Inicial AND @Dt_Final
  AND [t].[Duration] >= 30.00
  AND [t].[LoginName] IN (
      'CRAVIL\Nfe'
    , 'CRAVIL\Task'
    , 'CRAVIL\administrator'
    , 'CRAVIL\backupexec'
    , 'CRAVIL\sqlserver'
    , 'CRAVIL\vcenter'
    , 'NT SERVICE\MSSQLSERVER'
    , 'NT SERVICE\SQLSERVERAGENT'
    , 'NT AUTHORITY\SYSTEM'
    , 'sa'
    , 'admcravil'
    , 'YOUR_DATABASE'
    , 'CRAVIL\rdornel'
    , 'CRAVIL\domo'
    , 'CRAVIL\Infogen03'
    , 'CRAVIL\Infogen02'
    , 'CRAVIL\Infogen01'
    , 'infadriano'
    , 'infedivaldo'
    , 'infedivan'
    , 'infeliezer'
    , 'infivan'
    , 'infjehan'
    , 'infjoabel'
    , 'infmarcelo'
    , 'inftiago'
    , 'infogenbi'
    , 'suptcadm'
    , 'vpxuser'
    , 'sqlmdsmon'
  )
GROUP BY
    CONVERT(VARCHAR(10), [t].[StartTime], 103)
  , [t].[DatabaseName];
