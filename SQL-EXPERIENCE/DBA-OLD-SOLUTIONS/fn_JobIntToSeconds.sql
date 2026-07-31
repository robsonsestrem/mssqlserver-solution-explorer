/*
 *
	OBJETIVO: Conversão da duração de execução de Jobs do SQL Server Agent
	          (formato inteiro HHMMSS) para o total em segundos, permitindo
	          cálculos de soma e média de duração em rotinas de baseline.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	http://www.sqlservercentral.com/blogs/briankmcdonald/2010/10/29/sqlbigeek_1920_s-function-friday-1320-convert-job-duration-to-seconds/print/
 *	https://glutenfreesql.wordpress.com/2012/08/03/view-summary-of-sql-server-agent-jobs/
 */
-- ============================================================
-- Conversão de Duração de Job (HHMMSS) para Segundos
-- ============================================================
USE [YOUR_DATABASE]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- Criação da função para conversão de duração de job em segundos
-- Exemplo: 13210 (1 hora, 32 minutos e 10 segundos) retorna 5530 segundos
CREATE FUNCTION [Management].[fn_JobIntToSeconds]
(
    @run_duration INT
)
RETURNS INT
WITH ENCRYPTION
AS
BEGIN
    RETURN
        CASE
            -- Horas, minutos e segundos
            WHEN LEN(@run_duration) > 4 THEN
                CONVERT(VARCHAR(4), LEFT(@run_duration, LEN(@run_duration) - 4)) * 3600
                + LEFT(RIGHT(@run_duration, 4), 2) * 60
                + RIGHT(@run_duration, 2)
            -- Minutos e segundos
            WHEN LEN(@run_duration) = 4 THEN
                LEFT(@run_duration, 2) * 60
                + RIGHT(@run_duration, 2)
            WHEN LEN(@run_duration) = 3 THEN
                LEFT(@run_duration, 1) * 60
                + RIGHT(@run_duration, 2)
            -- Apenas segundos
            ELSE
                RIGHT(@run_duration, 2)
        END
END
GO
