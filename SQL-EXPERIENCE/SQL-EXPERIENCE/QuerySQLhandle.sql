--------------------------------------------------------------------------------------------------
-- Coluna sql_handle da tabela sysprocess traz este valor para extrair
--------------------------------------------------------------------------------------------------
DECLARE @handle VARBINARY(64) = 0x010005001973DB3210D50E0D0600000000000000 -- valor ilustrativo
DECLARE @start  INT = 100
DECLARE @end    INT = -1
DECLARE @len    INT
                        
SELECT SUBSTRING(text,@start/2,
            CASE WHEN @end > 0    
                THEN  (@end - @start)/2
                ELSE  LEN([text]) 
            END) 
FROM sys.dm_exec_sql_text(@handle)