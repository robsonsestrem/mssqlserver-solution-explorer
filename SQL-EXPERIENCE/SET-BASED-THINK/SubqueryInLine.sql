/*
 *
	OBJETIVO: Demonstração de otimização de desempenho substituindo Funções Definidas pelo Usuário (UDFs)
			  por subconsultas inline em consultas SET-based, com exemplos práticos de melhoria
			  significativa de performance (redução de 90 segundos para 1 segundo em 20.000 registros).
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Uso de subconsultas inline para substituir 
-- Funções Definidas pelo Usuário
-- ============================================================

-- ============================================================
-- Exemplo de abordagem procedural com UDF (baixo desempenho)
-- ============================================================
-- Considerando uma tabela auto-referencial Employee(ID, Name, MgrID),
-- onde MgrID referencia o ID de outro funcionário na mesma tabela.
-- A consulta abaixo retorna o nome do funcionário e o nome do seu gerente.

SELECT
    Name AS [Employee Name],
    dbo.fnGetManagerName(MgrID) AS [Manager Name]
FROM Employee

-- ============================================================
-- Definição da UDF utilizada na abordagem procedural
-- ============================================================
CREATE FUNCTION [dbo].[fnGetManagerName](@ID INT)
RETURNS VARCHAR(50)
AS
BEGIN
    -- Declara a variável para armazenar o resultado
    DECLARE @ManagerName VARCHAR(50)

    -- Obtém o nome do funcionário com base no ID informado
    SELECT @ManagerName = Name
    FROM Employee
    WHERE ID = @ID

    -- Retorna o resultado
    RETURN @ManagerName
END
GO

-- ============================================================
-- SOLUÇÃO COM MAIOR DESEMPENHO: Subconsulta inline SET-based
-- ============================================================
-- A abordagem procedural com UDF é substituída por uma subconsulta
-- correlacionada, eliminando a execução linha a linha da função
-- e obtendo ganho expressivo de performance.

SELECT
    E.Name AS [Employee Name],
    (
        SELECT Name
        FROM Employee
        WHERE ID = E.MgrID
    ) AS [Manager Name]
FROM Employee AS E
GO

-- ============================================================
-- NOTA DE PERFORMANCE
-- ============================================================
-- Em um projeto com SQL Server 2000, um procedimento armazenado
-- que processava cerca de 20.000 registros teve sua execução
-- reduzida de 90 segundos para apenas 1 segundo após substituir
-- a UDF por uma subconsulta inline, com as demais otimizações
-- já aplicadas previamente.
-- ============================================================
