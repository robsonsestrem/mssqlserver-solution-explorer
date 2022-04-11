------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo simples
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ##tabela_clientes (
  nome_cliente VARCHAR(200)
 ,cpf_cliente VARCHAR(200)
)
GO

INSERT INTO ##tabela_clientes
  VALUES ('Fabio', NULL),
  ('Jorge', 21325658454)
GO

SELECT
  *
FROM ##tabela_clientes
GO

DECLARE @nome_cliente VARCHAR(50)
       ,@cpf_cliente VARCHAR(50)

--Declarando o cursor
DECLARE nome_do_cursor CURSOR FOR

--dados que o cursos ira trabalhar
SELECT
  nome_cliente
 ,cpf_cliente
FROM ##tabela_clientes

--abre o cursor
OPEN nome_do_cursor

--posicionar o ponteiro do cursor na primeira linha do resultado do select acima
FETCH NEXT FROM nome_do_cursor

--insere nas variaveis os valores da primeira linha do resultado armazenado no cursor
INTO @nome_cliente, @cpf_cliente

--Esse parte diz "Enquanto tiver linha no cursor, faça:"
WHILE @@FETCH_STATUS = 0

--Nessa parte você insere o bloco de instruções que ira trabalhar no seu cursor.
--Se CPF for igual a nulo
BEGIN
IF ((SELECT
      cpf_cliente
    FROM ##tabela_clientes
    WHERE cpf_cliente = @cpf_cliente)
  IS NULL)

--Inserir no final do nome da pessoa o texto "Atualizar CPF"
BEGIN
  UPDATE ##tabela_clientes
  SET nome_cliente = @nome_cliente + ' Atualizar CPF'
  WHERE cpf_cliente = @cpf_cliente
END
FETCH NEXT FROM nome_do_cursor
INTO @nome_cliente, @cpf_cliente
END

--Para fechar o cursos você precisar inserir os seguinte comandos
CLOSE nome_do_cursor
DEALLOCATE nome_do_cursor

SELECT
  *
FROM ##tabela_clientes

DROP TABLE ##tabela_clientes


------------------------------------------------------------------------------------------------------------------------------------------------------
-- TIPOS DE CURSORES
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE Employee (
  EmpID INT PRIMARY KEY
 ,EmpName VARCHAR(50) NOT NULL
 ,Salary INT NOT NULL
 ,Address VARCHAR(200) NOT NULL
 ,
)
GO
INSERT INTO Employee (EmpID, EmpName, Salary, Address)
  VALUES (1, 'Mohan', 12000, 'Noida')
INSERT INTO Employee (EmpID, EmpName, Salary, Address)
  VALUES (2, 'Pavan', 25000, 'Delhi')
INSERT INTO Employee (EmpID, EmpName, Salary, Address)
  VALUES (3, 'Amit', 22000, 'Dehradun')
INSERT INTO Employee (EmpID, EmpName, Salary, Address)
  VALUES (4, 'Sonu', 22000, 'Noida')
INSERT INTO Employee (EmpID, EmpName, Salary, Address)
  VALUES (5, 'Deepak', 28000, 'Gurgaon')
GO
SELECT
  *
FROM Employee


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Static Cursor - Example
------------------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE @salary INT
DECLARE cur_emp CURSOR
STATIC FOR SELECT
  EmpID
 ,EmpName
 ,Salary
FROM Employee
OPEN cur_emp
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM cur_emp INTO @Id, @name, @salary
  WHILE @@Fetch_status = 0
  BEGIN
  PRINT 'ID : ' + CONVERT(VARCHAR(20), @Id) + ', Name : ' + @name + ', Salary : ' + CONVERT(VARCHAR(20), @salary)
  FETCH NEXT FROM cur_emp INTO @Id, @name, @salary
  END
END
CLOSE cur_emp
DEALLOCATE cur_emp
SET NOCOUNT OFF


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Dynamic Cursor - Example
------------------------------------------------------------------------------------------------------------------------------------------------------
--Dynamic Cursor for Update
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE Dynamic_cur_empupdate CURSOR
DYNAMIC FOR SELECT
  EmpID
 ,EmpName
FROM Employee
ORDER BY EmpName
OPEN Dynamic_cur_empupdate
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM Dynamic_cur_empupdate INTO @Id, @name
  WHILE @@Fetch_status = 0
  BEGIN
  IF @name = 'Mohan'
    UPDATE Employee
    SET Salary = 15000
    WHERE CURRENT OF Dynamic_cur_empupdate
  FETCH NEXT FROM Dynamic_cur_empupdate INTO @Id, @name
  END
