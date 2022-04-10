---------------------------------------------------------------------------------------------------------------------------
SET DATEFIRST 7;  

SELECT CAST('1999-1-1' AS datetime2) AS SelectDate  
    ,DATEPART(dw, '1999-1-1') AS DayOfWeek;  
-- January 1, 1999 is a Friday. Because the U.S. English default   
-- specifies Sunday as the first day of the week, DATEPART of 1999-1-1  
-- (Friday) yields a value of 6, because Friday is the sixth day of the   
-- week when you start with Sunday as day 1.  

SET DATEFIRST 3;  
-- Because Wednesday is now considered the first day of the week,  
-- DATEPART now shows that 1999-1-1 (a Friday) is the third day of the   
-- week. The following DATEPART function should return a value of 3.  
SELECT CAST('1999-1-1' AS datetime2) AS SelectDate  
    ,DATEPART(dw, '1999-1-1') AS DayOfWeek;  
GO 


---------------------------------------------------------------------------------------------------------------------------
SET DEADLOCK_PRIORITY HIGH -- LOW | NORMAL | HIGH | <numeric-priority> | @deadlock_var | @deadlock_intvar
-- Diz pra sess�o que prioridade tem caso de um deadLock, por exemplo se deixar como 
-- "HIGH" tem menor chance de ser escolhido como v�tima


---------------------------------------------------------------------------------------------------------------------------
SET IDENTITY_INSERT dbo.Cliente ON;
-- Permite inserir valores expl�citos em uma coluna IDENTITY (Somente uma tabela em uma sess�o
-- pode ter a propriedade IDENTITY_INSERT de�nida como ON)


---------------------------------------------------------------------------------------------------------------------------
SET QUOTED_IDENTIFIER ON;
-- assim permite colocar aspas duplas em palavras reservadas nos comandos
-- exemplo -> SELECT "identity","order" FROM "select"


---------------------------------------------------------------------------------------------------------------------------
SET ARITHABORT ON
-- Define se ao ocorrer overflow ou erro de divis�o por zero a consulta ser� encerrada (ON)


---------------------------------------------------------------------------------------------------------------------------
SET ROWCOUNT 0; -- traz os dez primeiros registros
GO
SELECT * FROM tabela_teste as t1


---------------------------------------------------------------------------------------------------------------------------
-- Especifica valor de varchar por linha que ir� trazer em todos os campos
SET TEXTSIZE 10 -- -1
select t1.TextData from tabela_teste as t1


---------------------------------------------------------------------------------------------------------------------------
-- Quando SET ANSI_PADDING = ON, espa�os � direita ser�o cortados em colunas VARCHAR e
-- VARBINARY


---------------------------------------------------------------------------------------------------------------------------
-- Quando SET ANSI_NULLS � OFF, os operadores de compara��o Igual a (=) e Diferente de (<>) n�o
-- seguem o padr�o ISO. Uma instru��o SELECT que usa WHERE column_name = NULL retorna as
-- linhas que t�m valores nulos em column_name


---------------------------------------------------------------------------------------------------------------------------
SET ANSI_WARNINGS ON
-- � Quando definida como ON, se forem exibidos valores nulos em fun��es de agrega��o, como
-- SUM, AVG, MAX, MIN, STDEV, STDEVP, VAR, VARP ou COUNT, ser� gerada uma mensagem de
-- aviso. Quando definido como OFF, nenhum aviso � emitido.


---------------------------------------------------------------------------------------------------------------------------
SET FORCEPLAN ON
-- Quando FORCEPLAN est� definido como ON, o otimizador de consulta do SQL Server processa os
-- JOINS na mesma ordem conforme as tabelas s�o exibidas na cl�usula FROM de uma consulta


---------------------------------------------------------------------------------------------------------------------------
SET STATISTICS XML ON -- no caso do SET SHOWPLAN_XML ON ele s� traz o plano e n�o a consulta
-- Quando � ON, Faz com que o SQL Server execute instru��es e gere informa��es detalhadas sobre
-- como as instru��es foram executadas na forma de um documento XML:
-- select t1.TextData, t1.StartTime from Management.TraceSlowQuery as t1
-- where t1.StartTime >= '20171120'


---------------------------------------------------------------------------------------------------------------------------
SET SHOWPLAN_XML OFF
-- select t1.TextData, t1.StartTime from Management.TraceSlowQuery as t1
-- where t1.StartTime >= '20171120'


---------------------------------------------------------------------------------------------------------------------------
SET ANSI_NULL_DFLT_ON ON
-- Quando SET ANSI_NULL_DFLT_OFF for ON, novas colunas criadas com o uso das instru��es ALTER
-- TABLE e CREATE TABLE aceitar�o valores NULL se n�o for especi�cado explicitamente


---------------------------------------------------------------------------------------------------------------------------
SET XACT_ABORT ON
-- Quando � ON, especifica que o SQL Server deve reverter (ROLLBACK) automaticamente a
-- transa��o atual quando uma instru��o Transact-SQL gerar um erro em tempo de execu��o.

CREATE TABLE t1 
    (a INT NOT NULL PRIMARY KEY);  
CREATE TABLE t2  
    (a INT NOT NULL REFERENCES t1(a));  
GO  
INSERT INTO t1 VALUES (1);  
INSERT INTO t1 VALUES (3);  
INSERT INTO t1 VALUES (4);  
INSERT INTO t1 VALUES (6);  
GO  
SET XACT_ABORT OFF;  
GO  
BEGIN TRANSACTION;  
INSERT INTO t2 VALUES (1);  
INSERT INTO t2 VALUES (2); -- Foreign key error.  o 2 n�o existe na tabela origem da� cai na constraint
INSERT INTO t2 VALUES (3); -- por�m vai fazer o insert dos outros dados
COMMIT TRANSACTION;  
GO  
SET XACT_ABORT ON;  -- n�o vai deixar inserir nada devido ao erro
GO  
BEGIN TRANSACTION;  
INSERT INTO t2 VALUES (4);  
INSERT INTO t2 VALUES (5); -- Foreign key error.  
INSERT INTO t2 VALUES (6);  
COMMIT TRANSACTION;  
GO  

select * from dbo.t1
select * from dbo.t2


-- testes da transa��o
BEGIN TRY
  BEGIN TRANSACTION;
  INSERT INTO dbo.SimpleOrders (custid, empid, orderdate)
    VALUES (68, 9, '2006-07-12');
  INSERT INTO dbo.SimpleOrderDetails (orderid, productid, unitprice, qty)
    VALUES (1, 2, 15.20, 20);
  COMMIT TRANSACTION;
END TRY
BEGIN CATCH
  SELECT
    ERROR_NUMBER() AS ErrNum
   ,ERROR_MESSAGE() AS ErrMsg;
  IF (XACT_STATE()) = -1
  BEGIN
    PRINT 'A transa��o est� em um estado incompat�vel. Retrocedendo transa��o.'
    ROLLBACK TRANSACTION;
  END;
  IF (XACT_STATE()) = 1
  BEGIN
    PRINT 'A transa��o � compat�vel. Transa��o completada.'
    COMMIT TRANSACTION;
  END;
END CATCH


/*********/
-- Obs: A fun��o @@ROWCOUNT � atualizada mesmo quando SET NOCOUNT � ON
/*********/