/*
    OBJETIVO: Demonstrar técnicas para geração de números aleatórios no SQL Server,
              incluindo métodos para valores FLOAT e INT, além de alternativa com CHECKSUM.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    http://www.dbinternals.com.br/?p=51
    https://dba-pro.com/como-gerar-numeros-aleatorios-no-sql/
*/

-- ============================================================
-- SEÇÃO 1: Declaração de variáveis para definição do intervalo
-- ============================================================

-- Declaração das variáveis que definem os limites do número aleatório
DECLARE @Upper INT;
DECLARE @Lower INT;

-- Definição do valor mínimo do intervalo
SET @Lower = 1; -- The lowest random number

-- Definição do valor máximo do intervalo
SET @Upper = 999; -- The highest random number

-- ============================================================
-- SEÇÃO 2: Geração de número aleatório em formato FLOAT
-- ============================================================

-- Geração de número aleatório com casas decimais usando NEWID() como semente
SELECT 
    CAST((@Upper - @Lower - 1) * RAND(CAST(NEWID() AS VARBINARY)) + @Lower AS FLOAT) AS RandomFloat;

-- ============================================================
-- SEÇÃO 3: Geração de número aleatório em formato INT
-- ============================================================

-- Geração de número aleatório inteiro usando NEWID() como semente
SELECT 
    CAST((@Upper - @Lower - 1) * RAND(CAST(NEWID() AS VARBINARY)) + @Lower AS INT) AS RandomInt;

-- ============================================================
-- SEÇÃO 4: Alternativa com CHECKSUM e NEWID
-- ============================================================

-- Método alternativo usando CHECKSUM para gerar sequência numérica aleatória
SELECT 
    LEFT(REPLACE(CHECKSUM(NEWID()), '-', ''), 3) AS RandomChecksum;
