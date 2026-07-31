/*
 *
    OBJETIVO: Scripts de referência para funções de data e hora no SQL Server:
              obtenção de timestamp corrente (GETDATE, SYSDATETIME, etc.),
              validação de datas (ISDATE), construção de datas a partir de
              partes (DATEFROMPARTS, DATETIMEFROMPARTS, DATETIME2FROMPARTS,
              DATETIMEOFFSETFROMPARTS), cálculos com DATEADD e DATEDIFF,
              extração de componentes (YEAR, MONTH, DAY, DATEPART, DATENAME)
              e rotina com WHILE para listar o último dia de cada mês do ano.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIA: Curso ProWay - https://proway.com.br/
 * 
 */
-- ============================================================
-- Cálculo de timestamp com componentes aninhados via DATEADD
-- ============================================================
-- Calcula o último milissegundo do dia anterior ao atual:
-- 1. FLOOR(CAST(GETDATE() AS FLOAT)) zera a parte de tempo (meia-noite de hoje)
-- 2. DATEADD(DAY, -1, ...) recua um dia (meia-noite de ontem)
-- 3. DATEADD(HOUR, 23, ...) avança 23 horas (23:00 de ontem)
-- 4. DATEADD(MINUTE, 59, ...) avança 59 minutos (23:59 de ontem)
-- 5. DATEADD(SECOND, 59, ...) avança 59 segundos (23:59:59 de ontem)
-- 6. DATEADD(MILLISECOND, 997, ...) avança 997ms (23:59:59.997 de ontem)
SELECT
    DATEADD(MILLISECOND, 997, DATEADD(SECOND, 59, DATEADD(MINUTE, 59, DATEADD(HOUR, 23, DATEADD(DAY, -1,
        CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)  -- floor usado para zerar e depois poder setar hora, minuto, etc
    )))))


-- ============================================================
-- Funções de obtenção de timestamp corrente
-- ============================================================
-- Compara as diferentes funções de data/hora do sistema:
-- GETDATE()           — datetime sem offset (precisão de milissegundos)
-- CURRENT_TIMESTAMP   — equivalente ANSI do GETDATE()
-- GETUTCDATE()        — datetime em UTC sem offset
-- SYSDATETIME()       — datetime2 com precisão de nanossegundos
-- SYSUTCDATETIME()    — datetime2 em UTC com precisão de nanossegundos
-- SYSDATETIMEOFFSET() — datetimeoffset com precisão de nanossegundos e offset de fuso
SELECT
      GETDATE()             AS [GetDate]
    , CURRENT_TIMESTAMP     AS [Current_Timestamp]
    , GETUTCDATE()          AS [GetUTCDate]
    , SYSDATETIME()         AS [SYSDateTime]
    , SYSUTCDATETIME()      AS [SYSUTCDateTime]
    , SYSDATETIMEOFFSET()   AS [SYSDateTimeOffset];


-- ============================================================
-- Validação de datas com ISDATE
-- ============================================================
-- ISDATE retorna 1 se a string é uma data válida, 0 caso contrário
SELECT
    ISDATE('20120212');     -- 1 (válido: 12 de fevereiro de 2012)

SELECT
    ISDATE('20120230');     -- 0 (inválido: fevereiro não tem 30 dias)


-- ============================================================
-- Extração de nome de componente com DATENAME
-- ============================================================
-- DATENAME retorna o nome por extenso do componente especificado
SELECT
    DATENAME(YEAR, '20120212');


-- ============================================================
-- Construção de datas a partir de partes (FROMPARTS)
-- ============================================================
-- DATETIMEFROMPARTS: 7 argumentos (ano, mês, dia, hora, minuto, segundo, milissegundo)
SELECT
    DATETIMEFROMPARTS(2012, 2, 12, 8, 30, 0, 0) AS Result;

-- DATETIME2FROMPARTS: 8 argumentos (ano, mês, dia, hora, minuto, segundo, frações, precisão)
SELECT
    DATETIME2FROMPARTS(2012, 2, 12, 8, 30, 00, 0, 0) AS Result;

-- DATEFROMPARTS: 3 argumentos (ano, mês, dia) — retorna tipo DATE
SELECT
    DATEFROMPARTS(2012, 2, 12) AS Result;

