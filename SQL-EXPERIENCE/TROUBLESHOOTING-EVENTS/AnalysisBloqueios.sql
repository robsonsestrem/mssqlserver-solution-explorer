/*
    OBJETIVO: Analisar bloqueios (deadlocks/blocking) registrados na tabela
              Management.HistoryBlockedProcess, extraindo informações do XML
              de bloqueio como duração, locks, SPIDs, scripts e logins
              envolvidos, além de contagem de usuários distintos afetados por dia.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- Análise detalhada de bloqueios por período
-- ============================================================

;WITH cte_BlockedProcess
AS (
    SELECT
        IdBlock
      , DateBlock
      , DatabaseName
      , GraphBlock
    FROM
        Management.HistoryBlockedProcess
    WHERE
        DateBlock >= '2019-04-30 13:15:00.997'
        AND DateBlock < '20190501'
)
, ExtraiXML
AS (
    SELECT
        REPLACE
        (
            (CAST(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Duration)') AS VARCHAR(60)) AS MONEY) / 1000 / 1000),
            ',',
            '.'
        )                                                                       AS Segundos
      , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EventType)') AS VARCHAR(50)) AS Evento
      , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Inicio
      , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EndTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Fim
      , A.DatabaseName                                                          AS BD
      , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Mode)') AS VARCHAR(10))   AS Mode
      , BlockedProcess.Process.value('@lockMode', 'VARCHAR(MAX)')               AS LockMode
      , BlockedProcess.Process.value('@waitresource', 'VARCHAR(MAX)')           AS Waitresource
      , BlockedProcess.Process.value('@clientapp', 'VARCHAR(MAX)')              AS Program_Blocked
      , BlockedProcess.Process.value('@spid', 'VARCHAR(MAX)')                   AS SPID_Blocked
      , BlockedProcess.Process.value('@hostname', 'VARCHAR(MAX)')               AS Host_Blocked
      , BlockedProcess.Process.value('@loginname', 'VARCHAR(MAX)')              AS Login_Blocked
      , BlockedProcess.Process.value('@isolationlevel', 'VARCHAR(MAX)')         AS IsolationLevel_Blocked
      , REPLACE
        (
            REPLACE
            (
                REPLACE
                (
                    RTRIM
                    (
                        REPLACE
                        (
                            REPLACE
                            (
                                CAST(BlockedProcess.Process.query('inputbuf') AS VARCHAR(MAX)),
                                '<inputbuf>',
                                ''
                            ),
                            '</inputbuf>',
                            ''
                        )
                    ),
                    CHAR(10),
                    ''
                ),
                CHAR(13),
                ''
            ),
            CHAR(9),
            ''
        )                                                                       AS Script_Blocked
      , BlockingProcess.Process.value('@clientapp', 'VARCHAR(MAX)')             AS Program_Blocking
      , BlockingProcess.Process.value('@spid', 'VARCHAR(MAX)')                  AS SPID_Blocking
      , BlockingProcess.Process.value('@hostname', 'VARCHAR(MAX)')              AS Host_Blocking
      , BlockingProcess.Process.value('@loginname', 'VARCHAR(MAX)')             AS Login_Blocking
      , BlockingProcess.Process.value('@isolationlevel', 'VARCHAR(MAX)')        AS IsolationLevel_Blocking
      , REPLACE
        (
            REPLACE
            (
                REPLACE
                (
                    RTRIM
                    (
                        REPLACE
                        (
                            REPLACE
                            (
                                CAST(BlockingProcess.Process.query('inputbuf') AS VARCHAR(MAX)),
                                '<inputbuf>',
                                ''
                            ),
                            '</inputbuf>',
                            ''
                        )
                    ),
                    CHAR(10),
                    ''
                ),
                CHAR(13),
                ''
            ),
            CHAR(9),
            ''
        )                                                                       AS Script_Blocking
    FROM
        cte_BlockedProcess AS A
        CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocked-process/process') AS BlockedProcess(Process)
        CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocking-process/process') AS BlockingProcess(Process)
)

SELECT
    (CAST(xml.Segundos AS DECIMAL(18,2)) / 60)                                  AS Minutos
  , xml.*
FROM
    ExtraiXML AS xml
-- WHERE CAST(xml.Segundos AS DECIMAL(18,2)) > 60.00
ORDER BY
    Minutos DESC;

/*
-- Consulta para análise por LockMode
SELECT
    COUNT(*)
  , xml.LockMode
FROM
    ExtraiXML AS xml
WHERE
    xml.Script_Blocking NOT LIKE '%select%'
    AND xml.Script_Blocking NOT LIKE '%update%'
    AND xml.Script_Blocking NOT LIKE '%insert%'
    AND xml.Script_Blocking NOT LIKE '%delete%'
    AND xml.Script_Blocking NOT LIKE '%Database Id%'
GROUP BY
    xml.LockMode
ORDER BY
    COUNT(*) DESC;
*/


