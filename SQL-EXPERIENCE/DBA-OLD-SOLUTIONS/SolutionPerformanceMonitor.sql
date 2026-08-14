/*
 *
    OBJETIVO: Consulta e extração de contadores de desempenho do SQL Server (PerfMon)
              para monitoramento de hardware, memória, CPU, I/O e métricas específicas
              do SQL Server. Inclui também procedure de limpeza para retenção configurável
              dos dados históricos.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  http://www.sqlteam.com/forums/topic.asp?topic_id=122326
 */
USE YOUR_DATABASE
GO

-- ============================================================
-- Bloco 01: Métricas de Disco
-- Current Disk Queue Length, % Idle Time, Avg. Disk Queues,
-- % Disk Time, Read/Write Bytes/sec, Split IO/Sec
-- ============================================================
SELECT
      CASE t1.CounterID
          WHEN 5   THEN 'Current Disk Queue Length'
          WHEN 4   THEN '% Idle Time'
          WHEN 6   THEN 'Avg. Disk Read Queue Length'
          WHEN 7   THEN 'Avg. Disk Write Queue Length'
          WHEN 8   THEN '% Disk Time'
          WHEN 9   THEN 'Disk Read Bytes/sec'
          WHEN 10  THEN 'Disk Write Bytes/sec'
          WHEN 190 THEN 'Split IO/Sec'
      END AS HardDisk
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , ROUND(t1.CounterValue, 2) AS CounterValue
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (4, 5, 6, 7, 8, 9, 10, 190)
GO

-- ============================================================
-- Bloco 02: Métricas de CPU
-- % Processor Time, Processor Queue Length, Thread Count
-- ============================================================
SELECT
      CASE t1.CounterID
          WHEN 12 THEN '% Processor Time'
          WHEN 22 THEN 'Processor Queue Length'
          WHEN 11 THEN 'Thread Count'
      END AS CPU
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , ROUND(t1.CounterValue, 2) AS CounterValue
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (22, 12, 11)
GO

-- ============================================================
-- Bloco 03: Métricas de Memória (em GB)
-- Available Bytes, Committed Bytes, Memory Grants Pending
-- ============================================================
SELECT
      CASE t1.CounterID
          WHEN 131 THEN 'Available Bytes'
          WHEN 3   THEN 'Committed Bytes'
          WHEN 18  THEN 'Memory Grants Pending'
      END AS Memory
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , CAST(t1.CounterValue / 1073741824 AS DECIMAL(10, 2)) AS CounterValue_Gb
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (131, 3, 18)
GO

-- ============================================================
-- Bloco 04: Contadores específicos do SQL Server
-- Buffer cache hit ratio, Page life expectancy, Lock Waits/sec,
-- Batch Requests/sec, Compilations/Recompilations, Page reads/lookups,
-- Logins/sec, Logouts/sec, User Connections
-- ============================================================
SELECT
      CASE t1.CounterID
          WHEN 153 THEN 'Page reads/sec'
          WHEN 152 THEN 'Page lookups/sec'
          WHEN 13  THEN 'Buffer cache hit ratio'
          WHEN 14  THEN 'Page life expectancy'
          WHEN 16  THEN 'Lock Waits/sec'
          WHEN 19  THEN 'Batch Requests/sec'
          WHEN 20  THEN 'SQL Compilations/sec'
          WHEN 21  THEN 'SQL Re-Compilations/sec'
          WHEN 158 THEN 'Logins/sec'
          WHEN 159 THEN 'Logouts/sec'
          WHEN 160 THEN 'User Connections'
      END AS [SQL Counter]
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , ROUND(t1.CounterValue, 2) AS CounterValue
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (13, 14, 16, 19, 20, 21, 153, 152, 158, 159, 160)
GO

-- ============================================================
-- Bloco 05: Comparação entre Batch Requests, Compilações e
-- Recompilações com thresholds calculados (10% e 1%)
-- ============================================================
SELECT
      CASE t1.CounterID
          WHEN 19 THEN 'Batch Requests/sec'
          WHEN 20 THEN 'SQL Compilations/sec'
          WHEN 21 THEN 'SQL Re-Compilations/sec'
      END AS [SQL Counter]
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , ROUND(t1.CounterValue, 2) AS CounterValue
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (19, 20, 21)

