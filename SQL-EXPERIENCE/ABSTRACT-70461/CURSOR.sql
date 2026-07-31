/*
 *
	OBJETIVO: Demonstração completa dos tipos de cursor disponíveis no T-SQL
			  (Static, Dynamic, Forward Only e Keyset Driven), com exemplos
			  práticos de operações UPDATE e DELETE utilizando WHERE CURRENT OF,
			  além de exemplo básico de cursor para processamento linha a linha.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *
 */
-- ============================================================
-- SEÇÃO 1: EXEMPLO BÁSICO DE CURSOR
-- Processamento linha a linha com validação condicional
-- ============================================================
-- Criação da tabela temporária global de clientes
CREATE TABLE ##tabela_clientes
(
    nome_cliente VARCHAR(200)
    ,cpf_cliente VARCHAR(200)
)
GO

-- Inserção de dados de teste (um com CPF nulo, outro válido)
INSERT INTO ##tabela_clientes
VALUES
    ('Fabio', NULL)
    ,('Jorge', 21325658454)
GO

-- Consulta inicial dos dados inseridos
SELECT
    t.nome_cliente
    ,t.cpf_cliente
FROM ##tabela_clientes AS t
GO

-- Declaração das variáveis de controle do cursor
DECLARE @nome_cliente VARCHAR(50)
DECLARE @cpf_cliente VARCHAR(50)

-- Declaração do cursor com base na consulta de clientes
DECLARE nome_do_cursor CURSOR FOR
SELECT
    t.nome_cliente
    ,t.cpf_cliente
FROM ##tabela_clientes AS t

-- Abertura do cursor
OPEN nome_do_cursor

-- Posicionamento do ponteiro na primeira linha e carregamento nas variáveis
FETCH NEXT FROM nome_do_cursor
INTO @nome_cliente
    ,@cpf_cliente

-- Loop de processamento enquanto houver linhas disponíveis
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Validação condicional: se o CPF for nulo, atualiza o nome do cliente
    IF
    (
        SELECT
            t.cpf_cliente
        FROM ##tabela_clientes AS t
        WHERE t.cpf_cliente = @cpf_cliente
    ) IS NULL
    BEGIN
        -- Concatenação do texto de alerta ao nome do cliente
        UPDATE ##tabela_clientes
        SET nome_cliente = @nome_cliente + ' Atualizar CPF'
        WHERE cpf_cliente = @cpf_cliente
    END

    -- Avanço do cursor para a próxima linha
    FETCH NEXT FROM nome_do_cursor
    INTO @nome_cliente
        ,@cpf_cliente
END

-- Encerramento e liberação do cursor
CLOSE nome_do_cursor
DEALLOCATE nome_do_cursor

-- Consulta final após processamento
SELECT
    t.nome_cliente
    ,t.cpf_cliente
FROM ##tabela_clientes AS t

-- Remoção da tabela temporária
DROP TABLE ##tabela_clientes


-- ============================================================
-- SEÇÃO 2: TABELA BASE PARA EXEMPLOS DE CURSORES
-- ============================================================
-- Criação da tabela Employee para demonstração dos tipos de cursor
CREATE TABLE Employee
(
    EmpID INT PRIMARY KEY
    ,EmpName VARCHAR(50) NOT NULL
    ,Salary INT NOT NULL
    ,Address VARCHAR(200) NOT NULL
)
GO

-- Inserção dos dados de exemplo
INSERT INTO Employee (EmpID, EmpName, Salary, Address)
VALUES
    (1, 'Mohan', 12000, 'Noida')
    ,(2, 'Pavan', 25000, 'Delhi')
    ,(3, 'Amit', 22000, 'Dehradun')
    ,(4, 'Sonu', 22000, 'Noida')
    ,(5, 'Deepak', 28000, 'Gurgaon')
GO

-- Consulta inicial dos dados
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e


-- ============================================================
-- SEÇÃO 3: STATIC CURSOR
-- Snapshot estático: não reflete alterações durante a iteração
-- ============================================================
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)
DECLARE @salary INT

-- Declaração do cursor STATIC com snapshot dos dados no momento da abertura
DECLARE cur_emp CURSOR
STATIC FOR
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
FROM Employee AS e

