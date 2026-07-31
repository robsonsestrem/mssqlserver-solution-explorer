/*
 *
	OBJETIVO: Demonstração de geração de todas as 24 horas de um dia específico
			  utilizando a tabela de sistema master..spt_values como fonte
			  de números para construir a lista de horas da data atual.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Listando todas as horas de um dia, com base na data atual
-- ============================================================
SELECT
    DATEADD
    (
        HOUR,
        number,
        DATEADD
        (
            DAY,
            DATEDIFF(DAY, 0, GETDATE()),
            0
        )
    ) AS HoraDoDia
FROM master..spt_values AS n WITH (NOLOCK)
WHERE number BETWEEN 0 AND 23
    AND type = 'p'
GO
