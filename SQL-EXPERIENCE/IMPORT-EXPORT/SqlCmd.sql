/*
 *
	OBJETIVO: Documentação do utilitário de linha de comando SQLCMD para execução
			  de scripts SQL, incluindo exemplos de execução em batch, inserção
			  em massa e resolução de problemas de memória e limites de linhas.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://www.dirceuresende.com/blog/sqlcmd-o-utilitario-de-linha-de-comando-do-sql-server/
 *	https://www.dirceuresende.com/blog/sql-server-como-executar-em-batch-todos-os-scripts-sql-de-uma-pasta-ou-diretorio-pelo-sqlcmd/
 */
-- ============================================================
-- Solução que me salvou uma inserção em massa via sqlcmd,
-- pois dava erro por memória insuficiente ou nº de linhas
-- excedidas do script de insert.
-- ============================================================

-- ============================================================
-- Exemplo de execução de script SQL com sqlcmd
-- ============================================================
-- sqlcmd -S servidor -d banco -U usuario -P senha -i "C:\caminho\script.sql"

-- ============================================================
-- Exemplo de execução em batch de todos os scripts de uma pasta
-- ============================================================
-- for %f in (C:\caminho\*.sql) do sqlcmd -S servidor -d banco -U usuario -P senha -i "%f"

-- ============================================================
-- Exemplo com parâmetros de saída e timeout
-- ============================================================
-- sqlcmd -S servidor -d banco -U usuario -P senha -i "C:\caminho\script.sql" -o "C:\caminho\saida.log" -t 3600

-- ============================================================
-- Exemplo para inserção em massa com chunking (evitar erro de memória)
-- ============================================================
-- Dividir o script de insert em partes menores e executar separadamente
-- for %f in (C:\caminho\chunks\*.sql) do sqlcmd -S servidor -d banco -U usuario -P senha -i "%f"