-- Abertura do cursor
OPEN cur_emp

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM cur_emp
    INTO @Id
        ,@name
        ,@salary

    -- Loop de impressão dos dados
    WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'ID : ' + CONVERT(VARCHAR(20), @Id) + ', Name : ' + @name + ', Salary : ' + CONVERT(VARCHAR(20), @salary)

        -- Avanço para a próxima linha
        FETCH NEXT FROM cur_emp
        INTO @Id
            ,@name
            ,@salary
    END
END

-- Encerramento e liberação do cursor
CLOSE cur_emp
DEALLOCATE cur_emp

SET NOCOUNT OFF


-- ============================================================
-- SEÇÃO 4: DYNAMIC CURSOR - UPDATE
-- Cursor dinâmico: reflete alterações 
-- e permite UPDATE CURRENT OF
-- ============================================================
-- Dynamic Cursor for Update
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)

-- Declaração do cursor DYNAMIC ordenado por nome
DECLARE Dynamic_cur_empupdate CURSOR
DYNAMIC FOR
SELECT
    e.EmpID
    ,e.EmpName
FROM Employee AS e
ORDER BY e.EmpName

-- Abertura do cursor
OPEN Dynamic_cur_empupdate

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM Dynamic_cur_empupdate
    INTO @Id
        ,@name

    -- Loop com atualização condicional via WHERE CURRENT OF
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Atualização do salário do funcionário Mohan
        IF @name = 'Mohan'
        BEGIN
            UPDATE Employee
            SET Salary = 15000
            WHERE CURRENT OF Dynamic_cur_empupdate
        END

        -- Avanço para a próxima linha
        FETCH NEXT FROM Dynamic_cur_empupdate
        INTO @Id
            ,@name
    END
END

-- Encerramento e liberação do cursor
CLOSE Dynamic_cur_empupdate
DEALLOCATE Dynamic_cur_empupdate

SET NOCOUNT OFF
GO

-- Consulta de validação após UPDATE
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e


-- ============================================================
-- SEÇÃO 5: DYNAMIC CURSOR - DELETE
-- Cursor dinâmico com DELETE CURRENT OF
-- ============================================================
-- Dynamic Cursor for DELETE
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)

-- Declaração do cursor DYNAMIC ordenado por nome
DECLARE Dynamic_cur_empdelete CURSOR
DYNAMIC FOR
SELECT
    e.EmpID
    ,e.EmpName
FROM Employee AS e
ORDER BY e.EmpName

-- Abertura do cursor
OPEN Dynamic_cur_empdelete

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM Dynamic_cur_empdelete
    INTO @Id
        ,@name

    -- Loop com exclusão condicional via WHERE CURRENT OF
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Exclusão do funcionário Deepak
        IF @name = 'Deepak'
        BEGIN
            DELETE Employee
            WHERE CURRENT OF Dynamic_cur_empdelete
        END

        -- Avanço para a próxima linha
        FETCH NEXT FROM Dynamic_cur_empdelete
        INTO @Id
            ,@name
    END
END

-- Encerramento e liberação do cursor
CLOSE Dynamic_cur_empdelete
DEALLOCATE Dynamic_cur_empdelete

SET NOCOUNT OFF
GO

-- Consulta de validação após DELETE
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e


-- ============================================================
-- SEÇÃO 6: FORWARD ONLY CURSOR - UPDATE
-- Cursor unidirecional: apenas avanço, sem scroll
-- ============================================================
-- Forward Only Cursor for Update
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)

-- Declaração do cursor FORWARD_ONLY ordenado por nome
DECLARE Forward_cur_empupdate CURSOR
FORWARD_ONLY FOR
SELECT
    e.EmpID
    ,e.EmpName
FROM Employee AS e
ORDER BY e.EmpName

-- Abertura do cursor
OPEN Forward_cur_empupdate

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM Forward_cur_empupdate
    INTO @Id
        ,@name

    -- Loop com atualização condicional via WHERE CURRENT OF
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Atualização do salário do funcionário Amit
        IF @name = 'Amit'
        BEGIN
            UPDATE Employee
            SET Salary = 24000
            WHERE CURRENT OF Forward_cur_empupdate
        END

        -- Avanço para a próxima linha
        FETCH NEXT FROM Forward_cur_empupdate
        INTO @Id
            ,@name
    END
END

-- Encerramento e liberação do cursor
CLOSE Forward_cur_empupdate
DEALLOCATE Forward_cur_empupdate

SET NOCOUNT OFF
GO

