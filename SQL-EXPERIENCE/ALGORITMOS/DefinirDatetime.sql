/*
 *
	OBJETIVO: Demonstração de construção de uma data/hora específica no SQL Server
			  utilizando DATEADD para definir valores personalizados de dia, hora,
			  minuto, segundo e milissegundo a partir da data atual.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Definir datetime com valores 
-- específicos de dia, hora, minuto, segundo e milissegundo
-- ============================================================
SELECT
    DATEADD
    (
        MILLISECOND, +997,
        DATEADD
        (
            SECOND, +59,
            DATEADD
            (
                MINUTE, +59,
                DATEADD
                (
                    HOUR, +23,
                    DATEADD
                    (
                        DAY, -1,
                        CAST
                        (
                            FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME
                        )
                    )
                )
            )
        )
    ) AS DataHoraCustomizada
GO
