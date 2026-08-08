/*
 *
    OBJETIVO: Dignóstico completo do SQL Server Agent no Linux.
    Testes gerais sobre funcionamento dessa solução.
    
    PROJETO: mssqlserver-solution-explorer    
*
*/
-- ============================================================
-- 1. COMANDOS T-SQL PARA DIAGNOSTICO E VALIDACAO
-- ============================================================

-- --------------------------------------------------------------
-- 1.1. VERIFICACAO DA VERSAO DO SQL SERVER
-- --------------------------------------------------------------
SELECT
    @@VERSION AS [SQLServerVersion]
GO

-- --------------------------------------------------------------
-- 1.2. VERIFICAR O NOME DO SERVIDOR REGISTRADO NO SQL SERVER
-- --------------------------------------------------------------
-- Antes da correcao: retorna o hostname antigo (FQDN ou nome longo)
-- Apos a correcao: deve retornar o hostname curto alinhado com o SO

SELECT
    @@SERVERNAME AS [RegisteredServerName]
   ,SERVERPROPERTY('ServerName') AS [ServerPropertyName]

GO

-- --------------------------------------------------------------
-- 1.3. ATUALIZAR METADADOS - REMOVER NOME ANTIGO E ADICIONAR NOVO
-- --------------------------------------------------------------
-- Conectar via sqlcmd: sqlcmd -S localhost -U sa -P '<senha>'

-- Remover o nome antigo do sys.servers
-- Substituir pelo nome antigo real do seu servidor
EXEC sp_dropserver N'prd-yourserver02.dominio.local'
GO

-- Adicionar o novo nome como servidor local
EXEC sp_addserver N'prd-yourserver02', local
GO

-- NOTA: Se sp_dropserver retornar o erro Msg 15190
-- ("There are still remote logins or linked logins for the server"),
-- significa que existem logins remotos ou linked servers associados
-- ao nome antigo. Remove-los primeiro:

-- Verificar logins remotos associados
SELECT
    r.remote_name AS [RemoteName]
   ,s.name AS [ServerName]
FROM sys.remote_logins AS r
    INNER JOIN sys.servers AS s
        ON r.server_id = s.server_id
WHERE s.name = N'prd-yourserver02.dominio.local'
GO

-- Remover logins remotos do servidor antigo
EXEC sp_dropremotelogin N'prd-yourserver02.dominio.local'
GO

-- Tentar sp_dropserver novamente
EXEC sp_dropserver N'prd-yourserver02.dominio.local'
GO

-- Adicionar o novo nome como servidor local
EXEC sp_addserver N'prd-yourserver02', local
GO

-- Apos sp_dropserver/sp_addserver, REINICIAR o SQL Server:
-- Comando Linux:
-- # sudo systemctl restart mssql-server
-- # sleep 10

-- --------------------------------------------------------------
-- 1.4. VERIFICAR SE A CONFIGURACAO DO AGENT ESTA HABILITADA
-- --------------------------------------------------------------
-- Comando Linux equivalente:
-- # sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true
-- # sudo cat /var/opt/mssql/mssql.conf

-- Verificar via T-SQL se as Agent XPs estao habilitadas
EXEC sp_configure 'show advanced options', 1
RECONFIGURE WITH OVERRIDE
GO

EXEC sp_configure 'Agent XPs'
GO

-- Se run_value for 0, habilitar:
EXEC sp_configure 'Agent XPs', 1
RECONFIGURE WITH OVERRIDE
GO

-- --------------------------------------------------------------
-- 1.5. VERIFICAR STATUS DO SQL SERVER AGENT APOS CORRECAO
-- --------------------------------------------------------------
-- No Linux (CU4+), o Agent roda como thread dentro do processo
-- sqlservr, nao como servico systemd separado.
-- A DMV sys.dm_server_services deve listar o Agent com status_desc
-- = 'Running'.

SELECT
    servicename AS [ServiceName]
   ,startup_type_desc AS [StartupType]
   ,status_desc AS [Status]
   ,process_id AS [ProcessID]
FROM sys.dm_server_services
ORDER BY servicename
GO

