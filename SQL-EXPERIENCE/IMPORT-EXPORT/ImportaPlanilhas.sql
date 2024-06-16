----------------------------------------------------------------------------------------------------------------------------------
-- https://www.dirceuresende.com/blog/sql-server-como-instalar-os-drivers-microsoft-ace-oledb-12-0-e-microsoft-jet-oledb-4-0/
-- https://www.dirceuresende.com/blog/sql-server-importando-e-exportando-dados-de-planilhas-do-excel/
----------------------------------------------------------------------------------------------------------------------------------
-- como verificar quais providers existentes.
----------------------------------------------------------------------------------------------------------------------------------
EXEC master.dbo.sp_MSset_oledb_prop
-- Microsoft.ACE.OLEDB.12.0


----------------------------------------------------------------------------------------------
-- habilitar as transações distribuídas
----------------------------------------------------------------------------------------------
sp_configure 'Show Advanced Options', 1;
RECONFIGURE;
GO
sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
GO


----------------------------------------------------------------------------------------------
-- Executar os comandos abaixo para
-- habilitar as features AllowInProcess e DynamicParameters
----------------------------------------------------------------------------------------------
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0' 
    , N'AllowInProcess', 1 
GO
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0'
    , N'DynamicParameters', 1
GO


----------------------------------------------------------------------------------------------
-- Como SELECIONAR os dados, pode ser qualquer versão do excel para esta API - ACE 12.0
-- Não fazer isso com a planilha aberta
----------------------------------------------------------------------------------------------
-- Utilizando OPENROWSET
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\audit_update_st_pssoa.xlsx', [dados$])
-- OU
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\audit_update_st_pssoa.xlsx', 'SELECT * FROM [dados$]')

-- Utilizando OPENDATASOURCE
SELECT * FROM OPENDATASOURCE('Microsoft.ACE.OLEDB.12.0', 'Data Source=C:\tmp\audit_update_st_pssoa.xlsx;Extended Properties=Excel 12.0')...[dados$]

-- OUTROS TESTES
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\fetch-api-poa.xls', [dados$])
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\LCK_M_SCH_M.xls', [dados$])
-- não lê csv
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\st_pssoa_cad.csv', [st_pssoa_cad$])
SELECT * FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0', 'Excel 12.0;Database=C:\tmp\log-events-viewer-result.csv', [log-events-viewer-result$])


SELECT *													
FROM OPENROWSET (
    'Microsoft.ACE.OLEDB.12.0', 
    'Excel 12.0;Database=C:\Users\sysadmin\Documents\Devart\audit_update_st_pssoa.xlsx;', 
    'SELECT * FROM [dados$]'								
) as x


----------------------------------------------------------------------------------------------
-- Como INSERIR os dados, pode ser qualquer versão do excel para esta API - ACE 12.0
-- Não fazer isso com a planilha aberta
----------------------------------------------------------------------------------------------
--INSERT INTO 
--OPENROWSET (
--    'Microsoft.ACE.OLEDB.12.0', 
--    'Excel 12.0;Database=C:\Users\sysadmin\Documents\Devart\dbForge Studio for SQL Server\Export\audit-update-st_pssoa.xlsx;', 
--    'SELECT * FROM [pla01$]'
--)
--SELECT * FROM TABELA_ORIGEM_DADOS