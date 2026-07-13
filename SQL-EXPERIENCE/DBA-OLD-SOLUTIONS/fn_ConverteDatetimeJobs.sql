------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Veremos como converter as colunas run_date e run_time da tabela de cat�logo do banco msdb.dbo.sysjobhistory para datetime. 
-- Atualmente, a coluna run_date � um varchar no formato yyyymmdd (Ex: 07/05/2015 = 20150507), 
-- e a coluna run_time � uma hora no formato hmmss (Ex: 08:27:00 = 82700). 
-- At� d� pra entender visualmente o que significam esses valores, mas o c�lculo com essas datas e horas ficam bem mais complicado.
------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Usada no BaseLine di�rio
------------------------------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO

/****** Object:  UserDefinedFunction [dbo].[fn_ConverteDatetimeJobs]    Script Date: 19/04/2017 11:07:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO
 
CREATE FUNCTION Management.[fn_ConverteDatetimeJobs]
(
    @DATE INT,
    @TIME INT
)
RETURNS datetime
WITH ENCRYPTION
AS BEGIN
 
    DECLARE @Date_Time datetime
 
    DECLARE @Ds_Date VARCHAR(8) = @DATE
    DECLARE @Ds_Time VARCHAR(8) = @TIME
 
    IF (@DATE = 0) RETURN NULL
 
    SET @Ds_Time = RIGHT('000000'+@Ds_Time,6)
    SET @Ds_Time = SUBSTRING(@Ds_Time,1,2)+':'+SUBSTRING(@Ds_Time,3,2)+':'+SUBSTRING(@Ds_Time,5,2)
 
    SET @Date_Time = CAST(@Ds_Date + ' ' + @Ds_Time AS datetime)
 
    RETURN @Date_Time	
END
GO

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Colocando a fun��o personalizada em uso
-----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    j.name,
    h.step_id,
    h.step_name,
    h.run_status,
    h.message,
    [RunDateTime] = IntegraTICravil.Management.fn_Converte_Datetime_Jobs(h.run_date, h.run_time)
FROM
    [msdb].[dbo].[sysjobs] j
    JOIN [msdb].[dbo].sysjobhistory h ON j.job_id = h.job_id
WHERE
    h.run_status = 0 
    AND h.step_id = 0


------------------------------------------------------------------------------------------------------------------------------------------------------------
-- ABAIXO OP��O J� EXISTENTE TAMB�M NO SQL SERVER (A DE CIMA � PERSONALIZADA)
------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    j.name,
    h.step_id,
    h.step_name,
    h.run_status,
    h.message,
    [RunDateTime] = msdb.dbo.agent_datetime(h.run_date, h.run_time), -- FUN��O INTERNA
    h.run_date,
    h.run_time
FROM
    [msdb].[dbo].[sysjobs] j
    JOIN [msdb].[dbo].sysjobhistory h ON j.job_id = h.job_id
WHERE
    h.run_status = 0 AND h.step_id = 0