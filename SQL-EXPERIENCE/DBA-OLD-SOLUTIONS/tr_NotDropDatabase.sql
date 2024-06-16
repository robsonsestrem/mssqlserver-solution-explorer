-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Referência
-- http://www.dbinternals.com.br/?p=1113
-----------------------------------------------------------------------------------------------------------------------------------------------------
USE master
GO

CREATE TRIGGER [tr_NotDropDatabase] ON ALL SERVER
WITH ENCRYPTION
FOR DROP_DATABASE
AS
 SET NOCOUNT ON;

 RAISERROR('Por segurança a exclusão de banco de dados está bloqueada, para prosseguir informe o administrador da base de dados', 16, 1);
 ROLLBACK;
GO