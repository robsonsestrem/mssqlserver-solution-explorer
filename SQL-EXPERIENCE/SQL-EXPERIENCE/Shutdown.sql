---------------------------------------------------------------------------------------------------------------
-- CUIDADO!!!
---------------------------------------------------------------------------------------------------------------
SHUTDOWN WITH NOWAIT

--Interrompe imediatamente o SQL Server.
--WITH NOWAIT
--Opcional. Desliga o SQL Server sem executar pontos de verificação em todo o banco de dados. 
--O SQL Server sai depois de tentar finalizar todos os processos de usuário. 
--Quando o servidor é reiniciado, ocorre uma operação de reversão para transações incompletas.

--As permissões SHUTDOWN são atribuídas a membros das funções de servidor fixas sysadmin e serveradmin,
--e elas não podem ser transferidas.