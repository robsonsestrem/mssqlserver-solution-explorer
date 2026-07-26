/*
    OBJETIVO: Identificar páginas suspeitas (suspect_pages) e detectar
              corrupções em bancos de dados através da análise do log de erros,
              consolidando resultados de comandos DBCC CHECKDB executados.
    PROJETO: mssqlserver-solution-explorer
*/

SET NOCOUNT ON;

-- ============================================================
-- ALERTA: PÁGINA CORROMPIDA
-- ============================================================

SELECT
    SP.*
FROM
    msdb.dbo.suspect_pages AS SP;


-- ============================================================
-- ALERTA: CORRUPÇÃO DE DATABASES
-- ============================================================

SET DATEFORMAT MDY;

IF (OBJECT_ID('tempdb..#TempLog') IS NOT NULL)
    DROP TABLE #TempLog;

CREATE TABLE #TempLog
(
    LogDate     DATETIME,
    ProcessInfo NVARCHAR(50),
    Text        NVARCHAR(MAX)
);

IF (OBJECT_ID('tempdb..#logF') IS NOT NULL)
    DROP TABLE #logF;

CREATE TABLE #logF
(
    ArchiveNumber   INT,
    LogDate         DATETIME,
    LogSize         INT
);

-- Seleciona o número de arquivos
INSERT INTO #logF
EXEC sp_enumerrorlogs;

DELETE FROM #logF
WHERE LogDate < GETDATE() - 2;

DECLARE @TSQL NVARCHAR(2000);
DECLARE @lC INT;

SELECT @lC = MIN(ArchiveNumber) FROM #logF;

-- Loop para realizar a leitura de todo o log
WHILE @lC IS NOT NULL
BEGIN
    INSERT INTO #TempLog
    EXEC sp_readerrorlog @lC;

    SELECT @lC = MIN(ArchiveNumber)
    FROM #logF
    WHERE ArchiveNumber > @lC;
END;

IF OBJECT_ID('_Result_Corrupcao') IS NOT NULL
    DROP TABLE _Result_Corrupcao;

SELECT
    LogDate
  , SUBSTRING(Text, 15, CHARINDEX(')', Text, 15) - 15)                  AS Nm_Database
  , SUBSTRING
    (
        Text,
        CHARINDEX('found', Text),
        (CHARINDEX('Elapsed time', Text) - CHARINDEX('found', Text))
    )                                                                   AS Erros
  , Text
INTO
    _Result_Corrupcao
FROM
    #TempLog
WHERE
    LogDate >= GETDATE() - 1
    AND Text LIKE '%DBCC CHECKDB (%'
    AND Text NOT LIKE '%IDR%'
    AND SUBSTRING
        (
            Text,
            CHARINDEX('found', Text),
            CHARINDEX('Elapsed time', Text) - CHARINDEX('found', Text)
        ) <> 'found 0 errors and repaired 0 errors.';

-- Resultado da verificação
SELECT
    *
FROM
    _Result_Corrupcao;
