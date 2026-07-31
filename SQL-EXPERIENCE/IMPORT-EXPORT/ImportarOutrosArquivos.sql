/*
 *
	OBJETIVO: Documentação de métodos para importação e exportação de arquivos de texto
			  no SQL Server, incluindo abordagens com BULK INSERT, OPENROWSET,
			  OLE Automation e CLR, com referências a delimitadores e parâmetros
			  para formatação de arquivos.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.dirceuresende.com/blog/sql-server-como-importar-arquivos-de-texto-para-o-banco-ole-automation-clr-bcp-bulk-insert-openrowset/
 *	https://imasters.com.br/banco-de-dados/sql-server/importando-multiplos-arquivos-texto/?trace=1519021197&source=single
 *	https://www.dirceuresende.com/blog/sql-server-como-exportar-dados-do-banco-para-arquivo-texto-clr-ole-bcp/
 */
-- ============================================================
-- Parâmetros para formatação de arquivos de texto
-- ============================================================
-- separador de colunas (caractere de tabulação \t)
-- identificador de final do registro (caractere de retorno de linha \n)

-- ============================================================
-- Exemplo de BULK INSERT com parâmetros de formatação
-- ============================================================
-- BULK INSERT dbo.tabela_destino
-- FROM 'C:\caminho\arquivo.txt'
-- WITH
-- (
--     FIELDTERMINATOR = '\t',    -- separador de colunas (tabulação)
--     ROWTERMINATOR = '\n',      -- separador de linhas
--     FIRSTROW = 2,              -- ignora cabeçalho
--     CODEPAGE = '65001'         -- UTF-8
-- )

-- ============================================================
-- Exemplo de OPENROWSET com arquivo de texto
-- ============================================================
-- SELECT *
-- FROM OPENROWSET(
--     BULK 'C:\caminho\arquivo.txt',
--     FORMATFILE = 'C:\caminho\formato.xml',  -- arquivo de formato
--     FIRSTROW = 2
-- ) AS dados

-- ============================================================
-- Exemplo de BCP para exportação
-- ============================================================
-- bcp "SELECT * FROM dbo.tabela_origem" queryout "C:\caminho\arquivo.txt" -c -t\t -S servidor -d banco -U usuario -P senha