-- --------------------------------------------------------------
-- 1.6. VERIFICAR TCP LISTENERS DO SQL SERVER
-- --------------------------------------------------------------
-- Util para confirmar em qual IP e porta o SQL Server escuta

SELECT
    listener_id AS [ListenerID]
   ,ip_address AS [IPAddress]
   ,port AS [Port]
   ,type_desc AS [TypeDescription]
   ,state_desc AS [State]
FROM sys.dm_tcp_listener_states
WHERE type = 0
ORDER BY listener_id
GO

-- --------------------------------------------------------------
-- 1.7. VERIFICAR SE O ARQUIVO DE LOG DO AGENT FOI CRIADO
-- --------------------------------------------------------------
-- Comando Linux:
-- # ls -la /var/opt/mssql/log/SQLAgent.out
-- # sudo cat /var/opt/mssql/log/SQLAgent.out
-- Esperado: "SQLServerAgent service started successfully."

-- Se o arquivo ainda nao existir, verificar:
-- Comando Linux:
-- # sudo find /var/opt/mssql/log/ -name "*agent*" -o -name "*sqlagent*"
-- # sudo tail -100 /var/opt/mssql/log/errorlog
-- # sudo journalctl -u mssql-server --no-pager -n 100

-- --------------------------------------------------------------
-- 1.8. LISTAR JOBS EXISTENTES NO msdb
-- --------------------------------------------------------------
-- As Jobs sao armazenadas nas tabelas de sistema do banco msdb.
-- Se o msdb esta intacto, as Jobs ainda estao la apos reabilitar
-- o Agent - nao precisam ser restauradas do backup.

USE [msdb]
GO

SELECT
    j.job_id AS [JobID]
   ,j.name AS [JobName]
   ,j.enabled AS [Enabled]
   ,s.name AS [ScheduleName]
   ,CASE s.freq_type
        WHEN 1 THEN 'Once'
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN 'Weekly'
        WHEN 16 THEN 'Monthly'
        ELSE CAST(s.freq_type AS VARCHAR(20))
    END AS [Frequency]
FROM dbo.sysjobs AS j
    LEFT JOIN dbo.sysjobschedules AS js
        ON j.job_id = js.job_id
    LEFT JOIN dbo.sysschedules AS s
        ON js.schedule_id = s.schedule_id
ORDER BY j.name
GO

/* ============================================================
   2. TESTE DE EXECUCAO DE JOB APOS CORRECAO
   ============================================================

   Cria uma Job de teste, executa imediatamente, verifica o
   resultado e remove a Job. Se run_status = 1 (Succeeded),
   o Agent esta funcionando corretamente.
*/

USE [msdb]
GO

-- --------------------------------------------------------------
-- 2.1. CRIAR JOB DE TESTE
-- --------------------------------------------------------------
BEGIN TRANSACTION

DECLARE @ReturnCode INT = 0
DECLARE @jobId BINARY(16)

EXEC dbo.sp_add_job
    @job_name = N'Test_Agent_PostFix'
   ,@enabled = 1
   ,@description = N'Job de teste para validar Agent apos correcao de hostname/hosts'
   ,@job_id = @jobId OUTPUT

EXEC dbo.sp_add_jobstep
    @job_id = @jobId
   ,@step_name = N'Step 1 - Validation'
   ,@subsystem = N'TSQL'
   ,@command = N'SELECT GETDATE() AS TestTime, @@SERVERNAME AS ServerName;'
   ,@database_name = N'master'

EXEC dbo.sp_add_jobserver
    @job_id = @jobId

COMMIT TRANSACTION
GO

-- --------------------------------------------------------------
-- 2.2. EXECUTAR A JOB IMEDIATAMENTE
-- --------------------------------------------------------------
EXEC dbo.sp_start_job N'Test_Agent_PostFix'
GO

-- --------------------------------------------------------------
-- 2.3. AGUARDAR E VERIFICAR O RESULTADO
-- --------------------------------------------------------------
WAITFOR DELAY '00:00:05'

SELECT
    j.name AS [JobName]
   ,h.run_date AS [RunDate]
   ,h.run_time AS [RunTime]
   ,CASE h.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        WHEN 4 THEN 'In Progress'
    END AS [Result]
