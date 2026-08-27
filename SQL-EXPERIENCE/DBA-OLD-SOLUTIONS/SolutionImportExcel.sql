/*
 *
    OBJETIVO: Procedure para importação de dados de planilhas Excel via OPENROWSET,
              usando o provider Microsoft.ACE.OLEDB.12.0.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/pt-br/sql/t-sql/functions/openrowset-transact-sql
 */
USE YOUR_DATABASE
GO

-- ============================================================
-- Procedure Management.sp_ImportExcel
-- ============================================================
CREATE OR ALTER PROCEDURE Management.[sp_ImportExcel]
(
    @Caminho VARCHAR(5000)
  , @Aba VARCHAR(200)
  , @Colunas VARCHAR(5000)
)
WITH ENCRYPTION
AS
BEGIN
    DECLARE @Exec VARCHAR(MAX)

    -- Montagem do comando dinâmico de importação
    SET @Exec = 'SELECT * FROM OPENROWSET (''Microsoft.ACE.OLEDB.12.0'', ''Excel 12.0;Database='
        + @Caminho
        + ';'', ''SELECT '
        + @Colunas
        + ' FROM ['
        + @Aba
        + '$]'') AS A'

    -- Execução do comando dinâmico
    EXEC(@Exec)
END
GO

-- ============================================================
-- Exemplo de uso
-- ============================================================
 USE DBA_PerformanceHub
 GO
 EXEC Management.sp_ImportExcel
     @Caminho = 'C:\SQLImportExport\Teste.xlsx' -- Diretório
   , @Aba = 'pla02' -- Guia do excel (sifrão já está na procedure)
   , @Colunas = '*' -- Campos
