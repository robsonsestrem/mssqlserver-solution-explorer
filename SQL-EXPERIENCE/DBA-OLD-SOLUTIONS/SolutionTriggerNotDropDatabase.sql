/*
 *
    OBJETIVO: Trigger DDL a nível de servidor para bloquear a exclusão
              (DROP) de qualquer banco de dados, prevenindo remoções
              acidentais e garantindo segurança operacional.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  http://www.dbinternals.com.br/?p=1113
 */
-- ============================================================
-- Trigger para bloquear exclusão de bancos de dados
-- ============================================================
USE master
GO

CREATE TRIGGER [tr_NotDropDatabase] ON ALL SERVER
WITH ENCRYPTION
FOR DROP_DATABASE
AS
BEGIN
    SET NOCOUNT ON

    RAISERROR('Por segurança a exclusão de banco de dados está bloqueada, para prosseguir informe o administrador da base de dados', 16, 1)
    ROLLBACK
END
GO
