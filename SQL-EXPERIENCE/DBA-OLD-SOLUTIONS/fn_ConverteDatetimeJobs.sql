/*
 *
	OBJETIVO: Conversão das colunas run_date e run_time da tabela de catálogo
	          msdb.dbo.sysjobhistory para o tipo DATETIME, facilitando cálculos
	          e filtros temporais em rotinas de baseline e auditoria de Jobs.
	PROJETO: mssqlserver-solution-explorer
 */
-- ============================================================
-- Conversão de run_date e run_time 
-- do SQL Server Agent para DATETIME
-- ============================================================

USE [YOUR_DATABASE];
GO

-- Criação da função personalizada para conversão de run_date (yyyymmdd) e run_time (hmmss) em DATETIME
CREATE FUNCTION [Management].[fn_ConverteDatetimeJobs]
(
    @DATE INT,
    @TIME INT
)
RETURNS DATETIME
WITH ENCRYPTION
AS
BEGIN
    DECLARE @Date_Time DATETIME;
    DECLARE @Ds_Date VARCHAR(8) = @DATE;
    DECLARE @Ds_Time VARCHAR(8) = @TIME;

    -- Retorna nulo quando a data informada for zero (Job ainda não executado)
    IF (@DATE = 0)
        RETURN NULL;

    -- Padroniza a hora com zeros à esquerda e formata como HH:MM:SS
    SET @Ds_Time = RIGHT('000000' + @Ds_Time, 6);
    SET @Ds_Time = SUBSTRING(@Ds_Time, 1, 2) + ':' + SUBSTRING(@Ds_Time, 3, 2) + ':' + SUBSTRING(@Ds_Time, 5, 2);

    -- Concatena data e hora formatadas convertendo para DATETIME
    SET @Date_Time = CAST(@Ds_Date + ' ' + @Ds_Time AS DATETIME);

    RETURN @Date_Time;
END
GO

-- Exemplo de uso da função personalizada em consultas de Jobs com falha (run_status = 0)
SELECT
    [j].[name]
  , [h].[step_id]
  , [h].[step_name]
  , [h].[run_status]
  , [h].[message]
  , [RunDateTime] = [DBA_PerformanceHub].[Management].[fn_ConverteDatetimeJobs]([h].[run_date], [h].[run_time])
FROM [msdb].[dbo].[sysjobs] AS [j]
INNER JOIN [msdb].[dbo].[sysjobhistory] AS [h]
    ON [j].[job_id] = [h].[job_id]
WHERE [h].[run_status] = 0
  AND [h].[step_id] = 0;

-- Alternativa utilizando a função interna do SQL Server Agent (msdb.dbo.agent_datetime)
SELECT
    [j].[name]
  , [h].[step_id]
  , [h].[step_name]
  , [h].[run_status]
  , [h].[message]
  , [RunDateTime] = [msdb].[dbo].[agent_datetime]([h].[run_date], [h].[run_time])
  , [h].[run_date]
  , [h].[run_time]
FROM [msdb].[dbo].[sysjobs] AS [j]
INNER JOIN [msdb].[dbo].[sysjobhistory] AS [h]
    ON [j].[job_id] = [h].[job_id]
WHERE [h].[run_status] = 0
  AND [h].[step_id] = 0;

