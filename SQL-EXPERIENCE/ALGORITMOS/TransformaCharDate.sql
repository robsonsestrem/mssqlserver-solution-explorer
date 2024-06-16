--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.sqlservercentral.com/Forums/Topic1526592-392-1.aspx
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
--WITH SampleData AS(
--SELECT CAST( '2013-12-30 12:09:00.123' AS CHAR(24)) AS CounterDateTime
--)

--SELECT 
--CONVERT(VARCHAR(10),convert(datetime,CounterDateTime),101) as Date,
--CONVERT(VARCHAR(5), convert(datetime,CounterDateTime), 108) + ' ' + SUBSTRING(CONVERT(VARCHAR(19), convert(datetime,CounterDateTime), 100),18,2) as Time 
--FROM SampleData


--WITH SampleData AS(
--SELECT CAST( '2013-12-30 12:09:00.123' AS CHAR(24)) AS CounterDateTime
--)
--SELECT 
--   CONVERT(VARCHAR(10),CONVERT(varchar,CounterDateTime),101) as Date,
--   SUBSTRING(CONVERT(VARCHAR(19), CounterDateTime, 100),12,5) as Time ,
--   convert(date,CounterDateTime) AS RealDate,
--   convert(time,CounterDateTime) As RealTime
--FROM SampleData


--with mySampleData(TheDate)
--AS
--(
--select convert(datetime,'2013-12-30 12:09:00.123')
--)
--select 
--  convert(date,TheDate) AS RealDate,
--  convert(time,TheDate,108) As RealTime,
--  convert(varchar,TheDate,101) AS SimpleDate,
--  convert(varchar,TheDate,108) As SimpleTime
--FROM mySampleData

--set dateformat dmy
SELECT 
cast(CONVERT(VARCHAR(10),CONVERT(varchar,CounterDateTime),101) as date) as [Date]
FROM dbo.CounterData




