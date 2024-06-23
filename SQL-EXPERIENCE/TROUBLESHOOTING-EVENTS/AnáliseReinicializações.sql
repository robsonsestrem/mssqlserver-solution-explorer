---------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/sql-server-como-descobrir-ha-quanto-tempo-a-instancia-esta-online-ou-quando-a-instancia-foi-iniciada/
-- Últimas reincializações
---------------------------------------------------------------------------------------------------------------------------------------------------
--select * from sys.traces
--select * from sys.databases

SELECT sqlserver_start_time FROM sys.dm_os_sys_info


SELECT login_time 
FROM sys.dm_exec_sessions 
WHERE session_id = 1


SELECT start_time
FROM sys.traces
WHERE is_default = 1


SELECT DATEADD(ms, -sample_ms, GETDATE()) AS StartTime
FROM sys.dm_io_virtual_file_stats(1,1)


DECLARE @Retorno TABLE ( [LogDate] DATETIME, [ProcessInfo] NVARCHAR(12), [Text] NVARCHAR(3999) )
INSERT INTO @Retorno
EXEC xp_readerrorlog 0, 1, N'Copyright (c) Microsoft Corporation'
SELECT LogDate FROM @Retorno 


SELECT last_startup_time
FROM sys.dm_server_services
WHERE ServiceName LIKE 'SQL Server (%' 


SELECT login_time
FROM sys.sysprocesses
WHERE spid = 1


SELECT MAX(agent_start_date) AS agent_start_date
FROM msdb.dbo.syssessions

---------------------------------------------------------------------------------------------------------------------------------------------------
-- SQL Server Agente - histórico de reinicializações
-- https://www.dirceuresende.com/blog/como-consultar-o-historico-de-inicializacao-do-sql-agent-no-sql-server/
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    MIN(agent_start_date) AS Dt_Primeira_Inicializacao, 
    COUNT(*) AS Qt_Inicializacoes,
    MAX(agent_start_date) AS Dt_Ultima_Inicializacao 
FROM 
    msdb.dbo.syssessions

---------------------------------------------------------------------------------------------------------------------------------------------------
IF (OBJECT_ID('tempdb..#Dados') IS NOT NULL) DROP TABLE #Dados
SELECT 
    A.agent_start_date,
    DATEDIFF(DAY, B.agent_start_date, A.agent_start_date) AS Qt_Diferenca,
    DAY(A.agent_start_date) AS Dia,
    DATEPART(HOUR, A.agent_start_date) AS Hora,
    DATENAME(WEEKDAY, A.agent_start_date) AS Dia_Semana
INTO
    #Dados
FROM 
    msdb.dbo.syssessions		A
    JOIN msdb.dbo.syssessions	B	ON	A.session_id = B.session_id + 1


IF (OBJECT_ID('tempdb..#Dia_Mais_Inicializado') IS NOT NULL) DROP TABLE #Dia_Mais_Inicializado
SELECT Dia, COUNT(*) AS Quantidade
INTO #Dia_Mais_Inicializado
FROM #Dados 
GROUP BY Dia

IF (OBJECT_ID('tempdb..#Hora_Mais_Inicializada') IS NOT NULL) DROP TABLE #Hora_Mais_Inicializada
SELECT Hora, COUNT(*) AS Quantidade
INTO #Hora_Mais_Inicializada
FROM #Dados 
GROUP BY Hora

IF (OBJECT_ID('tempdb..#Dia_Semana_Mais_Inicializado') IS NOT NULL) DROP TABLE #Dia_Semana_Mais_Inicializado
SELECT Dia_Semana, COUNT(*) AS Quantidade
INTO #Dia_Semana_Mais_Inicializado
FROM #Dados 
GROUP BY Dia_Semana

DECLARE @Qt_Media_Dias_Entre_Inicializacoes INT = (SELECT AVG(Qt_Diferenca) FROM #Dados)


SELECT 
    @Qt_Media_Dias_Entre_Inicializacoes AS Qt_Media_Dias_Entre_Inicializacoes,
    (SELECT TOP 1 Dia FROM #Dia_Mais_Inicializado ORDER BY Quantidade DESC) AS Qt_Dia_Com_Mais_Inicializacoes,
    (SELECT TOP 1 Hora FROM #Hora_Mais_Inicializada ORDER BY Quantidade DESC) AS Qt_Hora_Com_Mais_Inicializacoes,
    (SELECT TOP 1 Dia_Semana FROM #Dia_Semana_Mais_Inicializado ORDER BY Quantidade DESC) AS Qt_Dia_Semana_Com_Mais_Inicializacoes