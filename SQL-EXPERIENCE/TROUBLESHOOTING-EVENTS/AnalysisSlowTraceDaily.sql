/*
    OBJETIVO: Analisar execuções lentas registradas em trace do SQL Server,
              segmentando por usuários do sistema versus tarefas automatizadas,
              com métricas de desempenho e identificação de queries problemáticas.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- SEÇÃO 1: Análise de execuções para usuários do sistema (não tarefas)
-- ============================================================

-- Declaração das variáveis de período para análise
DECLARE @Dt_Inicial DATETIME;
DECLARE @Dt_Final DATETIME;

SET @Dt_Inicial = '20181119';
SET @Dt_Final = FLOOR(CAST(GETDATE() AS FLOAT));

-- Consulta de métricas agregadas de queries lentas por usuário do sistema
SELECT 
    REPLACE(REPLACE(REPLACE(x.Comando, CHAR(9), ''), CHAR(10), ''), CHAR(13), '') AS Comando
    , x.DataBaseName
    , x.LoginName
    , x.ApplicationName
    , x.HostName
    , x.QTD
    , x.LastTime
    , x.Total_time
    , x.AVG_Time
    , x.MIN_Time
    , x.MAX_Time
    , x.Total_reads
    , x.Writes
    , x.Total_cpu
FROM (
    SELECT 
        t.TextData AS Comando
        , t.DatabaseName
        , t.LoginName
        , CASE 
              WHEN t.LoginName = 'guru' AND t.DataBaseName = 'YOUR_DATABASE' THEN 'guruadm'
              WHEN t.LoginName = 'guru' AND t.DataBaseName <> 'YOUR_DATABASE' THEN 'guruUser'
              ELSE 'outros'
          END AS RotinasGuru
        , t.ApplicationName
        , t.HostName
        , (
            SELECT MAX(t2.EndTime)
            FROM Management.TraceSlowQuery AS t2
            WHERE t2.TextData = t.TextData
        ) AS LastTime
        , COUNT(t.TextData) AS QTD
        , SUM(Duration) AS Total_time
        , AVG(t.Duration) AS AVG_Time
        , MIN(t.Duration) AS MIN_Time
        , MAX(t.Duration) AS MAX_Time
        , SUM(CAST(t.Reads AS BIGINT)) AS Total_reads
        , SUM(CAST(t.writes AS BIGINT)) AS Writes
        , SUM(CAST(t.cpu AS BIGINT)) AS Total_cpu
    FROM Management.TraceSlowQuery AS t WITH (NOLOCK)
    WHERE t.Starttime >= @Dt_Inicial
        AND t.Starttime <= @Dt_Final
        AND t.Duration >= 20.00
        AND t.LoginName NOT IN (
            'cravil\nfe', 'cravil\task', 'cravil\administrator', 'cravil\backupexec',
            'cravil\sqlserver', 'cravil\vcenter', 'CRAVIL\rdornel', 'CRAVIL\rdorneldba',
            'nt service\mssqlserver', 'nt service\sqlserveragent', 'nt authority\system',
            'YOUR_DATABASE', 'admadriana', 'admcravil', 'admrobson',
            'cravil\domo', 'cravil\infogen03', 'agrosystem', 'consulta',
            'YOUR_DATABASE', 'guru', 'cravil\infogen02', 'cravil\infogen01',
            'infadriano', 'infedivaldo', 'infedivan', 'infeliezer', 'infivan', 'infjehan',
            'infernando', 'infmarcelo', 'inftiago', 'infneimar', 'suptcadm', 'vpxuser', 'sqlmdsmon'
        )
        AND t.ApplicationName NOT IN (
            'Microsoft SQL Server Management Studio - Query',
            '%DatabaseMail - DatabaseMail%'
        )
        AND t.DataBaseName = 'YOUR_DATABASE'
    GROUP BY 
        TextData,
        DatabaseName,
        LoginName,
        ApplicationName,
        HostName
    HAVING COUNT(TextData) > 1
) AS x
WHERE x.RotinasGuru <> 'guruadm'
ORDER BY 
    x.QTD DESC,
    x.LoginName;

-- ============================================================
-- SEÇÃO 2: Análise de execuções para tarefas automatizadas
-- ============================================================

-- Declaração das variáveis de período para análise de tarefas
DECLARE @Inicio DATETIME = '20180101';
DECLARE @Fim DATETIME = FLOOR(CAST(GETDATE() - 1 AS FLOAT));

-- Consulta de métricas diárias de queries lentas executadas por tarefas
SELECT 
    CONVERT(VARCHAR(10), t.StartTime, 103) AS StartTime
    , t.DatabaseName
    , COUNT(t.TextData) AS QTD
    , CAST(AVG(t.Duration) / 60 AS NUMERIC(15, 2)) AS AverageMinutes
    , CAST(MAX(t.Duration) / 60 AS NUMERIC(15, 2)) AS TopDurationMinutes
FROM YOUR_DATABASE.Management.TraceSlowQuery AS t WITH (NOLOCK)
WHERE t.Starttime BETWEEN @Inicio AND @Fim
    AND t.Duration >= 30.00
    AND t.LoginName IN (
        'cravil\nfe', 'cravil\task', 'cravil\administrator', 'cravil\backupexec',
        'cravil\sqlserver', 'cravil\vcenter', 'CRAVIL\rdornel', 'CRAVIL\rdorneldba',
        'nt service\mssqlserver', 'nt service\sqlserveragent', 'nt authority\system',
        'YOUR_DATABASE', 'admadriana', 'admcravil', 'admrobson',
        'cravil\domo', 'cravil\infogen03', 'agrosystem', 'consulta',
        'YOUR_DATABASE', 'guru', 'cravil\infogen02', 'cravil\infogen01',
        'infadriano', 'infedivaldo', 'infedivan', 'infeliezer', 'infivan', 'infjehan',
        'infernando', 'infmarcelo', 'inftiago', 'infneimar', 'suptcadm', 'vpxuser', 'sqlmdsmon'
    )
    AND t.HostName NOT IN ('WTS01', 'WTS02', 'WTS01')
GROUP BY 
    CONVERT(VARCHAR(10), t.StartTime, 103),
    t.DatabaseName;

-- ============================================================
-- SEÇÃO 3: Conferência de todos os dados armazenados no trace do dia
-- ============================================================

-- Consulta completa dos dados do arquivo de trace para validação
SELECT 
    TextData
    , NTUserName
    , HostName
    , ApplicationName
    , LoginName
    , SPID
    , CAST(Duration / 1000 / 1000.00 AS NUMERIC(15, 2)) AS DurationSegundos
    , Duration AS DurationMicrossegundos
    , Starttime
    , EndTime
    , Reads
    , writes
    , CPU
    , Servername
    , DatabaseName
    , rowcounts
    , SessionLoginName
FROM ::fn_trace_gettable(N'C:\DBACravil\Trace\Querys_Demoradas.trc', DEFAULT)
WHERE Duration IS NOT NULL
ORDER BY cpu DESC;

-- ============================================================
-- SEÇÃO 4: Identificação de textdata problemático e cálculo de tamanho
-- ============================================================

-- Cálculo do tamanho em MB de um textdata específico que causou erro de memória
-- Erro: An error occurred while executing batch. Error message is: Exception of type 'System.OutOfMemoryException' was thrown.
-- RowCount do textdata problemático do dia 14-01-2018: 454136
SELECT 484123978 / 1024.00 / 1024.00 AS Mb;
