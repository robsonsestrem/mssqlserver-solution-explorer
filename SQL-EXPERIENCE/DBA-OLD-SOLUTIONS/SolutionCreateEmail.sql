/*
    OBJETIVO: Demonstrar exemplos de envio de e-mails via SQL Server,
              incluindo Database Mail (sp_send_dbmail) e métodos alternativos
              via OLE Automation (sp_OACreate), além de consultas para
              monitoramento e limpeza da fila de e-mails.
    PROJETO: mssqlserver-solution-explorer
*/
-- ============================================================
-- Exemplo prático de envio de e-mail via Database Mail
-- ============================================================
USE msdb;
GO

EXEC sp_send_dbmail
    @profile_name = 'Cravil_ERP'            -- Nome do profile configurado
  , @recipients = 'sestrem2@hotmail.com'     -- Destinatários
  , @subject = 'Relatório Diário SGBD - SQL Server'
  , @body =
    'Corpo da mensagem.
    E-mail recebido através do database mail do SQL Server!!!!';


-- ============================================================
-- Consulta para monitorar mensagens enviadas
-- ============================================================
USE msdb;
GO

SELECT
    *
FROM
    sysmail_mailitems;

SELECT
    *
FROM
    sysmail_log;
GO


-- ============================================================
-- Limpeza da fila de e-mails
-- ============================================================
-- Excluindo todos os e-mails enviados até a data atual
DECLARE @GETDATE DATETIME;
SET @GETDATE = GETDATE();

EXECUTE msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @GETDATE;
GO

-- Excluindo e-mails anteriores a uma data específica
EXECUTE msdb.dbo.sysmail_delete_mailitems_sp @sent_before = 'November 1, 2017';
GO

-- Excluindo apenas e-mails que falharam
EXECUTE msdb.dbo.sysmail_delete_mailitems_sp @sent_status = 'failed';
GO


-- ============================================================
-- Envio via OLE Automation (SMTP) - SQL Server 2000+ (alternativa)
-- ============================================================
CREATE PROCEDURE sp_SMTPMail
    @SenderName         VARCHAR(100)
  , @SenderAddress      VARCHAR(100)
  , @RecipientName      VARCHAR(100)
  , @RecipientAddress   VARCHAR(100)
  , @Subject            VARCHAR(200)
  , @Body               VARCHAR(8000)
  , @MailServer         VARCHAR(100) = 'theserver.com'
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @oMail INT;              -- Object reference
    DECLARE @resultcode INT;

    EXEC @resultcode = sp_OACreate 'SMTPsvg.Mailer', @oMail OUTPUT;

    IF @resultcode = 0
    BEGIN
        EXEC @resultcode = sp_OASetProperty @oMail, 'RemoteHost',       @MailServer;
        EXEC @resultcode = sp_OASetProperty @oMail, 'Melody',            @SenderName;
        EXEC @resultcode = sp_OASetProperty @oMail, 'elody@hotmail.com', @SenderAddress;
        EXEC @resultcode = sp_OAMethod       @oMail, 'AddRecipient', NULL, @RecipientName, @RecipientAddress;
        EXEC @resultcode = sp_OASetProperty @oMail, 'Subject',           @Subject;
        EXEC @resultcode = sp_OASetProperty @oMail, 'BodyText',          @Body;
        EXEC @resultcode = sp_OAMethod       @oMail, 'SendMail', NULL;

        EXEC sp_OADestroy @oMail;
    END;

    SET NOCOUNT OFF;
END;
GO

-- Exemplo de execução
EXEC sp_SMTPMail
    @SenderName        = 'Servidor'
  , @SenderAddress     = 'seu_email@dominio.com.br'
  , @RecipientName     = 'Melody'
  , @RecipientAddress  = 'melody@aol.com'
  , @Subject           = 'SQL Test'
  , @Body              = 'Hello, this is a test email from SQL Server';
GO

-- ============================================================
-- Envio via CDONTS (Outra alternativa)
-- ============================================================
CREATE PROCEDURE dbo.sp_EnviaEmail
    @From    VARCHAR(100)
  , @To      VARCHAR(100)
  , @Subject VARCHAR(100)
  , @Body    VARCHAR(4000)
  , @CC      VARCHAR(100) = NULL
  , @BCC     VARCHAR(100) = NULL
AS
BEGIN
    DECLARE @MailID INT;
    DECLARE @hr INT;

    EXEC @hr = sp_OACreate     'CDONTS.NewMail', @MailID OUTPUT;
    EXEC @hr = sp_OASetProperty @MailID, 'From',    @From;
    EXEC @hr = sp_OASetProperty @MailID, 'Body',    @Body;
    EXEC @hr = sp_OASetProperty @MailID, 'BCC',     @BCC;
    EXEC @hr = sp_OASetProperty @MailID, 'CC',      @CC;
    EXEC @hr = sp_OASetProperty @MailID, 'Subject', @Subject;
    EXEC @hr = sp_OASetProperty @MailID, 'To',      @To;
    EXEC @hr = sp_OAMethod       @MailID, 'Send', NULL;
    EXEC @hr = sp_OADestroy      @MailID;
END;
GO


-- ============================================================
-- Configuração necessária para Database Mail
-- ============================================================
sp_configure 'show advanced', 1;
GO
RECONFIGURE;
GO

sp_configure 'Database Mail XPs', 1;
GO
RECONFIGURE;
GO


-- ============================================================
-- Sintaxe completa do sp_send_dbmail (referência)
-- ============================================================
/*
USE msdb;
GO

sp_send_dbmail
    @profile_name = 'profile_name'
  , @recipients = 'recipients [ ; ...n ]'
  , @copy_recipients = 'copy_recipient [ ; ...n ]'
  , @blind_copy_recipients = 'blind_copy_recipient [ ; ...n ]'
  , @subject = 'subject'
  , @body = 'body'
  , @body_format = 'body_format'
  , @importance = 'importance'
  , @sensitivity = 'sensitivity'
  , @file_attachments = 'attachment [ ; ...n ]'
  , @query = 'query'
  , @execute_query_database = 'execute_query_database'
  , @attach_query_result_as_file = attach_query_result_as_file
  , @query_attachment_filename = query_attachment_filename
  , @query_result_header = query_result_header
  , @query_result_width = query_result_width
  , @query_result_separator = 'query_result_separator'
  , @exclude_query_output = exclude_query_output
  , @append_query_error = append_query_error
  , @query_no_truncate = query_no_truncate
  , @mailitem_id = mailitem_id OUTPUT;
*/
