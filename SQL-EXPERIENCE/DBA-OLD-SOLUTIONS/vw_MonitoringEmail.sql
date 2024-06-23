USE Maintenance
GO

CREATE OR ALTER VIEW Management.[vw_MonitoringEmail] 
WITH ENCRYPTION
AS
SELECT
    a.send_request_date AS DataEnvio,
    a.sent_date AS DataEntrega,
    (CASE    
        WHEN a.sent_status = 0 THEN '0 - Aguardando envio'
        WHEN a.sent_status = 1 THEN '1 - Enviado'
        WHEN a.sent_status = 2 THEN '2 - Falhou'
        WHEN a.sent_status = 3 THEN '3 - Tentando novamente'
    END) AS Situacao,
    isnull(a.from_address, '') AS Remetente,
    isnull(A.recipients,'') AS Destinatario,
    isnull(a.subject,'') AS Assunto,
    isnull(a.reply_to,'') AS ResponderPara,
    isnull(a.body,'') AS Mensagem,
    isnull(a.body_format,'') AS Formato,
    isnull(a.importance,'') AS Importancia,
    isnull(a.file_attachments,'') AS Anexos,
    isnull(a.send_request_user,'') AS Usuario,
    isnull(B.description,'') AS Erro,
    isnull(B.log_date,'') AS DataFalha
FROM 
    msdb.dbo.sysmail_mailitems                  A    WITH(NOLOCK)
    LEFT JOIN msdb.dbo.sysmail_event_log        B    WITH(NOLOCK)    ON A.mailitem_id = B.mailitem_id