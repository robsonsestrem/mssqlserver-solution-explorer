/*
    OBJETIVO: Monitorar eventos de autogrowth de arquivos de dados e logs
              através de Event Notification e Service Broker, armazenando
              os eventos na tabela HistoryDBFileGrowth e enviando alertas
              por e-mail para a equipe de suporte.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
    http://www.dbinternals.com.br/?p=1089
*/
USE DBA_PerformanceHub;
GO

-- ============================================================
-- Tabela para armazenar histórico de autogrowth
-- ============================================================

CREATE TABLE Management.HistoryDBFileGrowth
(
    IdDBFileGrowth      INT             IDENTITY(1, 1) NOT NULL
  , DateInsert          DATETIME        NULL
  , EventType           NVARCHAR(MAX)   NULL
  , PostTime            NVARCHAR(MAX)   NULL
  , SPID                NVARCHAR(MAX)   NULL
  , DatabaseID          NVARCHAR(MAX)   NULL
  , NTDomainName        NVARCHAR(MAX)   NULL
  , HostName            NVARCHAR(MAX)   NULL
  , ClientProcessID     NVARCHAR(MAX)   NULL
  , ApplicationName     NVARCHAR(MAX)   NULL
  , LoginName           NVARCHAR(MAX)   NULL
  , Duration            NVARCHAR(MAX)   NULL
  , StartTime           NVARCHAR(MAX)   NULL
  , EndTime             NVARCHAR(MAX)   NULL
  , IntegerData         NVARCHAR(MAX)   NULL
  , ServerName          NVARCHAR(MAX)   NULL
  , DatabaseName        NVARCHAR(MAX)   NULL
  , FileName            NVARCHAR(MAX)   NULL
  , LoginSid            NVARCHAR(MAX)   NULL
  , EventSequence       NVARCHAR(MAX)   NULL
  , IsSystem            NVARCHAR(MAX)   NULL
  , SessionLoginName    NVARCHAR(MAX)   NULL
  , CONSTRAINT PK_tb_DBFileGrowth PRIMARY KEY (IdDBFileGrowth)
);


-- ============================================================
-- Service Broker: Queue e Service para Event Notification
-- ============================================================
CREATE QUEUE [Audit_DBFileGrowth_Queue];
GO

CREATE SERVICE Audit_DBFileGrowth_Service
    ON QUEUE [Audit_DBFileGrowth_Queue]
    ([http://schemas.microsoft.com/SQL/Notifications/PostEventNotification]);
GO

CREATE EVENT NOTIFICATION [Audit_DBFileGrowth_Event]
    ON SERVER WITH FAN_IN
    FOR DATA_FILE_AUTO_GROW
      , LOG_FILE_AUTO_GROW
    TO SERVICE 'Audit_DBFileGrowth_Service'
      , 'current database';
GO

-- DROP EVENT NOTIFICATION [Audit_DBFileGrowth_Event] ON SERVER;


-- ============================================================
-- Procedure de ativação da queue (processa eventos e envia e-mail)
-- ============================================================
CREATE OR ALTER PROCEDURE Management.sp_DBFileGrowth
    WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @message_body XML;

    WHILE (1 = 1)
    BEGIN
        WAITFOR
        (
            RECEIVE TOP (1)
                @message_body = CAST(message_body AS XML)
            FROM
                dbo.Audit_DBFileGrowth_Queue
        ), TIMEOUT 1000;

        IF (@@ROWCOUNT = 1)
        BEGIN
            INSERT INTO DBA_PerformanceHub.Management.HistoryDBFileGrowth
            (
                DateInsert
              , EventType
              , PostTime
              , SPID
              , DatabaseID
              , NTDomainName
              , HostName
              , ClientProcessID
              , ApplicationName
              , LoginName
              , Duration
              , StartTime
              , EndTime
              , IntegerData
              , ServerName
              , DatabaseName
              , FileName
              , LoginSid
              , EventSequence
              , IsSystem
              , SessionLoginName
            )
            SELECT
                GETDATE()
              , @message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/SPID)[1]', 'NVARCHAR(MAX)')
              , DB_NAME(@message_body.value('(/EVENT_INSTANCE/DatabaseID)[1]', 'NVARCHAR(MAX)'))
              , @message_body.value('(/EVENT_INSTANCE/NTDomainName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ClientProcessID)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ApplicationName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/Duration)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/StartTime)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/EndTime)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/IntegerData)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/ServerName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/FileName)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/LoginSid)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/EventSequence)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/IsSystem)[1]', 'NVARCHAR(MAX)')
              , @message_body.value('(/EVENT_INSTANCE/SessionLoginName)[1]', 'NVARCHAR(MAX)');

            -- ============================================================
            -- Envio de e-mail de alerta
            -- ============================================================
            DECLARE @Assunto VARCHAR(200) =
                @@SERVERNAME + ' - Atenção Foi Acionado Autogrowth em Datafile(s)';

            DECLARE @Destinatario VARCHAR(50) = 'suporte@cravil.com.br';

            DECLARE @Mensagem VARCHAR(MAX);

            SET @Mensagem =
                'Prezado DBA,<br>'
                + 'Verifique os logs, ocorreu autocrescimento em algum(s) datafiles, detalhes abaixo:'
                + '<br>Instância: ' + @@SERVICENAME
                + '<br>Servidor: ' + @@SERVERNAME
                + '<br><br>'
                + '<TABLE border=1 cellpadding=2 cellspacing=0 font-family:Arial;font-size:14px">'
                + '<tr align="left">'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>EventType</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>PostTime</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>HostName</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>ApplicationName</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>LoginName</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>Duration</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>StartTime</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>EndTime</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>Database</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>FileName</td>'
                + '<td bgcolor=#0B0B61 width="200"><font color=white>SessionLogin</td>'
                + '</tr>';

            SELECT @Mensagem = @Mensagem +
                '<tr align="left">'
                + '<td>' + LOWER(@message_body.value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(MAX)')) + '</td>'
                + '<td>' + REPLACE(REPLACE(@message_body.value('(/EVENT_INSTANCE/PostTime)[1]', 'NVARCHAR(MAX)'), 'T', ' '), '-', '/') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/HostName)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/ApplicationName)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/Duration)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '<td>' + REPLACE(REPLACE(@message_body.value('(/EVENT_INSTANCE/StartTime)[1]', 'NVARCHAR(MAX)'), 'T', ' '), '-', '/') + '</td>'
                + '<td>' + REPLACE(REPLACE(@message_body.value('(/EVENT_INSTANCE/EndTime)[1]', 'NVARCHAR(MAX)'), 'T', ' '), '-', '/') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/FileName)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '<td>' + @message_body.value('(/EVENT_INSTANCE/SessionLoginName)[1]', 'NVARCHAR(MAX)') + '</td>'
                + '</tr></table><br>';

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'CRAVIL'
              , @recipients = @Destinatario
              , @subject = @Assunto
              , @body = @Mensagem
              , @body_format = 'HTML';
        END;  -- fim do IF
    END;      -- fim do WHILE

    SET NOCOUNT OFF;
END;
GO


-- ============================================================
-- Ativação da queue
-- ============================================================
ALTER QUEUE [Audit_DBFileGrowth_Queue]
WITH ACTIVATION
(
    STATUS = ON
  , PROCEDURE_NAME = Management.sp_DBFileGrowth
  , MAX_QUEUE_READERS = 1
  , EXECUTE AS OWNER
);
GO
