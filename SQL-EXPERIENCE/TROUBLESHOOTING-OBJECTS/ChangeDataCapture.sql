/*
 *
  OBJETIVO: Scripts de configuração e demonstração do Change Data Capture (CDC)
            no SQL Server, incluindo habilitação/desabilitação de tabelas para
            rastreamento de alterações e consultas de dados capturados usando
            funções do CDC (fn_cdc_get_all_changes, fn_cdc_map_time_to_lsn).
 
  PROJETO: mssqlserver-solution-explorer

 * NOTA IMPORTANTE:
 *   Change Data Capture está disponível apenas nas edições Enterprise, Developer
 *   e Enterprise Evaluation do SQL Server. Standard Edition NÃO suporta CDC.
 */
-- ============================================================
-- Configuração do Change Data Capture
-- ============================================================
-- Habilitando CDC para a tabela PRODUTOSLEVEL4

-- A system stored procedure sp_cdc_enable_table habilita a tabela para rastreamento
-- e cria jobs do SQL Server Agent responsáveis pela captura de alterações
USE GesCooper90_homolog
GO

EXECUTE sys.sp_cdc_enable_table
    @source_schema = N'dbo'
    , @source_name = N'PRODUTOSLEVEL4'
    , @role_name = N'NULL'
GO

-- Após a execução, o SQL Server cria:
--   1. Jobs do SQL Server Agent para captura e limpeza
--   2. System tables para armazenamento de metadados do CDC
--   3. System stored procedures específicas da instância de captura
--   4. Database triggers para controle das operações de captura

-- 
-- Desabilitando CDC para a tabela PRODUTOSLEVEL4
-- 

USE GesCooper90_homolog
GO

EXECUTE sys.sp_cdc_disable_table
    @source_schema = N'dbo'
    , @source_name = N'PRODUTOSLEVEL4'
    , @capture_instance = N'dbo_PRODUTOSLEVEL4'
GO

-- ============================================================
-- Consultas de Dados Capturados pelo CDC
-- ============================================================
-- Retornando todas as alterações capturadas

-- Consulta básica usando fn_cdc_get_all_changes para obter todas as modificações
-- registradas entre o LSN mínimo e máximo disponíveis
USE GesCooper90_homolog
GO

DECLARE
    @from_lsn AS BINARY(10)
    , @to_lsn AS BINARY(10)

SET @from_lsn = sys.fn_cdc_get_min_lsn('dbo_Produtos')
SET @to_lsn = sys.fn_cdc_get_max_lsn()

SELECT
    *
FROM cdc.fn_cdc_get_all_changes_dbo_Produtos(@from_lsn, @to_lsn, N'all')
GO

-- 
-- Obtendo informações sobre colunas capturadas
-- 

-- sys.sp_cdc_get_captured_columns retorna metadados sobre quais colunas da tabela
-- de origem estão sendo rastreadas pela instância de captura
USE GesCooper90_homolog
GO

EXECUTE sys.sp_cdc_get_captured_columns
    @capture_instance = N'dbo_Produtos'
GO

-- 
-- Obtendo ajuda sobre configuração do CDC
-- 

-- sys.sp_cdc_help_change_data_capture retorna informações sobre as tabelas
-- habilitadas para CDC no schema especificado
USE GesCooper90_homolog
GO

EXECUTE sys.sp_cdc_help_change_data_capture
    @source_schema = N'dbo'
    , @source_name = N'Produtos'
GO

-- ============================================================
-- Consultas com Mapeamento de Tempo para LSN
-- ============================================================
-- Consultando alterações das últimas 24 horas

-- Converte intervalos de tempo em LSNs usando fn_cdc_map_time_to_lsn,
-- permitindo consultas baseadas em tempo em vez de LSNs manuais
DECLARE
    @begin_time AS DATETIME
    , @end_time AS DATETIME
    , @begin_lsn AS BINARY(10)
    , @end_lsn AS BINARY(10)

SELECT
    @begin_time = DATEADD(DAY, -1, GETDATE())
    , @end_time = GETDATE()

SELECT
    @begin_lsn = sys.fn_cdc_map_time_to_lsn('smallest greater than', @begin_time)

SELECT
    @end_lsn = sys.fn_cdc_map_time_to_lsn('largest less than or equal', @end_time)

SELECT
    *
FROM cdc.fn_cdc_get_all_changes_dbo_Empregados(@begin_lsn, @end_lsn, N'all')
GO

-- Parâmetros aceitos por fn_cdc_map_time_to_lsn:
--   - 'largest less than'
--   - 'largest less than or equal'
--   - 'smallest greater than'
--   - 'smallest greater than or equal'

-- ============================================================
-- Estrutura das Tabelas de Sistema do CDC
-- ============================================================

-- Tabelas criadas automaticamente pelo CDC durante a configuração:
--
-- cdc.<capture_instance>_CT
--   Contém uma linha para cada alteração em coluna capturada na tabela de origem
--
-- cdc.captured_columns
--   Contém uma linha para cada coluna rastreada na instância de captura
--
-- cdc.change_tables
--   Contém uma linha para cada tabela de alteração do banco de dados
--
-- cdc.ddl_history
--   Contém uma linha para cada alteração DDL em tabelas habilitadas para CDC
--
-- cdc.lsn_time_mapping
--   Mapeia LSNs confirmados para o horário de confirmação da transação
--
-- cdc.index_columns
--   Contém uma linha para cada coluna de índice associada a uma tabela de alteração
--
-- dbo.cdc_jobs
--   Armazena parâmetros de configuração dos jobs do agente CDC