UNION ALL

SELECT
      'Threshold_Compilation' AS [SQL Counter]
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , ROUND(t1.CounterValue, 2) * 0.1 AS CounterValue
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (19)

UNION ALL

SELECT
      'Threshold_Recompilation' AS [SQL Counter]
    , CONVERT(
          DATETIME,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
          + ' '
          + SUBSTRING(t1.CounterDateTime, 12, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 15, 2)
          + ':'
          + SUBSTRING(t1.CounterDateTime, 18, 2)
          + '.'
          + SUBSTRING(t1.CounterDateTime, 21, 3)
      ) AS DateReference
    , CONVERT(
          DATE,
          LEFT(t1.CounterDateTime, 4)
          + SUBSTRING(t1.CounterDateTime, 6, 2)
          + SUBSTRING(t1.CounterDateTime, 9, 2)
      ) AS [Date]
    , DATEPART(
          HOUR,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Horas
    , DATEPART(
          MINUTE,
          CONVERT(
              DATETIME,
              LEFT(t1.CounterDateTime, 4)
              + SUBSTRING(t1.CounterDateTime, 6, 2)
              + SUBSTRING(t1.CounterDateTime, 9, 2)
              + ' '
              + SUBSTRING(t1.CounterDateTime, 12, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 15, 2)
              + ':'
              + SUBSTRING(t1.CounterDateTime, 18, 2)
              + '.'
              + SUBSTRING(t1.CounterDateTime, 21, 3)
          )
      ) AS Minutos
    , ROUND(t1.CounterValue, 2) * 0.01 AS CounterValue
FROM
    CounterData AS t1
WHERE
    t1.CounterID IN (19)
GO

-- ============================================================
-- Bloco 06: Procedure de manutenção – Retenção dos dados
-- Rotina de limpeza da tabela de contadores do PerfMon,
-- preservando apenas os últimos X dias (padrão 60 dias).
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_DeleteCountersPerfMon
(
    @qtdadeManterDias INT = 60
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        -- ============================================================
        -- Bloco 06.1: Busca quantidade de dias distintos registrados
        -- ============================================================
        DECLARE @qtdade INT =
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT x.[Date] AS Dia
                FROM
                (
                    SELECT CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) AS [Date]
                    FROM dbo.CounterData
                ) AS x
                GROUP BY x.[Date]
            ) AS x2
        )

        DECLARE @dataMin DATETIME

        -- ============================================================
        -- Bloco 06.2: Loop para tratamento e exclusão dos dias excedentes
        -- ============================================================
        WHILE (@qtdade > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT MIN(x2.Dia)
                FROM
                (
                    SELECT x.Date AS Dia
                    FROM
                    (
                        SELECT CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) AS [Date]
                        FROM dbo.CounterData
                    ) AS x
                    GROUP BY x.Date
                ) AS x2
            )

            PRINT 'Deletando dados do dia -> ' + CAST(@dataMin AS VARCHAR(20))

            -- ============================================================
            -- Bloco 06.3: Exclusão física dos registros do dia mínimo
            -- ============================================================
            DELETE FROM dbo.CounterData
            WHERE CAST(CONVERT(VARCHAR(10), CONVERT(VARCHAR, CounterDateTime), 101) AS DATE) = @dataMin

            SET @qtdade = @qtdade - 1
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Bloco 06.4: Captura de exceção e montagem do e-mail de falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject    VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'

        SET @corpoFalha = '
        | Falha na procedure [sp_DeleteCountersPerfMon]:
        |
        | ---|---|---|
        |    [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
        |      [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
        |      [MESSAGE] - ' + ERROR_MESSAGE() + '
        |
        '

        SELECT @corpoFalha = @corpoFalha + ''

        -- ============================================================
        -- Bloco 06.5: Envio do e-mail de falha
        -- ============================================================
        EXEC msdb.dbo.sp_send_dbmail
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'
    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO
