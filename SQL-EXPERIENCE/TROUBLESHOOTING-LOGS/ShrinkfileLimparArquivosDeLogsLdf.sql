----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LIMPAR ARQUIVO DE LOGS
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- A única solução oficial no SQL Server 2008 e mais recente é alternar o modelo de recuperação do banco de dados para simples como mostrado no Books Online . 
-- Isso esvazia o log de transações, permitindo que o DBA execute um DBCC SHRINKFILE posteriormente, em seguida, alternar o modelo de recuperação voltar a completo.
-- EXEMPLO DO SHIRINKFILE:
exec sp_helpdb 'guru6'

use Guru6
go
DBCC SHRINKFILE(dbguru_log, 10) -- deve ser nome lógico
GO
