/*
    OBJETIVO: Simulação de coleta de locks via cursor no SQL Server.
              Cria tabela de teste, stored procedure com cursor DYNAMIC que
              aplica WAITFOR DELAY e UPDATE posicionado (WHERE CURRENT OF),
              e query de monitoramento de cursores ativos via sys.dm_exec_cursors.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
    https://blog.sqlauthority.com/2015/01/10/sql-server-what-is-the-query-used-in-sp_cursorfetch-and-fetch-api_cursor/
*/

-- ============================================================
-- Bloco 1: Criação da tabela de teste Employee
-- ============================================================
CREATE TABLE Employee
(
    EmpID INT PRIMARY KEY
    , EmpName VARCHAR(50) NOT NULL
    , Salary INT NOT NULL
    , Address VARCHAR(200) NOT NULL
);
GO

-- ============================================================
-- Bloco 2: Inserção de dados de teste
-- ============================================================
INSERT INTO Employee (EmpID, EmpName, Salary, Address) VALUES (1, 'Mohan', 12000, 'Noida')
;
INSERT INTO Employee (EmpID, EmpName, Salary, Address) VALUES (2, 'Pavan', 25000, 'Delhi')
;
INSERT INTO Employee (EmpID, EmpName, Salary, Address) VALUES (3, 'Amit', 22000, 'Dehradun')
;
INSERT INTO Employee (EmpID, EmpName, Salary, Address) VALUES (4, 'Sonu', 22000, 'Noida')
;
INSERT INTO Employee (EmpID, EmpName, Salary, Address) VALUES (5, 'Deepak', 28000, 'Gurgaon')
;
GO

-- Verificação: lista os dados inseridos
SELECT
    *
FROM Employee;
GO

-- ============================================================
-- Bloco 3: Stored procedure com cursor DYNAMIC para simular lock
-- ============================================================
CREATE OR ALTER PROCEDURE sp_testeLock
    @newValue INT
AS
BEGIN
    DECLARE
        @Id INT
        , @name VARCHAR(50);

    -- Declara cursor DYNAMIC sobre a tabela Employee ordenada por EmpName
    DECLARE Dynamic_cur_empupdate CURSOR
    DYNAMIC
    FOR
    SELECT
        EmpID
        , EmpName
    FROM Employee
    ORDER BY
        EmpName;

    OPEN Dynamic_cur_empupdate;

    IF @@CURSOR_ROWS > 0
    BEGIN
        FETCH NEXT FROM Dynamic_cur_empupdate INTO @Id, @name;

        WHILE @@Fetch_status = 0
        BEGIN
            -- Quando encontra 'Mohan', aguarda 30 segundos e atualiza via cursor posicionado
            IF @name = 'Mohan'
            BEGIN
                WAITFOR DELAY '00:00:30';
                UPDATE Employee
                SET Salary = @newValue
                WHERE CURRENT OF Dynamic_cur_empupdate;
            END

            FETCH NEXT FROM Dynamic_cur_empupdate INTO @Id, @name;
        END
    END

    CLOSE Dynamic_cur_empupdate;
    DEALLOCATE Dynamic_cur_empupdate;
END;
GO

-- ============================================================
-- Bloco 4: Executa a procedure dentro de uma transação
-- ============================================================
BEGIN TRANSACTION;
EXECUTE sp_testeLock 1500;
COMMIT TRANSACTION;
SELECT
    @@TRANCOUNT;
GO

-- ============================================================
-- Bloco 5: Coleta de informações de cursor em outra sessão
-- ============================================================

-- Executa a coleta em outra sessão para monitorar cursores ativos
SELECT
    creation_time
    , cursor_id
    , c.session_id
    , c.properties
    , c.creation_time
    , c.is_open
    -- Extrai o texto individual da instrução usando offsets de statement
    , SUBSTRING(
        st.TEXT,
        (c.statement_start_offset / 2) + 1,
        (
            (
                CASE c.statement_end_offset
                    WHEN -1 THEN DATALENGTH(st.TEXT)
                    ELSE c.statement_end_offset
                END - c.statement_start_offset
            ) / 2
        ) + 1
    ) AS statement_text
FROM sys.dm_exec_cursors(0) AS c
INNER JOIN sys.dm_exec_sessions AS s
    ON c.session_id = s.session_id
CROSS APPLY sys.Dm_exec_sql_text(c.sql_handle) AS st;