-- DATETIMEOFFSETFROMPARTS: 10 argumentos (ano, mês, dia, hora, minuto, segundo, frações, offset_hora, offset_min, precisão)
SELECT
    DATETIMEOFFSETFROMPARTS(2012, 2, 12, 8, 30, 0, 0, -7, 0, 0) AS Result;


-- ============================================================
-- Diferença entre datas com DATEDIFF
-- ============================================================
-- DATEDIFF(MILLISECOND, ...): retorna a diferença em milissegundos
-- entre GETDATE() (datetime) e SYSDATETIME() (datetime2)
-- OBS: no DATEDIFF, subtrai-se o segundo argumento (direita) do primeiro (esquerda)
SELECT
    DATEDIFF(MILLISECOND, GETDATE(), SYSDATETIME());


-- ============================================================
-- Extração de componentes de data corrente
-- ============================================================
-- Extrai componentes individuais da data/hora corrente
SELECT
      CURRENT_TIMESTAMP                     AS currentdatetime
    , CAST(CURRENT_TIMESTAMP AS DATE)      AS currentdate
    , CAST(CURRENT_TIMESTAMP AS TIME)      AS currenttime
    , YEAR(CURRENT_TIMESTAMP)              AS currentyear
    , MONTH(CURRENT_TIMESTAMP)             AS currentmonth
    , DAY(CURRENT_TIMESTAMP)               AS currentday
    , DATEPART(WEEK, CURRENT_TIMESTAMP)    AS currentweeknumber
    , DATENAME(MONTH, CURRENT_TIMESTAMP)   AS currentmonthname;

-- Extrai apenas a data (sem hora) usando CONVERT com estilo 112 (ISO: YYYYMMDD)
SELECT
    CAST(CONVERT(CHAR(8), CURRENT_TIMESTAMP, 112) AS DATETIME) AS currentdate;

-- Extrai apenas a data (sem hora) usando DATEADD + DATEDIFF
-- Técnica: calcula os dias desde '20000101' e adiciona a essa data base
SELECT
    DATEADD(DAY, DATEDIFF(DAY, '20000101', CURRENT_TIMESTAMP), '20000101') AS currentdate;


-- ============================================================
-- Cálculos diversos com DATEADD e DATEDIFF
-- ============================================================
-- Adiciona 3 meses à data corrente e calcula a diferença em dias
-- Também calcula diferença em semanas entre duas datas fixas e o primeiro dia do mês corrente
SELECT
      DATEADD(MONTH, 3, CURRENT_TIMESTAMP)                                AS threemonths
    , DATEDIFF(DAY, CURRENT_TIMESTAMP, DATEADD(MONTH, 3, CURRENT_TIMESTAMP)) AS diffdays
    , DATEDIFF(WEEK, '19920404', '20110916')                              AS diffweeks
    , DATEADD(DAY, -DAY(CURRENT_TIMESTAMP) + 1, CURRENT_TIMESTAMP)        AS firstday;


-- ============================================================
-- Rotina: listar o último dia de cada mês do ano corrente
-- ============================================================
-- Cria tabela temporária global para armazenar os resultados
CREATE TABLE ##ultimoDiaMes (
      mes SMALLINT
    , dia SMALLINT
)

-- Declara as variáveis de controle do loop
-- @mesinicio: 1º de janeiro do ano corrente
-- @mesfim: 31 de dezembro do ano corrente
DECLARE
      @mesinicio DATE = DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP), 1, 1)
    , @mesfim   DATE = DATEFROMPARTS(YEAR(CURRENT_TIMESTAMP), 12, 31)

-- Percorre todos os meses do ano corrente
WHILE (@mesinicio <= @mesfim)
BEGIN
    -- Insere o número do mês e o último dia desse mês (via EOMONTH)
    INSERT INTO ##ultimoDiaMes (mes, dia)
        VALUES (MONTH(@mesinicio), DAY(EOMONTH(@mesinicio)))

    -- Avança para o próximo mês
    SET @mesinicio = DATEADD(MONTH, 1, @mesinicio)
END

-- Retorna todos os meses com seus respectivos últimos dias
SELECT
    *
FROM
    ##ultimoDiaMes

-- Remove a tabela temporária global
DROP TABLE ##ultimoDiaMes
