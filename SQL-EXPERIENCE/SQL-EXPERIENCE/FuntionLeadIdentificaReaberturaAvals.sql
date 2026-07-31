/*
	OBJETIVO: Identificar avaliações que foram reabertas, detectando registros
			  onde o status atual é 'C' (Cancelado/Encerrado) e o próximo
			  registro na sequência temporal (segundo a DataAudit) possui
			  status 'E' (Em andamento/Reaberto), utilizando a função LEAD
			  para acessar o próximo valor da linha.
	PROJETO: mssqlserver-solution-explorer
*/
SELECT DISTINCT
      AD.CD_AVALS
    -- , AD.CD_PSSOA_CLENT
    -- , AD.CD_PSSOA_REG
    -- , AD.DT_AVALS
    -- , AD.ST_AVALS
    -- , AD.USR_REG
    -- , AD.Operacao
    -- , AD.DataAudit
    -- , XNEXT.NEXT_STAVALS
FROM AVALS_Audit                                                                      AS AD
CROSS APPLY
(
    SELECT
          LEAD(AX.ST_AVALS) OVER (ORDER BY AX.DataAudit ASC)                         AS NEXT_STAVALS
    FROM AVALS_Audit                                                                  AS AX
    WHERE AX.CD_AVALS = AD.CD_AVALS
)                                                                                     AS XNEXT
WHERE -- AD.CD_AVALS = 1579570                                                        -- Filtro opcional para avaliação específica
      AD.ST_AVALS = 'C'
      AND XNEXT.NEXT_STAVALS = 'E';
