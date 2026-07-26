/*
	OBJETIVO: Extrair o texto da consulta SQL a partir de um sql_handle fornecido,
			  utilizando a função sys.dm_exec_sql_text para recuperar o comando
			  armazenado em cache.
	PROJETO: mssqlserver-solution-explorer
*/

-- ====================================================================
-- Coluna sql_handle da tabela sysprocesses (ou sys.dm_exec_requests)
-- fornece este valor para extração do texto da consulta.
-- ====================================================================
DECLARE @handle VARBINARY(64) = 0x010005001973DB3210D50E0D0600000000000000; -- valor ilustrativo
DECLARE @start  INT           = 100;
DECLARE @end    INT           = -1;

SELECT
      SUBSTRING
      (
          [text]
        , @start / 2
        , CASE
              WHEN @end > 0
              THEN (@end - @start) / 2
              ELSE LEN([text])
          END
      )                                                                          AS QueryText
FROM sys.dm_exec_sql_text(@handle);
