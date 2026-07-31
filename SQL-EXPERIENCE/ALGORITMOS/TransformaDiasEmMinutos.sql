/*
 *
    OBJETIVO: Converter valores de duração em formato de dias e horas
              (ex: '04.12:07:59' = 4 dias, 12 horas, 7 minutos e 59 segundos)
              para o total equivalente em minutos. Aceita tanto o formato
              com dias (dd.hh:mm:ss) quanto o formato de apenas tempo (hh:mm:ss).
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/en-us/sql/t-sql/functions/datediff-transact-sql?view=sql-server-ver17
 *  https://learn.microsoft.com/en-us/sql/t-sql/queries/with-common-table-expression-transact-sql?view=sql-server-ver17
 */
-- ====================================================================
-- Conversão de Dias e Horas para Minutos
-- ====================================================================

-- CTE de teste: define os formatos de entrada a serem convertidos
-- '04.12:07:59' representa 4 dias + 12h07m59s
-- '12:07:59'    representa apenas 12h07m59s (sem dias)
WITH T(D) AS
(
    SELECT
        '04.12:07:59'
    UNION ALL
    SELECT
        '12:07:59'
)
-- Converte a string de duração em minutos totais:
-- 1. LEFT(D, LEN(D) - 8) extrai a parte dos dias (tudo antes dos últimos 8 caracteres hh:mm:ss)
-- 2. Multiplica os dias por 24 horas e por 60 minutos para obter o total em minutos
-- 3. RIGHT(D, 8) extrai a parte de tempo (hh:mm:ss)
-- 4. DATEDIFF(MINUTE, 0, ...) converte o tempo base-zero em minutos desde a data 0 (1900-01-01)
-- 5. Soma os minutos dos dias com os minutos do tempo para obter o total
SELECT
      D
    , CAST(LEFT(D, LEN(D) - 8) AS FLOAT) * 24 * 60
      + DATEDIFF(MINUTE, 0, RIGHT(D, 8)) AS Mins
FROM T;
