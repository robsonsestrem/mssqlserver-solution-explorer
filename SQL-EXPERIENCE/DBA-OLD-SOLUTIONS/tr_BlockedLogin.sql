-----------------------------------------------------------------------------------------------------------------------------------------------
-- http://www.forumrm.com.br/topic/5132-trigger-dispara-mensagem-na-tela-resolvido/
-- https://connect.microsoft.com/SQLServer/feedback/details/237008/logon-trigger-failures-disclose-excess-information
-- https://www.dirceuresende.com/blog/como-implementar-auditoria-e-controle-de-logins-no-sql-server-trigger-logon/
-----------------------------------------------------------------------------------------------------------------------------------------------
-- Os Triggers de Logon n�o podem exibir mensagens por design. Qualquer sa�da de PRINT ou RAISERROR vai ao log do SQL Server.
-- RAISERROR('Por seguran�a este login n�o � mais permitido, para prosseguir informe o administrador da base de dados', 16, 1);
USE [master]
GO

ALTER TRIGGER [tr_BlockedLogin] ON ALL SERVER
WITH ENCRYPTION
FOR LOGON 
AS
BEGIN  
	 -- N�o elimina login de usu�rios espec�ficos
	 IF(ORIGINAL_LOGIN() in ('CRAVIL\Nfe', 'CRAVIL\Task', 'CRAVIL\administrator', 'CRAVIL\backupexec', 'CRAVIL\sqlserver', 'CRAVIL\vcenter', 'CRAVIL\YOUR_DATABASEERP'
							   , 'NT SERVICE\MSSQLSERVER','NT SERVICE\SQLSERVERAGENT', 'NT AUTHORITY\SYSTEM', 'NT SERVICE\SQLTELEMETRY', 'NT SERVICE\SQLWriter', 'NT SERVICE\Winmgmt'
							   , 'sa', 'admcravil', 'admrobson', 'admadriana', 'YOUR_DATABASE', 'agrosystem', 'consulta', 'guru', 'suptcadm', 'vpxuser', 'sqlmdsmon', 'CRAVIL\rdornel', 'CRAVIL\domo'
							   , 'infadriano', 'infedivaldo', 'infedivan','infeliezer', 'infivan', 'infjehan', 'infmarcelo', 'inftiago', 'infogenbi', 'infernando')		
		)
	  BEGIN
		RETURN
	  END	
	 	       
		DECLARE 
			@Evento XML, 
			@Dt_Evento DATETIME,
			@Ds_Usuario VARCHAR(100),
			@Ds_Hostname VARCHAR(100),
			@Ds_Software VARCHAR(100)    

		SET @Evento = EVENTDATA()
                 
		SET @Ds_Usuario = @Evento.value('(/EVENT_INSTANCE/LoginName/text())[1]','varchar(100)')   
		SET @Ds_Hostname = HOST_NAME()            
		SET @Ds_Software = PROGRAM_NAME()	 	   
		IF ( (@Ds_Usuario IN ('cravil\infogen01', 'cravil\infogen02', 'cravil\infogen03')) AND (@Ds_Hostname in ('SQL01', 'CRVSQL01', 'CRVSQL02', 'IIS01', 'IIS02')) )
		BEGIN     
			RAISERROR('Por seguran�a este login n�o � mais permitido, para prosseguir informe o administrador da base de dados', 16, 1);
			ROLLBACK TRANSACTION;  			
		END 
		IF(@Ds_Usuario = 'YOUR_DATABASE' and @Ds_Software LIKE '%management Studio%')     
		BEGIN
			RAISERROR('Por seguran�a este login n�o � mais permitido, para prosseguir informe o administrador da base de dados', 16, 1);
			ROLLBACK TRANSACTION;
		END                    
END

GO



