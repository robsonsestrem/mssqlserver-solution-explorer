/*
 *
	OBJETIVO: Scripts de configuração e consulta do Service Broker para
			  monitoramento de processos bloqueados (BLOCKED_PROCESS_REPORT)
			  no SQL Server, incluindo criação de QUEUE, SERVICE, EVENT
			  NOTIFICATION, stored procedure de captura e rotinas de
			  análise de locks (XML parsing, totalização por dia/semana,
			  visão para PowerBI e contagem de logins distintos afetados).
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- =====================================================================================
-- Criação de objetos para coleta de processos bloqueados
-- =====================================================================================

---------------------------------------------------------------------------------------
-- 1. Habilitação do Service Broker e Trustworthy
---------------------------------------------------------------------------------------
-- É necessário alterar a configuração habilitando o Broker e o Trustworthy
USE DBA_PerformanceHub
GO

ALTER DATABASE DBA_PerformanceHub
SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO

ALTER DATABASE DBA_PerformanceHub SET ENABLE_BROKER
GO

-- Caso haja problema de mesmo ID do Service Broker:
-- ALTER DATABASE DBA_PerformanceHub SET NEW_BROKER

ALTER DATABASE DBA_PerformanceHub SET TRUSTWORTHY ON
GO

ALTER DATABASE DBA_PerformanceHub
SET MULTI_USER WITH ROLLBACK IMMEDIATE
GO

-- 
-- Automatizando o processo caso tenha problema de mesmo ID do Service Broker
-- 

-- DECLARE @SQL NVARCHAR(MAX)
-- BEGIN TRY
--     SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET ENABLE_BROKER WITH ROLLBACK IMMEDIATE '
--     PRINT @SQL
--     EXEC sp_executesql @SQL
-- END TRY
-- BEGIN CATCH
--     SET @SQL = 'ALTER DATABASE ' + DB_NAME() + ' SET NEW_BROKER WITH ROLLBACK IMMEDIATE '
--     PRINT @SQL
--     EXEC sp_executesql @SQL
-- END CATCH
-- GO


---------------------------------------------------------------------------------------
-- 2. Configuração do Threshold de Processo Bloqueado
---------------------------------------------------------------------------------------
-- Indicar em quanto tempo, em segundos, após o início do lock o report (queue) é criado.
-- Isso evita a geração de dados em excesso por locks que duram poucos segundos.
-- Parametrizando o servidor para gerar o evento/report (queue) de lock somente se o lock tiver mais de 10 segundos.
EXEC sp_configure 'show advanced options', 1
GO

sp_configure 'blocked process threshold', 10
GO

RECONFIGURE WITH OVERRIDE


---------------------------------------------------------------------------------------
-- 3. Criação da Tabela de Histórico de Processos Bloqueados
---------------------------------------------------------------------------------------
-- Primeiro crio a tabela que irá receber todos os eventos de locks dos bancos de dados
CREATE TABLE Gescooper90.dbo.HistoryBlockedProcess
(
    IdBlock INT IDENTITY(1, 1) NOT NULL
    , DateBlock DATETIME NULL
    , DatabaseName VARCHAR(255)
    , GraphBlock XML
    , CONSTRAINT PK_BlockedProcess PRIMARY KEY (IdBlock)
)


---------------------------------------------------------------------------------------
-- 4. Criação da QUEUE, SERVICE e EVENT NOTIFICATION
---------------------------------------------------------------------------------------
-- Em seguida crio a QUEUE, o Service e o Event Notification para esta coleta.
-- Na criação do Event a ação que é monitorada é o BLOCKED_PROCESS_REPORT.
USE DBA_PerformanceHub
GO

CREATE QUEUE Audit_Blocked_Process_Queue
GO

CREATE SERVICE Audit_Blocked_Process_Service
ON QUEUE Audit_Blocked_Process_Queue ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification])
GO

USE DBA_PerformanceHub
GO

CREATE EVENT NOTIFICATION Audit_Blocked_Process_Event
ON SERVER
WITH FAN_IN
FOR BLOCKED_PROCESS_REPORT
TO SERVICE N'Audit_Blocked_Process_Service', N'current database'
GO

-- Drop do Event Notification (quando necessário)
-- DROP EVENT NOTIFICATION Audit_Blocked_Process_Event
-- ON SERVER


---------------------------------------------------------------------------------------
-- 5. Stored Procedure de Captura dos Eventos
---------------------------------------------------------------------------------------
-- Os eventos vêm como XML (EVENT_INSTANCE) a partir de um SELECT na QUEUE Audit_Blocked_Process_Queue.
-- Como a stored procedure é acionada a cada evento, ela capta da QUEUE o XML, desserializa e grava cada campo na tabela HistoryBlockedProcess.
USE DBA_PerformanceHub
GO

CREATE PROCEDURE Management.sp_BlockedProcess
WITH EXECUTE AS OWNER, ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET ARITHABORT ON  -- adicionado 23-03-2017

    DECLARE
        @message_body AS XML
        , @event_datetime AS DATETIME
        , @DBname AS SYSNAME

    WHILE (1 = 1)
    BEGIN
        WAITFOR (
            RECEIVE TOP (1)
                @message_body = CAST(message_body AS XML)
            FROM dbo.Audit_Blocked_Process_Queue
        ), TIMEOUT 1000

        IF (@@ROWCOUNT = 1)
        BEGIN
            -- Seta variáveis
            SELECT
                @event_datetime = @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'datetime')
                , @DBname = DB_NAME(@message_body.value('(/EVENT_INSTANCE/TextData/blocked-process-report/blocked-process/process/@currentdb)[1]', 'varchar(10)'))

            -- Insere registros
            INSERT INTO DBA_PerformanceHub.Management.HistoryBlockedProcess
            (
                DateBlock
                , DatabaseName
                , GraphBlock
            )
            SELECT
                @event_datetime
                , @DBname
                , @message_body
        END
    END
END
GO


---------------------------------------------------------------------------------------
-- 6. Configuração da QUEUE com Activation
---------------------------------------------------------------------------------------
-- Em seguida configuro a QUEUE Audit_Blocked_Process_Queue para acionar a stored procedure
-- sp_BlockedProcess houver um evento e já ativar a QUEUE.
USE DBA_PerformanceHub
GO

ALTER QUEUE Audit_Blocked_Process_Queue
WITH ACTIVATION
(
    STATUS = ON
    , PROCEDURE_NAME = Management.sp_BlockedProcess
    , MAX_QUEUE_READERS = 1  -- número máximo de instâncias do procedimento armazenado que o Service Broker inicia para essa fila
    , EXECUTE AS OWNER
)
GO


-- =====================================================================================
-- Consulta de Análise dos Dados Coletados (XML Parsing)
-- =====================================================================================
USE DBA_PerformanceHub
GO

;WITH cte_BlockedProcess AS
(
    SELECT
        IdBlock
        , DateBlock
        , DatabaseName
        , GraphBlock
    FROM Management.HistoryBlockedProcess
    WHERE DateBlock >= '20180626'
)
, ExtraiXML AS
(
    SELECT
        -- CONVERT(VARCHAR(50), A.GraphBlock.query('data(/EVENT_INSTANCE/Duration)')) AS Duracao_ms
        REPLACE((CAST(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Duration)') AS VARCHAR(60)) AS MONEY) / 1000 / 1000), ',', '.') AS Segundos
        , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EventType)') AS VARCHAR(50)) AS Evento
        , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Inicio
        , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EndTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Fim
        , A.DatabaseName AS BD
        , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Mode)') AS VARCHAR(10)) AS Mode
        , BlockedProcess.Process.value('@lockMode', 'varchar(max)') AS LockMode
        , BlockedProcess.Process.value('@waitresource', 'varchar(max)') AS Waitresource
        -- CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/DatabaseID)') AS VARCHAR(10)) AS id_banco
        , BlockedProcess.Process.value('@clientapp', 'varchar(max)') AS Program_Blocked
        , BlockedProcess.Process.value('@spid', 'varchar(max)') AS SPID_Blocked
        , BlockedProcess.Process.value('@hostname', 'varchar(max)') AS Host_Blocked
        , BlockedProcess.Process.value('@loginname', 'varchar(max)') AS Login_Blocked
        , BlockedProcess.Process.value('@isolationlevel', 'varchar(max)') AS IsolationLevel_Blocked
        , REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST(BlockedProcess.Process.query('inputbuf') AS VARCHAR(MAX)), '<inputbuf>', '')), '</inputbuf>', '')), CHAR(10), ''), CHAR(13), ''), CHAR(9), '') AS Script_Blocked
        , BlockingProcess.Process.value('@clientapp', 'varchar(max)') AS Program_Blocking
        , BlockingProcess.Process.value('@spid', 'varchar(max)') AS SPID_Blocking
        , BlockingProcess.Process.value('@hostname', 'varchar(max)') AS Host_Blocking
        , BlockingProcess.Process.value('@loginname', 'varchar(max)') AS Login_Blocking
        , BlockingProcess.Process.value('@isolationlevel', 'varchar(max)') AS IsolationLevel_Blocking
        , REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST(BlockingProcess.Process.query('inputbuf') AS VARCHAR(MAX)), '<inputbuf>', '')), '</inputbuf>', '')), CHAR(10), ''), CHAR(13), ''), CHAR(9), '') AS Script_Blocking
    FROM cte_BlockedProcess AS A
    CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocked-process/process') AS BlockedProcess (Process)
    CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocking-process/process') AS BlockingProcess (Process)
)
SELECT
    *
FROM ExtraiXML AS xml
ORDER BY xml.Data_Inicio DESC


---------------------------------------------------------------------------------------
-- Contagem por LockMode excluindo scripts de leitura/escrita convencionais
---------------------------------------------------------------------------------------
SELECT
    COUNT(*) AS Total
    , xml.LockMode
FROM ExtraiXML AS xml
WHERE xml.Script_Blocking NOT LIKE '%select%'
    AND xml.Script_Blocking NOT LIKE '%update%'
    AND xml.Script_Blocking NOT LIKE '%insert%'
    AND xml.Script_Blocking NOT LIKE '%delete%'
    AND xml.Script_Blocking NOT LIKE '%Database Id%'
GROUP BY xml.LockMode
ORDER BY 1 DESC

-- No banco de dados SQL Server máximo por instância que podem ser criados são 32.767.
-- Este último número foi reservado pelo próprio Banco de Dados de Recursos.
-- Ele é localizado em -> C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL\Binn
-- Nome dele é "mssqlsystemresource"
SELECT
    SERVERPROPERTY('ResourceVersion') AS ResourceVersion
    , SERVERPROPERTY('ResourceLastUpdateDateTime') AS ResourceLastUpdateDateTime
GO

---------------------------------------------------------------------------------------
-- Totalização por Dia
---------------------------------------------------------------------------------------
-- Linha de tendência mostrará aumento nos totais diários e semanal de processos bloqueados,
-- indica e justifica baixa de performance.
SELECT
    COUNT(IdBlock) AS total
    , DatabaseName
FROM Management.HistoryBlockedProcess
WHERE DateBlock >= '2017-03-30 00:00:00.000' AND DateBlock <= '2017-03-30 23:59:59.997'
GROUP BY DatabaseName


SELECT
    COUNT(h.IdBlock) AS TotalBlock
    , CONVERT(VARCHAR(10), h.DateBlock, 103) AS Date
    , h.DatabaseName
FROM YOUR_DATABASE.Management.HistoryBlockedProcess AS h
WHERE h.DatabaseName IS NOT NULL
    AND h.DateBlock IS NOT NULL
    AND h.DateBlock BETWEEN '2017-03-24' AND GETDATE()  -- a data setada é a primeira registrada na rotina de coleta
GROUP BY
    SUBSTRING(CONVERT(VARCHAR(10), h.DateBlock, 103), 4, 2)
    , CONVERT(VARCHAR(10), h.DateBlock, 103)
    , h.DatabaseName


---------------------------------------------------------------------------------------
-- Totalização por Semana (comentado)
---------------------------------------------------------------------------------------
SELECT SUM(x.TotalBlock) AS total, MAX(x.DateBlock), x.DatabaseName FROM (
    SELECT
        COUNT(h.IdBlock) AS TotalBlock
        , CONVERT(VARCHAR(12), h.DateBlock, 103) AS DateBlock
        , h.DatabaseName
    FROM DBA_PerformanceHub.Management.HistoryBlockedProcess AS h
    WHERE h.DatabaseName IS NOT NULL AND h.DateBlock IS NOT NULL
        AND CAST(h.DateBlock AS DATE)
        BETWEEN DATEADD(WEEK, -1, CAST(CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME) AS DATE))
        AND CAST(GETDATE() AS DATE)
    GROUP BY SUBSTRING(CONVERT(VARCHAR(12), h.DateBlock, 103), 4, 2)
        , CONVERT(VARCHAR(12), h.DateBlock, 103)
        , h.DatabaseName
) AS x
GROUP BY x.DatabaseName


---------------------------------------------------------------------------------------
-- Cálculo Semanal com Variável de Decremento
---------------------------------------------------------------------------------------
-- No script abaixo foi calculado para trazer a data, porém é escolhido a última data do agrupamento
-- de count por base de dados, ou seja, tenho bloqueios numa base no dia 10 e no dia 11 ele me traz
-- a data do dia 11 e o total desses bloqueios.
-- Obs.: na última semana talvez pode duplicar a data pois ele calcula a data máxima de uma semana
-- pra frente e depois as anteriores na variável @decremento.
DECLARE
    @decremento AS SMALLINT
    , @limite AS SMALLINT
    , @dia AS DATETIME

IF (OBJECT_ID('tempdb.dbo.##semanas') IS NOT NULL)
BEGIN
    DROP TABLE ##semanas
END

CREATE TABLE ##semanas
(
    TotalBlock INT
    , DateBlock VARCHAR(12)
    , DatabaseName VARCHAR(50)
)

SET @limite = (SELECT DATEDIFF(WEEK, '2017-03-24', GETDATE()) * -1)  -- a data setada é a primeira registrada na rotina de coleta
SET @decremento = 1

WHILE (@limite <= @decremento)
BEGIN
    SET @dia = (SELECT CAST(DATEADD(WEEK, @decremento, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)) AS DATE))

    INSERT INTO ##semanas
    SELECT
        SUM(x.TotalBlock) AS TotalBlock
        , MAX(x.DateBlock) AS LastDayWeek
        , x.DatabaseName
    FROM (
        SELECT
            COUNT(h.IdBlock) AS TotalBlock
            , CONVERT(VARCHAR(12), h.DateBlock, 103) AS DateBlock
            , h.DatabaseName
        FROM YOUR_DATABASE.Management.HistoryBlockedProcess AS h
        WHERE h.DatabaseName IS NOT NULL
            AND h.DateBlock IS NOT NULL
            AND CAST(h.DateBlock AS DATE)
            BETWEEN DATEADD(WEEK, -1, CAST(CAST(FLOOR(CAST(@dia AS FLOAT)) AS DATETIME) AS DATE))
            AND CAST(@dia AS DATE)
        GROUP BY
            SUBSTRING(CONVERT(VARCHAR(12), h.DateBlock, 103), 4, 2)
            , CONVERT(VARCHAR(12), h.DateBlock, 103)
            , h.DatabaseName
    ) AS x
    GROUP BY x.DatabaseName

    SET @decremento = @decremento - 1
END

SELECT
    s.TotalBlock
    , s.DateBlock
    , s.DatabaseName
FROM ##semanas AS s

IF (OBJECT_ID('tempdb.dbo.##semanas') IS NOT NULL)
BEGIN
    DROP TABLE ##semanas
END


---------------------------------------------------------------------------------------
-- Nova Visão para PowerBI
---------------------------------------------------------------------------------------
SELECT
    x.DateBlock AS [Data de Referência]
    , x.DatabaseName AS [Nome Database]
    , COUNT(x.IdBlock) AS [Total Block]
FROM (
    SELECT
        h.IdBlock
        , CAST(h.DateBlock AS DATE) AS DateBlock
        , h.DatabaseName
    FROM YOUR_DATABASE.Management.HistoryBlockedProcess AS h
    WHERE h.DatabaseName IS NOT NULL
        AND h.DateBlock IS NOT NULL
) AS x
GROUP BY
    x.DateBlock
    , x.DatabaseName


---------------------------------------------------------------------------------------
-- Contagem de Usuários Distintos por Dia Afetados por Bloqueio
---------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO

;WITH cte_BlockedProcess AS
(
    SELECT
        IdBlock
        , DateBlock
        , DatabaseName
        , GraphBlock
    FROM Management.HistoryBlockedProcess
)
, ExtraiXML AS
(
    SELECT
        A.IdBlock
        , REPLACE((CAST(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Duration)') AS VARCHAR(60)) AS MONEY) / 1000 / 1000), ',', '.') AS Segundos
        , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EventType)') AS VARCHAR(50)) AS Evento
        , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/StartTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Inicio
        , REPLACE(CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/EndTime)') AS VARCHAR(23)), 'T', ' ') AS Data_Fim
        , A.DatabaseName AS BD
        , CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/Mode)') AS VARCHAR(10)) AS Mode
        , BlockedProcess.Process.value('@lockMode', 'varchar(max)') AS LockMode
        , BlockedProcess.Process.value('@waitresource', 'varchar(max)') AS Waitresource
        -- CAST(A.GraphBlock.query('data(/EVENT_INSTANCE/DatabaseID)') AS VARCHAR(10)) AS id_banco
        , BlockedProcess.Process.value('@clientapp', 'varchar(max)') AS Program_Blocked
        , BlockedProcess.Process.value('@spid', 'varchar(max)') AS SPID_Blocked
        , BlockedProcess.Process.value('@hostname', 'varchar(max)') AS Host_Blocked
        , BlockedProcess.Process.value('@loginname', 'varchar(max)') AS Login_Blocked
        , BlockedProcess.Process.value('@isolationlevel', 'varchar(max)') AS IsolationLevel_Blocked
        , REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST(BlockedProcess.Process.query('inputbuf') AS VARCHAR(MAX)), '<inputbuf>', '')), '</inputbuf>', '')), CHAR(10), ''), CHAR(13), ''), CHAR(9), '') AS Script_Blocked
        , BlockingProcess.Process.value('@clientapp', 'varchar(max)') AS Program_Blocking
        , BlockingProcess.Process.value('@spid', 'varchar(max)') AS SPID_Blocking
        , BlockingProcess.Process.value('@hostname', 'varchar(max)') AS Host_Blocking
        , BlockingProcess.Process.value('@loginname', 'varchar(max)') AS Login_Blocking
        , BlockingProcess.Process.value('@isolationlevel', 'varchar(max)') AS IsolationLevel_Blocking
        , REPLACE(REPLACE(REPLACE(RTRIM(REPLACE(REPLACE(CAST(BlockingProcess.Process.query('inputbuf') AS VARCHAR(MAX)), '<inputbuf>', '')), '</inputbuf>', '')), CHAR(10), ''), CHAR(13), ''), CHAR(9), '') AS Script_Blocking
    FROM cte_BlockedProcess AS A
    CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocked-process/process') AS BlockedProcess (Process)
    CROSS APPLY A.GraphBlock.nodes('//blocked-process-report/blocking-process/process') AS BlockingProcess (Process)
)
SELECT DISTINCT
    COUNT(y.TotalPorDia) OVER (PARTITION BY y.data) AS [Total Logins Bloqueados Distintos]
    , y.data AS [Data]
    , COALESCE(y.BD, '') AS [Database]
FROM (
    SELECT
        ROW_NUMBER() OVER (ORDER BY x.Login_Blocked) AS TotalPorDia
        , x.Login_Blocked
        , x.data
        , x.BD
    FROM (
        SELECT DISTINCT
            xml.Login_Blocked
            , CAST(xml.Data_Inicio AS DATE) AS data
            , xml.BD
        FROM ExtraiXML AS xml
        -- WHERE xml.BD = 'YOUR_DATABASE'
    ) AS x
) AS y


-- ============================================================
-- Retenção de dados - Tabela HistoryBlockedProcess
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_DeleteHistoryLocks
(
    @qtdadeManterDias INT = 365 -- Quantidade de dias para manter
)
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY
        BEGIN TRANSACTION

        -- ============================================================
        -- Bloco 01: Contagem de dias distintos com histórico de bloqueio
        -- ============================================================
        DECLARE @qtdadeDias INT
              , @dataMin DATE

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Registros)
            FROM
            (
                SELECT COUNT(*) AS [Registros]
                FROM [YOUR_DATABASE].[Management].HistoryBlockedProcess AS t1
                GROUP BY CAST(t1.DateBlock AS DATE)
            ) AS x
        )

        -- ============================================================
        -- Bloco 02: Loop de exclusão dos dias excedentes
        -- ============================================================
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT CAST(DATEADD(DAY, 1,
                (
                    SELECT MIN(t1.DateBlock)
                    FROM [YOUR_DATABASE].[Management].HistoryBlockedProcess AS t1
                )) AS DATE)
            )

            DELETE FROM [YOUR_DATABASE].[Management].HistoryBlockedProcess
            WHERE DateBlock < @dataMin

            SET @qtdadeDias -= 1
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Bloco 03: Variáveis para envio de e-mail de falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100) -- assunto
              , @recipients VARCHAR(100); -- destinatário

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';
        SET @corpoFalha = ''

        -- ============================================================
        -- Bloco 04: Montagem do corpo do e-mail de falha
        -- ============================================================
        SELECT @corpoFalha = @corpoFalha + '
        | Falha na procedure [sp_DeleteHistoryLocks]:
        |
        | ---|---|---|
        |    [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
        |      [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
        |      [MESSAGE] - ' + ERROR_MESSAGE() + '
        |
        '

        SELECT @corpoFalha = @corpoFalha + ''

        -- ============================================================
        -- Bloco 05: Envio do e-mail de falha
        -- ============================================================
        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients
          , @subject = @subject
          , @profile_name = 'CRAVIL'
          , @body = @corpoFalha
          , @body_format = 'HTML';
    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO
