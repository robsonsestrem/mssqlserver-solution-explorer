/*
    OBJETIVO: Monitorar consultas duplicadas de agendamento no sistema, identificando registros
              com mesmo horário de início, fim e especialidade médica através de ROW_NUMBER e
              self-join para análise de possíveis inconsistências de dados.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- SEÇÃO 1: Consulta de teste para validação de duplicidade
-- ============================================================

-- Exemplo de parâmetros para teste:
-- INTERVALO: C.DT_CNSUL_INI_PREV BETWEEN '2023-02-14 14:00:00' AND '2023-02-14 14:20:00'
-- PROFISSIONAL: SELECT * FROM PSSOA p WHERE P.NM_PSSOA LIKE '%RONNE HEDILI%' -- 609852

-- Consulta com ROW_NUMBER para identificar duplicatas por horário e especialidade
SELECT 
    ROW_NUMBER() OVER (
        PARTITION BY 
            C.DT_CNSUL_INI_PREV,
            C.DT_CNSUL_FIM_PREV,
            C.CD_ESPMD
        ORDER BY C.CD_CNSUL ASC
    ) AS RN
    , *
FROM CNSUL AS C
WHERE C.CD_PSSOA_PROF = 609852
    AND C.DT_CNSUL_INI_PREV BETWEEN '2023-02-14 14:00:00' AND '2023-02-14 14:21:00';

-- ============================================================
-- SEÇÃO 2: Monitoramento de duplicidade com self-join
-- ============================================================

-- Declaração da variável de período para análise
DECLARE @dataPesquisa DATE = GETDATE() - 3;

-- Identificação de consultas duplicadas através de ROW_NUMBER e self-join
SELECT 
    T1.*
FROM (
    -- Subquery para identificar registros com RN > 1 (duplicatas)
    SELECT 
        *
    FROM (
        -- Query interna com ROW_NUMBER particionado por horário e especialidade
        SELECT 
            ROW_NUMBER() OVER (
                PARTITION BY 
                    C.DT_CNSUL_INI_PREV,
                    C.DT_CNSUL_FIM_PREV,
                    C.CD_ESPMD
                ORDER BY C.CD_CNSUL ASC
            ) AS RN
            , *
        FROM CNSUL AS C
        WHERE C.DT_CNSUL_REG >= @dataPesquisa
            AND C.ST_CNSUL NOT IN ('B')
            AND C.DS_CNSUL_OBS_AGEND NOT LIKE '%webservice%'
            AND C.DS_CNSUL_OBS_AGEND NOT LIKE '%video%'
    ) AS X
    WHERE X.RN > 1
) AS T2
INNER JOIN CNSUL AS T1
    ON T1.DT_CNSUL_INI_PREV = T2.DT_CNSUL_INI_PREV
    AND T1.DT_CNSUL_FIM_PREV = T2.DT_CNSUL_FIM_PREV
WHERE T1.DT_CNSUL_REG >= @dataPesquisa
    AND T1.ST_CNSUL NOT IN ('B')
    AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%webservice%'
    AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%video%'
ORDER BY T1.DT_CNSUL_INI_PREV ASC;
