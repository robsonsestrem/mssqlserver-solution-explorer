/*
 *
    OBJETIVO: Trigger de logon em nível de servidor para auditoria e controle de acessos,
              permitindo whitelist de contas de serviço e bloqueando logins específicos
              por segurança.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  http://www.forumrm.com.br/topic/5132-trigger-dispara-mensagem-na-tela-resolvido/
 *  https://connect.microsoft.com/SQLServer/feedback/details/237008/logon-trigger-failures-disclose-excess-information
 *  https://www.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server-trigger-logon/
 */
-- ============================================================
-- Contexto geral da solução
-- Triggers de Logon não podem exibir mensagens 
-- na tela por design.
-- Qualquer saída de PRINT ou RAISERROR é registrada 
-- no log do SQL Server.
-- ============================================================
USE [master]
GO

-- ============================================================
-- Trigger tr_BlockedLogin
-- ============================================================
CREATE OR ALTER TRIGGER [tr_BlockedLogin]
ON ALL SERVER
WITH ENCRYPTION
FOR LOGON
AS
BEGIN
    -- ============================================================
    -- Bloco 01: Whitelist de logins de serviço e administrativos
    -- Se o login autenticado estiver nesta lista, 
    -- a trigger encerra sem bloqueio.
    -- ============================================================
    IF
    (
        ORIGINAL_LOGIN() IN
        (
            'DOMAIN\Nfe'
          , 'DOMAIN\Task'
          , 'DOMAIN\administrator'
          , 'DOMAIN\backupexec'
          , 'DOMAIN\sqlserver'
          , 'DOMAIN\vcenter'
          , 'DOMAIN\YOUR_DATABASEERP'
          , 'NT SERVICE\MSSQLSERVER'
          , 'NT SERVICE\SQLSERVERAGENT'
          , 'NT AUTHORITY\SYSTEM'
          , 'NT SERVICE\SQLTELEMETRY'
          , 'NT SERVICE\SQLWriter'
          , 'NT SERVICE\Winmgmt'
          , 'sa'
          , 'admcravil'
          , 'admrobson'
          , 'admadriana'          
          , 'agrosystem'
          , 'consulta'
          , 'guru'
          , 'suptcadm'
          , 'vpxuser'
          , 'sqlmdsmon'
          , 'infogenbi'
        )
    )
    BEGIN
        RETURN
    END

    -- ============================================================
    -- Bloco 02: Captura do evento de logon e contexto da conexão
    -- ============================================================
    DECLARE @Evento XML
          , @Dt_Evento DATETIME
          , @Ds_Usuario VARCHAR(100)
          , @Ds_Hostname VARCHAR(100)
          , @Ds_Software VARCHAR(100)

    SET @Evento = EVENTDATA()
    SET @Ds_Usuario = @Evento.value('(/EVENT_INSTANCE/LoginName/text())[1]', 'varchar(100)')
    SET @Ds_Hostname = HOST_NAME()
    SET @Ds_Software = PROGRAM_NAME()

    -- ============================================================
    -- Bloco 03: Bloqueio de contas específicas 
    -- em servidores específicos
    -- ============================================================
    IF
    (
        @Ds_Usuario IN
        (
            'domain\infogen01'
          , 'domain\infogen02'
          , 'domain\infogen03'
        )
        AND @Ds_Hostname IN
        (
            'SQL01'
          , 'CRVSQL01'
          , 'CRVSQL02'
          , 'IIS01'
          , 'IIS02'
        )
    )
    BEGIN
        RAISERROR('Por segurança este login não é mais permitido, para prosseguir informe o administrador da base de dados', 16, 1);
        ROLLBACK TRANSACTION;
    END

    -- ============================================================
    -- Bloco 04: Bloqueio de acesso direto via SSMS para a conta de aplicação
    -- ============================================================
    IF
    (
        @Ds_Usuario = 'YOUR_DATABASE'
        AND @Ds_Software LIKE '%management Studio%'
    )
    BEGIN
        RAISERROR('Por segurança este login não é mais permitido, para prosseguir informe o administrador da base de dados', 16, 1);
        ROLLBACK TRANSACTION;
    END
END
GO
