---------------------------------------------------------------------------------------------------------------
-- https://healthmap.atlassian.net/browse/HMAP-1075
-- PROF DE EXEMPLO
-- INTERVALO DE EXEMPLO: C.DT_CNSUL_INI_PREV BETWEEN '2023-02-14 14:00:00' AND '2023-02-14 14:20:00'
-- SELECT * FROM PSSOA p WHERE P.NM_PSSOA LIKE '%RONNE HEDILI%' -- 609852
---------------------------------------------------------------------------------------------------------------
-- CONSULTA TESTE
SELECT 
ROW_NUMBER() OVER (PARTITION BY C.DT_CNSUL_INI_PREV, C.DT_CNSUL_FIM_PREV, C.CD_ESPMD ORDER BY C.CD_CNSUL ASC) AS RN
, * 
FROM CNSUL C
WHERE 
 --C.ST_CNSUL IN ('D', 'F') AND C.DS_CNSUL_OBS_AGEND NOT LIKE '%webservice%'    
 C.CD_PSSOA_PROF = 609852
AND C.DT_CNSUL_INI_PREV BETWEEN '2023-02-14 14:00:00' AND '2023-02-14 14:21:00'


---------------------------------------------------------------------------------------------------------------
-- MONITORA
---------------------------------------------------------------------------------------------------------------
DECLARE @dataPesquisa DATE = GETDATE()-3;
SELECT T1.*
FROM (
    SELECT * FROM (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY C.DT_CNSUL_INI_PREV, C.DT_CNSUL_FIM_PREV, C.CD_ESPMD ORDER BY C.CD_CNSUL ASC) AS RN        
            , * 
        FROM CNSUL C
        WHERE C.DT_CNSUL_REG >= @dataPesquisa
        AND C.ST_CNSUL NOT IN ('B') 
        AND C.DS_CNSUL_OBS_AGEND NOT LIKE '%webservice%'  
        AND C.DS_CNSUL_OBS_AGEND NOT LIKE '%video%'   
    ) AS X
    WHERE X.RN > 1
) T2
INNER JOIN CNSUL T1 ON T1.DT_CNSUL_INI_PREV = T2.DT_CNSUL_INI_PREV AND T1.DT_CNSUL_FIM_PREV = T2.DT_CNSUL_FIM_PREV
WHERE T1.DT_CNSUL_REG >= @dataPesquisa
AND T1.ST_CNSUL NOT IN ('B') 
AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%webservice%'  
AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%video%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%whats%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%remarcou%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%reagend%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%cancel%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%desmarc%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%remaneja%'
--AND T1.DS_CNSUL_OBS_AGEND NOT LIKE '%falt%'
ORDER BY T1.DT_CNSUL_INI_PREV ASC


