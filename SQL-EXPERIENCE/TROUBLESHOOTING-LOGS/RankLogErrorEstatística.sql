/*
    OBJETIVO: Analisar e ranquear ocorrências de erros de rede (network error code)
              na tabela Management.HistoryErrorLogin, com três abordagens distintas:
              ranqueamento com estatística percentual, total por data e agrupamento
              por login.
    PROJETO: mssqlserver-solution-explorer
*/

USE IntegraTICravil;
GO

-- ============================================================
-- Ranqueamento e estatística percentual
-- ============================================================
SELECT
    y.Data
  , y.HostName
  , y.[Numero de Ocorrências]
  , DENSE_RANK() OVER (ORDER BY y.[Numero de Ocorrências] DESC)           AS [Rank]
  , CAST
    (
        100. * y.[Numero de Ocorrências]
        / LAST_VALUE(y.Somatoria) OVER
          (
              ORDER BY y.Somatoria
              ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
          )
        AS DECIMAL(18,2)
    )                                                                      AS PercentualDoTotal
FROM
    (
        SELECT
            x.DataEvent                                                     AS [Data]
          , COUNT(x.DataEvent)                                              AS [Numero de Ocorrências]
          , x.HostName
          , SUM(COUNT(x.DataEvent)) OVER
            (
                ORDER BY COUNT(x.DataEvent)
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )                                                               AS Somatoria
        FROM
            (
                SELECT
                    CAST(t1.DateError AS DATE)                              AS DataEvent
                  , t1.HostName
                FROM
                    Management.HistoryErrorLogin AS t1
                WHERE
                    t1.TextData LIKE '%network error code%'
            ) AS x
        GROUP BY
            x.DataEvent
          , x.HostName
    ) AS y
GROUP BY
    y.Data
  , y.HostName
  , y.[Numero de Ocorrências]
  , y.Somatoria
ORDER BY
    y.[Numero de Ocorrências] DESC;


-- ============================================================
-- Total de ocorrências por data
-- ============================================================
SELECT
    x.DataEvent                                                             AS [Data]
  , COUNT(x.DataEvent)                                                      AS [Numero de Ocorrências]
FROM
    (
        SELECT
            CAST(t1.DateError AS DATE)                                      AS DataEvent
        FROM
            Management.HistoryErrorLogin AS t1
        WHERE
            t1.DateError >= '20180315'
            AND t1.TextData LIKE '%network error code%'
    ) AS x
GROUP BY
    x.DataEvent
ORDER BY
    x.DataEvent DESC;


-- ============================================================
-- Ocorrências por login
-- ============================================================
SELECT
    x.DataEvent                                                             AS [Data]
  , COUNT(x.DataEvent)                                                      AS [Numero de Ocorrências]
  , x.LoginName
FROM
    (
        SELECT
            CAST(t1.DateError AS DATE)                                      AS DataEvent
          , t1.LoginName
        FROM
            Management.HistoryErrorLogin AS t1
        WHERE
            t1.TextData LIKE '%network error code%'
    ) AS x
GROUP BY
    x.DataEvent
  , x.LoginName
ORDER BY
    x.DataEvent DESC;

