/*
	OBJETIVO: Executar o desligamento imediato da instância do SQL Server,
			  com a opção WITH NOWAIT para pular a execução de checkpoints
			  em todos os bancos de dados.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- CUIDADO!!!
-- Este comando interrompe imediatamente o SQL Server.
-- ============================================================

SHUTDOWN WITH NOWAIT;

-- ============================================================
-- Comportamento e observações:
--   - WITH NOWAIT (opcional): desliga o SQL Server sem executar
--     checkpoints em todos os bancos de dados.
--   - O SQL Server sai após tentar finalizar todos os processos
--     de usuário.
--   - Quando o servidor é reiniciado, ocorre uma operação de
--     reversão para transações incompletas.
--   - Permissões: SHUTDOWN é atribuída a membros das funções
--     de servidor fixas sysadmin e serveradmin, e não podem
--     ser transferidas.
-- ============================================================
