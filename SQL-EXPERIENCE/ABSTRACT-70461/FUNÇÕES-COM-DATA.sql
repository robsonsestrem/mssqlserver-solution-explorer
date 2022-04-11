---------------------------------------------------------------------------------------------------------------------------------------------------
-- Utilização de alguns tipos de funções de data
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  DATEADD(MILLISECOND, +997, DATEADD(SECOND, +59, DATEADD(MINUTE, +59, DATEADD(HOUR, +23, DATEADD(DAY, -1,

  CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)  -- floor usado para zerar e depois poder setar hora, minuto, etc
  )--dia
  )--hora
  )--minutos
  )--segundos
  )--milissegundos


---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  GETDATE() AS [GetDate]
 ,CURRENT_TIMESTAMP AS [Current_Timestamp]
 ,GETUTCDATE() AS [GetUTCDate]
 ,SYSDATETIME() AS [SYSDateTime]
 ,SYSUTCDATETIME() AS [SYSUTCDateTime]
 ,SYSDATETIMEOFFSET() AS [SYSDateTimeOffset];


---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  ISDATE('20120212'); --is valid
SELECT
  ISDATE('20120230'); --February doesn't have 30 days
SELECT
  DATENAME(YEAR, '20120212');
SELECT
  DATETIMEFROMPARTS(2012, 2, 12, 8, 30, 0, 0) AS Result; --7 arguments
SELECT
  DATETIME2FROMPARTS(2012, 2, 12, 8, 30, 00, 0, 0) AS Result; -- 8 arguments
SELECT
  DATEFROMPARTS(2012, 2, 12) AS Result; -- 3args
SELECT
  DATETIMEOFFSETFROMPARTS(2012, 2, 12, 8, 30, 0, 0, -7, 0, 0) AS Result;
SELECT
  DATEDIFF(MILLISECOND, GETDATE(), SYSDATETIME()); -- no datediff se subtrai o campo da direita para esquerda


---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  CURRENT_TIMESTAMP AS currentdatetime
 ,CAST(CURRENT_TIMESTAMP AS DATE) AS currentdate
 ,CAST(CURRENT_TIMESTAMP AS TIME) AS currenttime
 ,YEAR(CURRENT_TIMESTAMP) AS currentyear
 ,MONTH(CURRENT_TIMESTAMP) AS currentmonth
 ,DAY(CURRENT_TIMESTAMP) AS currentday
 ,DATEPART(WEEK, CURRENT_TIMESTAMP) AS currentweeknumber
 ,DATENAME(MONTH, CURRENT_TIMESTAMP) AS currentmonthname;
SELECT
  CAST(CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112) AS DATETIME) AS currentdate;
SELECT
  DATEADD(DAY, DATEDIFF(DAY, '20000101', CURRENT_TIMESTAMP), '20000101') AS currentdate;


---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
  DATEADD(MONTH, 3, CURRENT_TIMESTAMP) AS threemonths
 ,DATEDIFF(DAY, CURRENT_TIMESTAMP, DATEADD(MONTH, 3, CURRENT_TIMESTAMP)) AS diffdays
 ,DATEDIFF(WEEK, '19920404', '20110916') AS diffweeks
 ,DATEADD(DAY, -DAY(CURRENT_TIMESTAMP) + 1, CURRENT_TIMESTAMP) AS firstday; 


---------------------------------------------------------------------------------------------------------------------------------------------------
-- criando rotinas para exercícios
---------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ##ultimoDiaMes (
  mes SMALLINT
 ,dia SMALLINT
)

DECLARE @mesinicio DATE = DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP), 1, 1)
DECLARE @mesfim DATE = DATEFROMPARTS(YEAR(current_timestamp), 12, 31)

WHILE (@mesinicio <= @mesfim)
BEGIN
  INSERT INTO ##ultimoDiaMes (mes, dia)
    VALUES (MONTH(@mesinicio), DAY(EOMONTH(@mesinicio)))
  
  SET @mesinicio = DATEADD(MONTH, 1, @mesinicio)
END

SELECT
  *
FROM ##ultimoDiaMes

DROP TABLE ##ultimoDiaMes