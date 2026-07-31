/*
 *
	OBJETIVO: Documentação e exemplo de refatoração de lógica baseada em cursor 
	          para subconsultas correlacionadas (Set Based Approach), visando 
	          otimização do plano de execução pelo motor do SQL Server.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/relational-databases/performance/subqueries
 */
-- ============================================================
-- Conceito de Subconsulta Correlacionada
-- ============================================================

-- Tente reescrever seus T-SQLs baseados em cursor com subconsultas correlacionadas.
-- Geralmente, usa-se um cursor para obter um conjunto de resultados e processar 
-- cada linha individualmente para formular o resultado desejado.
-- Esse tipo de processamento pode ser substituído por uma subconsulta correlacionada 
-- (na maioria dos casos).

-- O que é uma subconsulta correlacionada?
-- É uma subconsulta onde a consulta externa precisa ser executada primeiro e, 
-- para cada linha da consulta externa, a consulta interna é executada. 
-- Isso significa que, antes de executar a consulta interna para uma linha específica, 
-- a consulta externa já foi processada para aquela linha (e, portanto, a consulta 
-- interna está correlacionada com a externa).

-- Exemplo de subconsulta correlacionada:
SELECT 
    E.Name AS [Employee Name]
    ,(
        SELECT Name 
        FROM Employee 
        WHERE ID = E.MgrID
    ) AS [Manager Name] -- CORRELAÇÃO
FROM Employee AS E

-- ============================================================
-- Decomposição da Consulta
-- ============================================================

-- Consulta externa:
SELECT 
    E.Name AS [Employee Name] 
FROM Employee AS E  -- EXTERNA

-- Consulta interna:
SELECT Name 
FROM Employee 
WHERE ID = E.MgrID  -- INTERNA

-- Nota sobre a cláusula WHERE na consulta interna (ID = E.MgrID):
-- Para executar esta consulta interna, o mecanismo de processamento de consultas 
-- precisa que E.MgrID já esteja disponível.

-- Portanto, para determinar cada linha no conjunto de resultados geral, 
-- a consulta é processada da seguinte maneira:
-- 1. Obter o valor da coluna Name (como Employee Name) e o valor da coluna MgrID da tabela Employee.
-- 2. Obter o valor da coluna Name (como Manager Name) da tabela Employee onde ID = MgrID.

-- ============================================================
-- Análise de Desempenho (Set Based Approach)
-- ============================================================

-- Como pode ser visto, para determinar cada linha no conjunto de resultados, 
-- o mecanismo de execução do SQL Server executa duas consultas SQL diferentes.
-- No entanto, a execução desta consulta é muito mais otimizada em comparação 
-- com consultas baseadas em UDF e Cursor, porque, na abordagem de subconsulta, 
-- o SQL Server decide a maneira otimizada e melhor de implementar a consulta 
-- interna em seu plano de execução (como decidir o melhor algoritmo para 
-- implementação de um JOIN).
-- Consequentemente, a consulta é executada mais rapidamente (abordagem baseada em conjunto).

-- Contudo, se você já possui alguma lógica de processamento complexa implementada 
-- usando um cursor que é executado para cada linha no conjunto de resultados, 
-- e se acredita que implementar a mesma lógica usando uma abordagem baseada em 
-- conjunto é difícil ou quase impossível, você pode seguir esta abordagem.
