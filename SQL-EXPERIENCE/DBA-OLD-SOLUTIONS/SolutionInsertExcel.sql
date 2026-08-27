/*
 *
    OBJETIVO: Procedure para exportação de dados de uma tabela SQL Server
              para um arquivo Excel (.xlsx) utilizando OPENROWSET com
              o provedor Microsoft.ACE.OLEDB.12.0.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/pt-br/sql/relational-databases/import-export/import-data-from-excel-to-sql
 *  https://learn.microsoft.com/en-us/sql/relational-databases/import-export/overview-import-export
 */
-- ==============================================================================================
-- Para que esta procedure funcione corretamente, 
-- é necessário atentar-se a alguns pré-requisitos:

-- 1. Provedor ACE OLEDB: O driver Microsoft.ACE.OLEDB.12.0 
-- deve estar instalado no servidor SQL Server. 
-- Ele pode ser baixado como parte do Microsoft Access Database Engine.

-- 2. Configuração do SQL Server: 
-- A opção de configuração Ad Hoc Distributed Queries deve estar habilitada. 
-- Do contrário, um erro como 
-- "SQL Server blocked access to STATEMENT 
-- 'OpenRowset/OpenDatasource' of component 'Ad Hoc Distributed Queries'" 
-- será gerado. 
-- Para habilitar:
-- ==============================================================================================
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.[sp_InsertExcel](
    @Caminho VARCHAR(MAX)
  , @Aba VARCHAR(200)
  , @Tabela VARCHAR(200)
  , @Colunas VARCHAR(MAX)
)
WITH ENCRYPTION
AS
BEGIN

    -- ============================================================
    -- Se @Colunas for '*', busca todas as colunas da tabela origem
    -- ============================================================
    IF (@Colunas = '*')
    BEGIN
        SELECT @Colunas = ISNULL(NULLIF(@Colunas, '*') + ',', '') + b.name
        FROM sysobjects a WITH(NOLOCK)
            JOIN syscolumns b WITH(NOLOCK) ON a.id = b.id
        WHERE a.xtype = 'U'
            AND a.name = @Tabela
    END
    
    -- Montagem da instrução SQL dinâmica para exportação
    DECLARE @Exec VARCHAR(MAX)

    SET @Exec = 'INSERT INTO OPENROWSET (''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database='
        + @Caminho
        + ';'', ''SELECT '
        + @Colunas
        + ' FROM ['
        + @Aba
        + '$]'') '
        + 'SELECT '
        + @Colunas
        + ' FROM '
        + @Tabela
    
    -- Execução da instrução dinâmica
    EXEC(@Exec)

END
GO

-- ============================================================
-- Exemplo de uso da procedure [sp_InsertExcel]
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE #temp
(
      nome  VARCHAR(20)
    , email VARCHAR(20)
)

INSERT INTO #temp
VALUES
      ('debora', 'debora@gmail.com')

EXEC Management.sp_InsertExcel
    @Caminho = 'C:\SQLImportExport\Teste.xlsx'  -- Diretório do arquivo Excel
  , @Aba = 'pla01'                              -- Nome da aba (sem o '$' pois já está na procedure)
  , @Tabela = '#temp'                           -- Tabela de origem dos dados
  , @Colunas = '*'                              -- '*' para exportar todas as colunas

DROP TABLE #temp
GO