-- Consulta de validação após UPDATE
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e


-- ============================================================
-- SEÇÃO 7: FORWARD ONLY CURSOR - DELETE
-- Cursor unidirecional com DELETE CURRENT OF
-- ============================================================
-- Forward Only Cursor for Delete
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)

-- Declaração do cursor FORWARD_ONLY ordenado por nome
DECLARE Forward_cur_empdelete CURSOR
FORWARD_ONLY FOR
SELECT
    e.EmpID
    ,e.EmpName
FROM Employee AS e
ORDER BY e.EmpName

-- Abertura do cursor
OPEN Forward_cur_empdelete

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM Forward_cur_empdelete
    INTO @Id
        ,@name

    -- Loop com exclusão condicional via WHERE CURRENT OF
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Exclusão do funcionário Sonu
        IF @name = 'Sonu'
        BEGIN
            DELETE Employee
            WHERE CURRENT OF Forward_cur_empdelete
        END

        -- Avanço para a próxima linha
        FETCH NEXT FROM Forward_cur_empdelete
        INTO @Id
            ,@name
    END
END

-- Encerramento e liberação do cursor
CLOSE Forward_cur_empdelete
DEALLOCATE Forward_cur_empdelete

SET NOCOUNT OFF
GO

-- Consulta de validação após DELETE
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e


-- ============================================================
-- SEÇÃO 8: KEYSET DRIVEN CURSOR - UPDATE
-- Cursor baseado em conjunto de chaves: mantém estrutura fixa
-- ============================================================

-- Keyset Driven Cursor for Update
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)

-- Declaração do cursor KEYSET ordenado por nome
DECLARE Keyset_cur_empupdate CURSOR
KEYSET FOR
SELECT
    e.EmpID
    ,e.EmpName
FROM Employee AS e
ORDER BY e.EmpName

-- Abertura do cursor
OPEN Keyset_cur_empupdate

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM Keyset_cur_empupdate
    INTO @Id
        ,@name

    -- Loop com atualização condicional via WHERE CURRENT OF
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Atualização do salário do funcionário Pavan
        IF @name = 'Pavan'
        BEGIN
            UPDATE Employee
            SET Salary = 27000
            WHERE CURRENT OF Keyset_cur_empupdate
        END

        -- Avanço para a próxima linha
        FETCH NEXT FROM Keyset_cur_empupdate
        INTO @Id
            ,@name
    END
END

-- Encerramento e liberação do cursor
CLOSE Keyset_cur_empupdate
DEALLOCATE Keyset_cur_empupdate

SET NOCOUNT OFF
GO

-- Consulta de validação após UPDATE
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e


-- ============================================================
-- SEÇÃO 9: KEYSET DRIVEN CURSOR - DELETE
-- Cursor baseado em conjunto de chaves com DELETE CURRENT OF
-- ============================================================
-- Keyset Driven Cursor for Delete
SET NOCOUNT ON

-- Declaração de variáveis de controle
DECLARE @Id INT
DECLARE @name VARCHAR(50)

-- Declaração do cursor KEYSET ordenado por nome
DECLARE Keyset_cur_empdelete CURSOR
KEYSET FOR
SELECT
    e.EmpID
    ,e.EmpName
FROM Employee AS e
ORDER BY e.EmpName

-- Abertura do cursor
OPEN Keyset_cur_empdelete

-- Processamento das linhas se houver registros disponíveis
IF @@CURSOR_ROWS > 0
BEGIN
    -- Carregamento da primeira linha
    FETCH NEXT FROM Keyset_cur_empdelete
    INTO @Id
        ,@name

    -- Loop com exclusão condicional via WHERE CURRENT OF
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Exclusão do funcionário Amit
        IF @name = 'Amit'
        BEGIN
            DELETE Employee
            WHERE CURRENT OF Keyset_cur_empdelete
        END

        -- Avanço para a próxima linha
        FETCH NEXT FROM Keyset_cur_empdelete
        INTO @Id
            ,@name
    END
END

-- Encerramento e liberação do cursor
CLOSE Keyset_cur_empdelete
DEALLOCATE Keyset_cur_empdelete

SET NOCOUNT OFF
GO

-- Consulta de validação após DELETE
SELECT
    e.EmpID
    ,e.EmpName
    ,e.Salary
    ,e.Address
FROM Employee AS e
