/*
 *
	OBJETIVO: Conversão de valores inteiros representando segundos totais
	          para formato de tempo HH:MM:SS, utilizada em campos de sistemas
	          que armazenam duração em minutos ou segundos totais.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	http://www.sqlservercentral.com/scripts/Converter+Inteiro+em+Horas/73984/
 */
-- ============================================================
-- Conversão de Inteiro para Formato de Tempo (HH:MM:SS)
-- ============================================================

USE [YOUR_DATABASE];
GO

-- Criação da função para conversão de segundos totais em formato HH:MM:SS
CREATE OR ALTER FUNCTION [Management].[fn_IntToTime]
(
    @TEMPO INT
)
RETURNS VARCHAR(20)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @HORARIO VARCHAR(20);
    DECLARE @HORA INT;
    DECLARE @MINUTO INT;
    DECLARE @SEGUNDO INT;

    -- Cálculo de horas, minutos e segundos a partir do total de segundos
    SET @HORA = (@TEMPO / 3600);
    SET @MINUTO = (@TEMPO % 3600) / 60;
    SET @SEGUNDO = (@TEMPO % 3600) % 60;

    -- Formatação do horário com zeros à esquerda quando necessário
    SELECT @HORARIO =
        CASE
            WHEN @TEMPO / 3600 >= 1 THEN
                CASE
                    WHEN LEN(CAST(@HORA AS VARCHAR)) = 1 THEN '0'
                    ELSE ''
                END
                + CAST(@HORA AS VARCHAR) + ':'
                + CASE
                    WHEN LEN(CAST(@MINUTO AS VARCHAR)) = 1 THEN '0'
                    ELSE ''
                END
                + CAST(@MINUTO AS VARCHAR) + ':'
                + CASE
                    WHEN LEN(CAST(@SEGUNDO AS VARCHAR)) = 1 THEN '0'
                    ELSE ''
                END
                + CAST(@SEGUNDO AS VARCHAR)
            ELSE
                CASE
                    WHEN LEN(CAST(@MINUTO AS VARCHAR)) = 1 THEN '0'
                    ELSE ''
                END
                + CAST(@MINUTO AS VARCHAR) + ':'
                + CASE
                    WHEN LEN(CAST(@SEGUNDO AS VARCHAR)) = 1 THEN '0'
                    ELSE ''
                END
                + CAST(@SEGUNDO AS VARCHAR)
        END;

    RETURN @HORARIO;
END
GO


------------------------------------------------------------------
-- Exemplo de uso: cálculo de horas e minutos 
-- a partir de segundos totais
-- 528 segundos = 8 minutos e 48 segundos 
-- (528 / 60 = 8 horas, 528 % 60 = 48 minutos)
------------------------------------------------------------------
SELECT
    [Management].[dbo].[fn_IntToTime](528) AS [HorarioFormatado]
  , 528 / 60 AS [Horas]
  , 528 % 60 AS [Minutos];
