/*
 *
	OBJETIVO: Demonstração de processamento de result set utilizando TABLE VARIABLE
			  em substituição ao uso de CURSOR, evitando I/O em disco, lock de
			  recursos e comunicação inter-DB (tempdb).
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/t-sql/data-types/table-transact-sql
 */
-- ============================================================
-- Table Variable vs Cursor vs Temporary Table
-- ============================================================

-- Em vez de um cursor, utilize uma TABLE VARIABLE para processar o result set.

-- O que é uma TABLE VARIABLE?
-- Em T-SQL (desde o SQL Server 2000), uma TABLE VARIABLE é um tipo especial de
-- variável que se assemelha a uma tabela real.
-- O aspecto mais importante de uma TABLE VARIABLE é que ela reside em memória
-- quase 100% do tempo (a menos que a própria TABLE VARIABLE seja muito grande;
-- nesse caso, ela pode residir no banco de dados tempdb).

-- O uso de uma TABLE VARIABLE é eficiente (na maioria das vezes, em termos de
-- memória e tempo de execução) em comparação com tabelas temporárias, pelos
-- seguintes motivos:

-- Tabelas temporárias residem no banco de dados tempdb, e operar sobre elas
-- resulta em comunicação inter-DB. Isso tende a ser lento.
-- TABLE VARIABLES são majoritariamente variáveis em memória, portanto o I/O
-- em TABLE VARIABLES tende a ser rápido.

-- Operar sobre tabelas temporárias resulta em grande atividade de disco e uso
-- de recursos porque:
-- 1. A tabela temporária precisa ser criada
-- 2. Os dados precisam ser inseridos na tabela temporária
-- 3. Frequentemente, a tabela temporária precisa ser unida (JOIN) a uma tabela
--    física para obter um resultado
-- 4. Um lock precisa ser estabelecido na tabela temporária durante a atualização
--    dos dados
-- 5. A tabela temporária precisa ser removida (DROP)

-- Por outro lado, operar sobre TABLE VARIABLES não requer lock sobre os recursos.
-- Além disso, a inserção de dados em uma TABLE VARIABLE é muito mais rápida do que
-- em uma tabela temporária, pois não ocorre I/O de disco nem comunicação inter-DB.
-- A TABLE VARIABLE também sai de escopo quando o bloco SQL correspondente sai de
-- escopo, portanto TABLE VARIABLES não precisam ser removidas com DROP.
-- Tudo isso torna TABLE VARIABLES uma excelente escolha para implementar T-SQL
-- mais rápido.

-- É possível utilizar TABLE VARIABLES no lugar de CURSORS?
-- Sim. A seguir, um exemplo de processamento de result set utilizando TABLE VARIABLE.

-- SOLUÇÃO COM MAIOR DESEMPENHO

-- Declaração da TABLE VARIABLE
DECLARE @Elements TABLE
(
    Number INT IDENTITY(1,1) -- Auto incrementing Identity column
    ,ProductName VARCHAR(300) -- The string value
)

-- Declaração de variável para rastrear a posição atual do delimitador
DECLARE @N INT

-- Declaração de variável para armazenar o número de linhas na tabela
DECLARE @Count INT

-- Populando a TABLE VARIABLE com dados da tabela de produtos
INSERT INTO @Elements
SELECT Name
FROM dbo.Products

-- Inicialização da variável de iteração
SET @N = 1

-- Determinação do número total de linhas na TABLE VARIABLE
SELECT @Count = MAX(Number)
FROM @Elements

-- Variável para armazenar o valor atualmente selecionado da tabela
DECLARE @CurrentValue VARCHAR(300);

-- Loop para processamento de todas as linhas do result set
WHILE @N <= @Count
BEGIN
    -- Carregamento do valor atual da TABLE VARIABLE
    SELECT @CurrentValue = ProductName
    FROM @Elements
    WHERE Number = @N

    -- Processamento do valor atual
    PRINT @CurrentValue

    -- Incremento do contador de iteração
    SET @N = @N + 1;
END

-- A substituição de código baseado em CURSOR por código baseado em TABLE VARIABLE
-- proporciona ganhos significativos de performance.
-- Observação: ainda assim, deve-se evitar escrever T-SQL utilizando abordagem
-- procedural (o uso de TABLE VARIABLE ainda é uma abordagem procedural).
-- Contudo, se for realmente necessário escrever uma forma própria de processamento
-- de result set, utilize TABLE VARIABLES para evitar CURSORS.
