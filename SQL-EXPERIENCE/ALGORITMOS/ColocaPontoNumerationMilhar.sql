/*
 *
	OBJETIVO: Demonstração de formatação de números com separadores de milhar
			  utilizando conversão para MONEY e manipulação de strings,
			  convertendo valores bigint para formato com vírgula ou ponto
			  a cada três dígitos, e também para gigabytes.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Conversão: coloca vírgula/ponto a cada milhar dos números
-- ============================================================
DECLARE @free_space_mb BIGINT

SET @free_space_mb = 187406112745679

SELECT
    REVERSE
    (
        SUBSTRING
        (
            REVERSE
            (
                CONVERT(VARCHAR(30), CONVERT(MONEY, @free_space_mb), 1)
            ),
            4,
            15
        )
    ) AS MegabytesVirgula,
    REPLACE
    (
        REVERSE
        (
            SUBSTRING
            (
                REVERSE
                (
                    CONVERT(VARCHAR(30), CONVERT(MONEY, @free_space_mb), 1)
                ),
                4,
                15
            )
        ),
        ',',
        '.'
    ) AS MegabytesPonto,
    CAST(@free_space_mb / 1024 AS DECIMAL(15, 2)) AS Gibabytes
GO
