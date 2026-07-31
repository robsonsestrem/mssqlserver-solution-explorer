/*
 *
    OBJETIVO: Alterar o usuário proprietário do banco de dados atual
              para 'sa' utilizando a system stored procedure sp_changedbowner.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-changedbowner-transact-sql?view=sql-server-ver17
 */
-- ============================================================
-- Alteração do proprietário do banco de dados
-- ============================================================

-- OBS: sp_changedbowner está deprecated desde o SQL Server 2012.
--      A Microsoft recomenda utilizar ALTER AUTHORIZATION ON DATABASE::[nome] TO [sa]
--      em scripts novos. O comando abaixo é mantido por compatibilidade
--      com scripts legados existentes neste projeto.
--
-- Define 'sa' como proprietário do banco de dados atual
EXEC sp_changedbowner 'sa';
