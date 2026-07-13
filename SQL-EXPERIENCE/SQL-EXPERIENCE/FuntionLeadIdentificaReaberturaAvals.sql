-- Identifica reaberturas de avaliações
SELECT DISTINCT
       AD.CD_AVALS
--      ,AD.CD_PSSOA_CLENT
--      ,AD.CD_PSSOA_REG
--      ,AD.DT_AVALS
--      ,AD.ST_AVALS
--      ,AD.USR_REG
--      ,AD.Operacao
--      ,AD.DataAudit      
--      ,XNEXT.NEXT_STAVALS 
   
FROM AVALS_Audit AD
CROSS APPLY 
(
  SELECT 
  LEAD(AX.ST_AVALS) OVER (ORDER BY AX.DataAudit ASC) AS NEXT_STAVALS
  FROM AVALS_Audit AX
  WHERE AX.CD_AVALS = AD.CD_AVALS            
) AS XNEXT
WHERE --AD.CD_AVALS = 1579570
 AD.ST_AVALS = 'C'
AND XNEXT.NEXT_STAVALS = 'E'