FROM dbo.sysjobhistory AS h
    INNER JOIN dbo.sysjobs AS j
        ON h.job_id = j.job_id
WHERE j.name = N'Test_Agent_PostFix'
ORDER BY h.run_date DESC
   ,h.run_time DESC
GO

-- --------------------------------------------------------------
-- 2.4. REMOVER A JOB DE TESTE
-- --------------------------------------------------------------
EXEC dbo.sp_delete_job @job_name = N'Test_Agent_PostFix'
GO

/* ============================================================
   3. COMANDOS LINUX COMPLEMENTARES PARA DIAGNOSTICO
   ============================================================

   --------------------------------------------------------------
   3.1. VERIFICAR SE EXISTE PACOTE LEGADO mssql-server-agent
   --------------------------------------------------------------
   A partir do CU4, o Agent e nativo do mssql-server. Se existir
   um pacote legado mssql-server-agent instalado (de upgrade
   pre-CU4), deve ser removido.

   Comando Linux:
   # rpm -qa | grep mssql-server-agent
   # Se retornar vazio: nao ha pacote legado (esperado para CU31).
   # Se retornar algo: remover com:
   #   sudo yum remove mssql-server-agent -y

   --------------------------------------------------------------
   3.2. VERIFICAR O CONTEUDO DO mssql.conf
   --------------------------------------------------------------
   Comando Linux:
   # sudo cat /var/opt/mssql/mssql.conf
   # Esperado: secao [sqlagent] com enabled = true

   Se nao existir ou estiver false, reaplicar:
   # sudo /opt/mssql/bin/mssql-conf set sqlagent.enabled true

   --------------------------------------------------------------
   3.3. VERIFICAR O TAMANHO DO HOSTNAME
   --------------------------------------------------------------
   Comando Linux:
   # hostname | wc -c
   # Retorna o numero de caracteres + 1 (newline).
   # Resultado deve ser <= 16 (15 caracteres + \n).

   --------------------------------------------------------------
   3.4. VERIFICAR O /etc/hosts
   --------------------------------------------------------------
   Comando Linux:
   # cat /etc/hosts
   # Deve conter: <IP_PRIVADO> <hostname_curto>
   # NUNCA usar IP publico para o hostname do SQL Server.

   --------------------------------------------------------------
   3.5. VERIFICAR PERMISSOES DO DIRETORIO mssql
   --------------------------------------------------------------
   Comando Linux:
   # ls -la /var/opt/mssql/
   # O owner deve ser mssql:mssql em todos os arquivos e diretorios.
   # Se nao for:
   #   sudo chown -R mssql:mssql /var/opt/mssql

   --------------------------------------------------------------
   3.6. VERIFICAR OS LOGS DO SISTEMA
   --------------------------------------------------------------
   Comando Linux:
   # sudo journalctl -u mssql-server --no-pager -n 100
   # Mostra os logs do systemd sobre o servico mssql-server.

   Comando Linux:
   # sudo cat /var/opt/mssql/log/errorlog | grep -iE "agent|sqlagent|startup|error|fail"
   # Filtra o errorlog por termos relevantes.

   Comando Linux:
   # sudo cat /var/opt/mssql/log/SQLAgent.out
   # Log especifico do Agent. Se o arquivo nao existir, o Agent
   # nem chegou a iniciar - provavelmente falha de resolucao de
   # nome (hostname/hosts) ou de permissoes.

   --------------------------------------------------------------
   3.7. VERIFICAR FIREWALL (SE APLICAVEL)
   --------------------------------------------------------------
   Comando Linux:
   # sudo firewall-cmd --list-all
   # A porta 1433/tcp deve estar liberada para conexao local.

   Se necessario:
   # sudo firewall-cmd --permanent --add-port=1433/tcp
   # sudo firewall-cmd --reload

   --------------------------------------------------------------
   3.8. VERIFICAR DBCC CHECKDB NO msdb
   --------------------------------------------------------------
   Se apos todas as correcoes as Jobs ainda nao executarem, pode
   haver corrupcao em tabelas do msdb.
*/

DBCC CHECKDB('msdb') WITH NO_INFOMSGS, ALL_ERRORMSGS
GO