-- ============================================================
-- Conta usuários distintos por dia afetados por bloqueio
-- ============================================================

;WITH cte_BlockedProcess
AS (
    SELECT
        IdBlock
      , DateBlock
      , DatabaseName
      , GraphBlock
    FROM
        Management.HistoryBlockedProcess
    WHERE
        DateBlock >= '20180801'
)
, ExtraiXML
AS (
    SELECT
        A.IdBlock
      , REPLACE
        (
            (CAST(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Duration)') AS VARCHAR(60)) AS MONEY) / 1000 / 1000),
            ',',
            '.'
        )                                                                       AS Segundos
      , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EventType)') AS VARCHAR(50)) AS Evento
      , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Inicio
      , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EndTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Fim
      , A.DatabaseName                                                          AS BD
      , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Mode)') AS VARCHAR(10))   AS Mode
      , BlockedProcess.Process.value('@lockMode', 'VARCHAR(MAX)')               AS LockMode
      , BlockedProcess.Process.value('@waitresource', 'VARCHAR(MAX)')           AS Waitresource
      , BlockedProcess.Process.value('@clientapp', 'VARCHAR(MAX)')              AS Program_Blocked
      , BlockedProcess.Process.value('@spid', 'VARCHAR(MAX)')                   AS SPID_Blocked
      , BlockedProcess.Process.value('@hostname', 'VARCHAR(MAX)')               AS Host_Blocked
      , BlockedProcess.Process.value('@loginname', 'VARCHAR(MAX)')              AS Login_Blocked
      , BlockedProcess.Process.value('@isolationlevel', 'VARCHAR(MAX)')         AS IsolationLevel_Blocked
      , REPLACE
        (
            REPLACE
            (
                REPLACE
                (
                    RTRIM
                    (
                        REPLACE
                        (
                            REPLACE
                            (
                                CAST(BlockedProcess.Process.query('inputbuf') AS VARCHAR(MAX)),
                                '<inputbuf>',
                                ''
                            ),
                            '</inputbuf>',
                            ''
                        )
                    ),
                    CHAR(10),
                    ''
                ),
                CHAR(13),
                ''
            ),
            CHAR(9),
            ''
        )                                                                       AS Script_Blocked
      , BlockingProcess.Process.value('@clientapp', 'VARCHAR(MAX)')             AS Program_Blocking
      , BlockingProcess.Process.value('@spid', 'VARCHAR(MAX)')                  AS SPID_Blocking
      , BlockingProcess.Process.value('@hostname', 'VARCHAR(MAX)')              AS Host_Blocking
      , BlockingProcess.Process.value('@loginname', 'VARCHAR(MAX)')             AS Login_Blocking
      , BlockingProcess.Process.value('@isolationlevel', 'VARCHAR(MAX)')        AS IsolationLevel_Blocking
      , REPLACE
        (
            REPLACE
            (
                REPLACE
                (
                    RTRIM
                    (
                        REPLACE
                        (
                            REPLACE
                            (
                                CAST(BlockingProcess.Process.query('inputbuf') AS VARCHAR(MAX)),
                                '<inputbuf>',
                                ''
                            ),
                            '</inputbuf>',
                            ''
                        )
                    ),
                    CHAR(10),
                    ''
                ),
                CHAR(13),
                ''
            ),
            CHAR(9),
            ''
        )                                                                       AS Script_Blocking
    FROM
        cte_BlockedProcess AS A
        CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocked-process/process') AS BlockedProcess(Process)
        CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocking-process/process') AS BlockingProcess(Process)
)

SELECT DISTINCT
    COUNT(y.TotalPorDia) OVER (PARTITION BY y.data)                            AS [Total Logins Bloqueados Distintos]
  , y.data                                                                     AS [Data]
FROM
    (
        SELECT
            ROW_NUMBER() OVER (ORDER BY x.Login_Blocked)                        AS TotalPorDia
          , x.Login_Blocked
          , x.data
        FROM
            (
                SELECT DISTINCT
                    xml.Login_Blocked
                  , CAST(xml.Data_Inicio AS DATE)                              AS [data]
                FROM
                    ExtraiXML AS xml
                WHERE
                    xml.BD = 'YOUR_DATABASE'
            ) AS x
    ) AS y;
