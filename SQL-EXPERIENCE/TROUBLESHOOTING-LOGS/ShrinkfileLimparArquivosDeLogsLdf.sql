/*
    OBJETIVO: Demonstrar o procedimento oficial para limpeza de arquivo de log (LDF) no SQL Server 2008+,
              alternando o modelo de recuperação para SIMPLES, executando DBCC SHRINKFILE e retornando
              ao modelo de recuperação COMPLETO.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- SEÇÃO 1: Identificação do banco de dados e arquivos
-- ============================================================

-- Consulta informações do banco de dados para identificar o nome lógico do arquivo de log
EXECUTE sp_helpdb @dbname = 'guru6';
GO

-- ============================================================
-- SEÇÃO 2: Limpeza do arquivo de log via SHRINKFILE
-- ============================================================

-- Altera o contexto para o banco de dados alvo
USE Guru6;
GO

-- Executa o encolhimento do arquivo de log para o tamanho especificado em MB
-- IMPORTANTE: O primeiro parâmetro deve ser o nome lógico do arquivo de log
DBCC SHRINKFILE(dbguru_log, 10);
GO