END
CLOSE Dynamic_cur_empupdate
DEALLOCATE Dynamic_cur_empupdate
SET NOCOUNT OFF
GO
SELECT
  *
FROM Employee

-- Dynamic Cursor for DELETE
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE Dynamic_cur_empdelete CURSOR
DYNAMIC FOR SELECT
  EmpID
 ,EmpName
FROM Employee
ORDER BY EmpName
OPEN Dynamic_cur_empdelete
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM Dynamic_cur_empdelete INTO @Id, @name
  WHILE @@Fetch_status = 0
  BEGIN
  IF @name = 'Deepak'
    DELETE Employee
    WHERE CURRENT OF Dynamic_cur_empdelete
  FETCH NEXT FROM Dynamic_cur_empdelete INTO @Id, @name
  END
END
CLOSE Dynamic_cur_empdelete
DEALLOCATE Dynamic_cur_empdelete
SET NOCOUNT OFF
GO
SELECT
  *
FROM Employee


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Forward Only Cursor - Example
------------------------------------------------------------------------------------------------------------------------------------------------------
--Forward Only Cursor for Update
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE Forward_cur_empupdate CURSOR
FORWARD_ONLY FOR SELECT
  EmpID
 ,EmpName
FROM Employee
ORDER BY EmpName
OPEN Forward_cur_empupdate
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM Forward_cur_empupdate INTO @Id, @name
  WHILE @@Fetch_status = 0
  BEGIN
  IF @name = 'Amit'
    UPDATE Employee
    SET Salary = 24000
    WHERE CURRENT OF Forward_cur_empupdate
  FETCH NEXT FROM Forward_cur_empupdate INTO @Id, @name
  END
END
CLOSE Forward_cur_empupdate
DEALLOCATE Forward_cur_empupdate
SET NOCOUNT OFF
GO
SELECT
  *
FROM Employee

-- Forward Only Cursor for Delete
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE Forward_cur_empdelete CURSOR
FORWARD_ONLY FOR SELECT
  EmpID
 ,EmpName
FROM Employee
ORDER BY EmpName
OPEN Forward_cur_empdelete
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM Forward_cur_empdelete INTO @Id, @name
  WHILE @@Fetch_status = 0
  BEGIN
  IF @name = 'Sonu'
    DELETE Employee
    WHERE CURRENT OF Forward_cur_empdelete
  FETCH NEXT FROM Forward_cur_empdelete INTO @Id, @name
  END
END
CLOSE Forward_cur_empdelete
DEALLOCATE Forward_cur_empdelete
SET NOCOUNT OFF
GO
SELECT
  *
FROM Employee


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Keyset Driven Cursor - Example
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Keyset Driven Cursor for Update
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE Keyset_cur_empupdate CURSOR
KEYSET FOR SELECT
  EmpID
 ,EmpName
FROM Employee
ORDER BY EmpName
OPEN Keyset_cur_empupdate
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM Keyset_cur_empupdate INTO @Id, @name
  WHILE @@Fetch_status = 0
  BEGIN
  IF @name = 'Pavan'
    UPDATE Employee
    SET Salary = 27000
    WHERE CURRENT OF Keyset_cur_empupdate
  FETCH NEXT FROM Keyset_cur_empupdate INTO @Id, @name
  END
END
CLOSE Keyset_cur_empupdate
DEALLOCATE Keyset_cur_empupdate
SET NOCOUNT OFF
GO
SELECT
  *
FROM Employee

-- Keyset Driven Cursor for Delete
SET NOCOUNT ON
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE Keyset_cur_empdelete CURSOR
KEYSET FOR SELECT
  EmpID
 ,EmpName
FROM Employee
ORDER BY EmpName
OPEN Keyset_cur_empdelete
IF @@CURSOR_ROWS > 0
BEGIN
  FETCH NEXT FROM Keyset_cur_empdelete INTO @Id, @name
  WHILE @@Fetch_status = 0
  BEGIN
  IF @name = 'Amit'
    DELETE Employee
    WHERE CURRENT OF Keyset_cur_empdelete
  FETCH NEXT FROM Keyset_cur_empdelete INTO @Id, @name
  END
END
CLOSE Keyset_cur_empdelete
DEALLOCATE Keyset_cur_empdelete
SET NOCOUNT OFF
GO
SELECT
  *
FROM Employee
