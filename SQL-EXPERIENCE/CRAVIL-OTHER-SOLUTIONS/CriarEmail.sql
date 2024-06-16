-------------------------------------------------------------------------------------------------------------------------
-- Segue um exemplo prático de envio de email (esta forma coloquei em uso aqui na cravil)
-------------------------------------------------------------------------------------------------------------------------
USE msdb
GO

EXEC sp_send_dbmail @profile_name ='Cravil_ERP', -- Coloque o profile desejado.

@recipients ='sestrem2@hotmail.com', -- Coloque os receptores da mensagem.

@subject ='Relatório Diário SGBD - SQL Server',

@body =
'Corpo da mensagem.
E-mail recebido através do database mail do SQL Server!!!!'


-------------------------------------------------------------------------------------------------------------------------
--Note que o envio não é disparado necessariamente na hora, 
--ele é posto numa fila e o envio dependerá das condições da rede e de conectividade.
--Podemos analisar as mensagens e o status do envio das mesmas, através dos seguintes comandos de seleção:
-------------------------------------------------------------------------------------------------------------------------
use msdb
go
SELECT * FROM sysmail_mailitems

use msdb
go
SELECT * FROM sysmail_log
GO


-------------------------------------------------------------------------------------------------------------------------
--Excluindo tudo
-------------------------------------------------------------------------------------------------------------------------
DECLARE @GETDATE datetime
SET @GETDATE = GETDATE();
EXECUTE msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @GETDATE;
GO


-------------------------------------------------------------------------------------------------------------------------
--Excluindo os emails mais antigos
--O exemplo a seguir exclui os emails do Database Mail anteriores a October 9, 2005.
-------------------------------------------------------------------------------------------------------------------------
EXECUTE msdb.dbo.sysmail_delete_mailitems_sp 
    @sent_before = 'November 1, 2017' ;
GO


-------------------------------------------------------------------------------------------------------------------------
--Excluindo todos os emails de um determinado tipo
--O exemplo a seguir exclui todos os emails que falharam do log do Database Mail.
-------------------------------------------------------------------------------------------------------------------------
EXECUTE msdb.dbo.sysmail_delete_mailitems_sp 
    @sent_status = 'failed' ;
GO


-------------------------------------------------------------------------------------------------------------------------------------
--Outra opção e mais fácil e flexível, pois, vc pode utilizá-la até no sql 2000 para envio via SMTP é vc usar o OAMethod. 
--Para isso vc terá que informar somente as informações de conexão com o servidor de email smtp.
--Segue procedure.
-------------------------------------------------------------------------------------------------------------------------------------
--Create Procedure sp_SMTPMail

--@SenderName varchar(100),
--@SenderAddress varchar(100),
--@RecipientName varchar(100),
--@RecipientAddress varchar(100),
--@Subject varchar(200),
--@Body varchar(8000),
--@MailServer varchar(100) = 'theserver.com'

--AS 

--SET nocount on

--declare @oMail int		--Object reference
--declare @resultcode int

--EXEC @resultcode = sp_OACreate 'SMTPsvg.Mailer', @oMail OUT

--if @resultcode = 0
--	BEGIN
--	EXEC @resultcode = sp_OASetProperty @oMail, 'RemoteHost',			@mailserver
--	EXEC @resultcode = sp_OASetProperty @oMail, 'Melody',				@SenderName
--	EXEC @resultcode = sp_OASetProperty @oMail, 'elody@hotmail.com',	@SenderAddress
--	EXEC @resultcode = sp_OAMethod		@oMail, 'AddRecipient', NULL,	@RecipientName, @RecipientAddress
--	EXEC @resultcode = sp_OASetProperty @oMail, 'Subject',				@Subject
--	EXEC @resultcode = sp_OASetProperty @oMail, 'BodyText',				@Body
--	EXEC @resultcode = sp_OAMethod		@oMail, 'SendMail', NULL

--	EXEC sp_OADestroy @oMail
--END 


--SET nocount off
--GO
--exec sp_SMTPMail @SenderName =			'Servidor', 
--				 @SenderAddress =		'seu_email@domonio.com.br',
--				 @RecipientName =		'Melody', 
--				 @RecipientAddress =	'melody@aol.com', 
--				 @Subject=				'SQL Test', 
--				 @body =				'Hello, this is a test email from SQL Server'


-------------------------------------------------------------------------------------------------------------------------------------
-- Outro exemplo da configuração citada acima
-------------------------------------------------------------------------------------------------------------------------------------
--CREATE PROCEDURE [dbo].[sp_EnviaEmail] 

--@From varchar(100),
--@To varchar(100),
--@Subject varchar(100),
--@Body varchar(4000),
--@CC varchar(100) = null,
--@BCC varchar(100) = null

--AS

--	Declare @MailID int
--	Declare @hr int

--	EXEC @hr = sp_OACreate		'CDONTS.NewMail',	@MailID OUT
--	EXEC @hr = sp_OASetProperty @MailID, 'From',	@From
--	EXEC @hr = sp_OASetProperty @MailID, 'Body',	@Body
--	EXEC @hr = sp_OASetProperty @MailID, 'BCC',		@BCC
--	EXEC @hr = sp_OASetProperty @MailID, 'CC',		@CC
--	EXEC @hr = sp_OASetProperty @MailID, 'Subject', @Subject
--	EXEC @hr = sp_OASetProperty @MailID, 'To',		@To
--	EXEC @hr = sp_OAMethod		@MailID, 'Send', NULL
--	EXEC @hr = sp_OADestroy		@MailID

--GO


				-- OUTRAS ORIENTAÇÕES PARA FUNCIONAMENTO DO E-MAIL
-------------------------------------------------------------------------------------------------------------------------
-- É necessário primeiramente executar a seguinte configuração para garantir que não haverá problemas:
-------------------------------------------------------------------------------------------------------------------------
--sp_configure 'show advanced', 1 
--GO 
--RECONFIGURE 
--GO 
--sp_configure 'Database Mail XPs', 1 
--GO 
--RECONFIGURE 
--GO


-------------------------------------------------------------------------------------------------------------------------
-- Na sequência podemos utilizar a stored procedure de sistema denominada: 
-- sp_send_dbmail, cuja sintaxe é mostrada a seguir (para mais detalhes consulte o books online):
-------------------------------------------------------------------------------------------------------------------------
--USE msdb
--GO
--sp_send_dbmail  @profile_name =  'profile_name'
--    ,  @recipients =  'recipients [ ; ...n ]' 
--    ,  @copy_recipients = 'copy_recipient [ ; ...n ]' 
--    ,  @blind_copy_recipients = 'blind_copy_recipient [ ; ...n ]' 
--    ,  @subject = 'subject'
--    ,  @body = 'body'  
--    ,  @body_format = 'body_format' 
--    ,  @importance = 'importance' 
--    ,  @sensitivity = 'sensitivity' 
--    ,  @file_attachments = 'attachment [ ; ...n ]' 
--    ,  @query = 'query' 
--    ,  @execute_query_database = 'execute_query_database' 
--    ,  @attach_query_result_as_file = attach_query_result_as_file 
--    ,  @query_attachment_filename = query_attachment_filename 
--    ,  @query_result_header = query_result_header 
--    ,  @query_result_width = query_result_width 
--    ,  @query_result_separator = 'query_result_separator' 
--    ,  @exclude_query_output = exclude_query_output 
--    ,  @append_query_error = append_query_error 
--    ,  @query_no_truncate = query_no_truncate 
--    ,  @mailitem_id = mailitem_id -- OUTPUT