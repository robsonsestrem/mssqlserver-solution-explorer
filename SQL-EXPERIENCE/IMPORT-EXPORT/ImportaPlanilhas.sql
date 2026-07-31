/*
 *
	OBJETIVO: Procedimentos para importação e exportação de dados entre SQL Server e
			  planilhas Excel utilizando os drivers Microsoft ACE OLEDB 12.0,
			  incluindo configuração de permissões, exemplos de SELECT e INSERT
			  com OPENROWSET e OPENDATASOURCE.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.dirceuresende.com/blog/sql-server-como-instalar-os-drivers-microsoft-ace-oledb-12-0-e-microsoft-jet-oledb-4-0/
 *	https://www.dirceuresende.com/blog/sql-server-importando-e-exportando-dados-de-planilhas-do-excel/
 */
-- ============================================================
-- Verificar providers existentes
-- ============================================================
EXEC master.dbo.sp_MSset_oledb_prop
-- Microsoft.ACE.OLEDB.12.0

-- ============================================================
-- Habilitar transações distribuídas e consultas ad hoc
-- ============================================================
sp_configure 'Show Advanced Options', 1
RECONFIGURE
GO

sp_configure 'Ad Hoc Distributed Queries', 1
RECONFIGURE
GO

-- ============================================================
-- Habilitar features AllowInProcess e DynamicParameters para o provider
-- ============================================================
EXEC master.dbo.sp_MSset_oledb_prop
    N'Microsoft.ACE.OLEDB.12.0',
    N'AllowInProcess',
    1
GO

EXEC master.dbo.sp_MSset_oledb_prop
    N'Microsoft.ACE.OLEDB.12.0',
    N'DynamicParameters',
    1
GO

-- ============================================================
-- SELECT utilizando OPENROWSET (Excel)
-- ============================================================
-- Não fazer isso com a planilha aberta

-- Utilizando OPENROWSET com nome da planilha
SELECT *
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\tmp\audit_update_st_pssoa.xlsx',
    [dados$]
)

-- Utilizando OPENROWSET com consulta SQL
SELECT *
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\tmp\audit_update_st_pssoa.xlsx',
    'SELECT * FROM [dados$]'
)

-- ============================================================
-- SELECT utilizando OPENDATASOURCE (Excel)
-- ============================================================
SELECT *
FROM OPENDATASOURCE(
    'Microsoft.ACE.OLEDB.12.0',
    'Data Source=C:\tmp\audit_update_st_pssoa.xlsx;Extended Properties=Excel 12.0'
)...[dados$]

-- ============================================================
-- Testes com outros arquivos
-- ============================================================
-- SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\fetch-api-poa.xls', [dados$])
-- SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\LCK_M_SCH_M.xls', [dados$])

-- ============================================================
-- Não lê arquivos CSV diretamente
-- ============================================================
-- SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\st_pssoa_cad.csv', [st_pssoa_cad$])
-- SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\log-events-viewer-result.csv', [log-events-viewer-result$])

-- ============================================================
-- SELECT com alias e formatação completa
-- ============================================================
SELECT *
FROM OPENROWSET(
    'Microsoft.ACE.OLEDB.12.0',
    'Excel 12.0;Database=C:\Users\sysadmin\Documents\Devart\audit_update_st_pssoa.xlsx;',
    'SELECT * FROM [dados$]'
) AS x

-- ============================================================
-- INSERT utilizando OPENROWSET (Excel)
-- ============================================================
-- INSERT INTO
-- OPENROWSET(
--     'Microsoft.ACE.OLEDB.12.0',
--     'Excel 12.0;Database=C:\Users\sysadmin\Documents\Devart\dbForge Studio for SQL Server\Export\audit-update-st_pssoa.xlsx;',
--     'SELECT * FROM [pla01$]'
-- )
-- SELECT * FROM TABELA_ORIGEM_DADOS
