/*
    OBJETIVO: Demonstrar o uso da função não documentada sys.fn_dblog para leitura
              da parte ativa do transaction log do SQL Server, identificando operações
              de INSERT e DELETE em nível de registro.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://gustavomaiaaguiar.wordpress.com/2009/08/01/piores-praticas-utilizar-o-comando-backup-log-com-a-opcao-with-truncate_only-parte-i/
    https://www.brentozar.com/archive/2009/08/backup-log-with-truncate-only-in-sql-server-2008/
    http://solutioncenter.apexsql.com/pt/lendo-um-sql-server-transaction-log/
    https://blog.sqlauthority.com/2010/11/10/sql-server-get-database-backup-history-for-a-single-database/
*/

-- ============================================================
-- SEÇÃO 1: Consulta geral da função sys.fn_dblog
-- ============================================================

-- A função sys.fn_dblog é não documentada e lê a parte ativa do transaction log
-- Execução completa sem filtros para visualização geral das operações registradas
SELECT *
FROM sys.fn_dblog(NULL, NULL);

-- ============================================================
-- SEÇÃO 2: Visualização de transações de linhas inseridas
-- ============================================================

-- Filtra apenas operações de inserção de registros (LOP_INSERT_ROWS)
-- para identificar quais transações adicionaram dados ao banco
SELECT 
    [Current LSN]
    , Operation
    , Context
    , [Transaction ID]
    , [Begin time]
FROM sys.fn_dblog(NULL, NULL)
WHERE Operation IN ('LOP_INSERT_ROWS');

-- ============================================================
-- SEÇÃO 3: Visualização de transações de registros apagados
-- ============================================================

-- Filtra apenas operações de exclusão de registros (LOP_DELETE_ROWS)
-- para identificar quais transações removeram dados do banco
SELECT 
    [begin time]
    , [rowlog contents 1]
    , [Transaction Name]
    , Operation
FROM sys.fn_dblog(NULL, NULL)
WHERE Operation IN ('LOP_DELETE_ROWS');
