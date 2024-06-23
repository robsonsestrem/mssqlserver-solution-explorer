--REFERÊNCIAS
-- https://gustavomaiaaguiar.wordpress.com/2009/08/01/piores-praticas-%E2%80%93-utilizar-o-comando-backup-log-com-a-opcao-with-truncate_only-%E2%80%93-parte-i/
-- https://www.brentozar.com/archive/2009/08/backup-log-with-truncate-only-in-sql-server-2008/
-- http://solutioncenter.apexsql.com/pt/lendo-um-sql-server-transaction-log/
-- https://blog.sqlauthority.com/2010/11/10/sql-server-get-database-backup-history-for-a-single-database/
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- USANDO FUNÇÃO INTERNA sys.fn_dblog
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- fn_dblog é uma função não documentada no SQL Server que lê a parte ativa de um transaction log
-- Vamos ver os passos necessários para fazer e ver o resultado apresentado
-- Execute a função fn_dblog
Select * FROM sys.fn_dblog(NULL,NULL)

--Para visualizar transações de linhas inseridas, execute:

SELECT [Current LSN], 
       Operation, 
       Context, 
       [Transaction ID], 
       [Begin time]
       FROM sys.fn_dblog
   (NULL, NULL)
  WHERE operation IN
   ('LOP_INSERT_ROWS');

--Para visualizar transações de registros apagados, execute:

SELECT [begin time], 
       [rowlog contents 1], 
       [Transaction Name], 
       Operation
  FROM sys.fn_dblog
   (NULL, NULL)
  WHERE operation IN
   ('LOP_DELETE_ROWS');
   
   
   