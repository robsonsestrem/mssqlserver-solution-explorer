/*
 *
	OBJETIVO: Demonstração de cálculos de diferença entre datas no SQL Server,
			  totalizando dias, horas, minutos e segundos entre uma data de
			  chegada e a data/hora atual, utilizando funções de data.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	http://www.tek-tips.com/viewthread.cfm?qid=1284504
 */
-- ============================================================
-- Conversões para trazer dias, horas, minutos, segundos etc...
-- ============================================================
DECLARE @Temp TABLE
(
    ArrivalDate DATETIME
)

SET DATEFORMAT MDY

INSERT INTO @Temp VALUES('10-01-2006 18:00:00')
INSERT INTO @Temp VALUES('09-30-2006 11:30:00')
INSERT INTO @Temp VALUES('09-29-2006 20:00:00')
INSERT INTO @Temp VALUES('10-02-2006 08:00:00')
INSERT INTO @Temp VALUES('10-01-2006 15:00:00')
INSERT INTO @Temp VALUES('09-27-2006 00:09:00')

SELECT
    ArrivalDate,
    DATEDIFF(HOUR, ArrivalDate, GETDATE()) / 24 AS Days,
    DATEDIFF
    (
        MINUTE,
        DATEADD
        (
            DAY,
            DATEDIFF(HOUR, ArrivalDate, GETDATE()) / 24,
            ArrivalDate
        ),
        GETDATE()
    ) / 60 AS Hours,
    DATEDIFF
    (
        SECOND,
        DATEADD
        (
            HOUR,
            DATEDIFF
            (
                MINUTE,
                DATEADD
                (
                    DAY,
                    DATEDIFF(HOUR, ArrivalDate, GETDATE()) / 24,
                    ArrivalDate
                ),
                GETDATE()
            ) / 60,
            DATEADD
            (
                DAY,
                DATEDIFF(HOUR, ArrivalDate, GETDATE()) / 24,
                ArrivalDate
            )
        ),
        GETDATE()
    ) / 60 AS Seconds
FROM @Temp
GO
