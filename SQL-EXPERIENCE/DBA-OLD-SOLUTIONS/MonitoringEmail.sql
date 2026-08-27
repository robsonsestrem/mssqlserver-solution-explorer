/*
 *
    OBJETIVO: View para monitoramento de e-mails enviados via Database Mail,
              exibindo informações de envio, status, destinatários, assunto,
              erros e demais detalhes dos itens de correio eletrônico.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: sysmail_mailitems, sysmail_event_log
 */
USE YOUR_DATABASE
GO

CREATE OR ALTER VIEW Management.[vw_MonitoringEmail]
WITH ENCRYPTION
AS
SELECT
      a.send_request_date AS DataEnvio
    , a.sent_date AS DataEntrega
    , CASE
          WHEN a.sent_status = 0 THEN '0 - Aguardando envio'
          WHEN a.sent_status = 1 THEN '1 - Enviado'
          WHEN a.sent_status = 2 THEN '2 - Falhou'
          WHEN a.sent_status = 3 THEN '3 - Tentando novamente'
      END AS Situacao
    , ISNULL(a.from_address, '') AS Remetente
    , ISNULL(A.recipients, '') AS Destinatario
    , ISNULL(a.subject, '') AS Assunto
    , ISNULL(a.reply_to, '') AS ResponderPara
    , ISNULL(a.body, '') AS Mensagem
    , ISNULL(a.body_format, '') AS Formato
    , ISNULL(a.importance, '') AS Importancia
    , ISNULL(a.file_attachments, '') AS Anexos
    , ISNULL(a.send_request_user, '') AS Usuario
    , ISNULL(B.description, '') AS Erro
    , ISNULL(B.log_date, '') AS DataFalha
FROM msdb.dbo.sysmail_mailitems A WITH(NOLOCK)
    LEFT JOIN msdb.dbo.sysmail_event_log B WITH(NOLOCK)
        ON A.mailitem_id = B.mailitem_id
GO
