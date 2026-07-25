/*
    OBJETIVO: Calcular a frequência de erros de rede (network error code) registrados
              na tabela Management.HistoryErrorLogin, agrupados por data e hostname,
              apresentando ranking e percentual de participação no total de ocorrências.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- Cálculo de Ocorrências de Log Error por Data e HostName
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
