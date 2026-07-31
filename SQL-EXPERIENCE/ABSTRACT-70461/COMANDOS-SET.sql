/*
 *
    OBJETIVO: Coleção de comandos SET do SQL Server para configuração de
              opções de sessão: DATEFIRST, DEADLOCK_PRIORITY, IDENTITY_INSERT,
              QUOTED_IDENTIFIER, ARITHABORT, ROWCOUNT, TEXTSIZE, ANSI_WARNINGS,
              FORCEPLAN, STATISTICS XML, SHOWPLAN_XML, ANSI_NULL_DFLT_ON e
              XACT_ABORT. Inclui exemplos práticos com transações e
              tratamento de erros via TRY...CATCH com XACT_STATE().
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIA: Curso ProWay - https://proway.com.br/
 * 
 */
-- ============================================================
-- SET DATEFIRST: Define o primeiro dia da semana
-- ============================================================
-- Define domingo (7) como primeiro dia da semana
SET DATEFIRST 7;

-- 1 de janeiro de 1999 é uma sexta-feira. Com DATEFIRST = 7 (domingo),
-- DATEPART(dw, ...) retorna 6, pois sexta é o 6º dia a partir de domingo
SELECT
      CAST('1999-1-1' AS DATETIME2) AS SelectDate
    , DATEPART(dw, '1999-1-1') AS DayOfWeek;

-- Define quarta-feira (3) como primeiro dia da semana
SET DATEFIRST 3;

-- Agora sexta-feira é o 3º dia da semana. DATEPART deve retornar 3
SELECT
      CAST('1999-1-1' AS DATETIME2) AS SelectDate
    , DATEPART(dw, '1999-1-1') AS DayOfWeek;
GO


-- ============================================================
-- SET DEADLOCK_PRIORITY: Define prioridade 
-- da sessão em deadlocks
-- ============================================================
-- Opções: LOW | NORMAL | HIGH | <numeric-priority> | @deadlock_var | @deadlock_intvar
-- HIGH reduz a chance de a sessão ser escolhida como vítima de deadlock
SET DEADLOCK_PRIORITY HIGH


-- ============================================================
-- SET IDENTITY_INSERT: Permite inserir 
-- valores explícitos em coluna IDENTITY
-- ============================================================
-- Somente uma tabela por sessão pode ter IDENTITY_INSERT = ON simultaneamente
SET IDENTITY_INSERT dbo.Cliente ON;


-- ============================================================
-- SET QUOTED_IDENTIFIER: Permite uso de 
-- aspas duplas em identificadores
-- ============================================================
-- Com ON, aspas duplas delimitam identificadores (não strings)
-- Exemplo: SELECT "identity", "order" FROM "select"
SET QUOTED_IDENTIFIER ON;


-- ============================================================
-- SET ARITHABORT: Define comportamento 
-- em overflow ou divisão por zero
-- ============================================================
-- ON: encerra a consulta quando ocorre overflow ou divisão por zero
SET ARITHABORT ON


-- ============================================================
-- SET ROWCOUNT: Limita o número de linhas retornadas
-- ============================================================
-- 0 = sem limite (retorna todos os registros)
SET ROWCOUNT 0;
GO

SELECT
    *
FROM
    tabela_teste AS t1


-- ============================================================
-- SET TEXTSIZE: Limita o tamanho de dados varchar retornados
-- ============================================================
-- Define o tamanho máximo em bytes para campos de texto (-1 = ilimitado)
SET TEXTSIZE 10

SELECT
    t1.TextData
FROM
    tabela_teste AS t1


-- ============================================================
-- ANSI_PADDING: Comportamento de espaços 
-- à direita em VARCHAR e VARBINARY
-- ============================================================
-- Quando SET ANSI_PADDING = ON, espaços à direita são preservados em
-- colunas VARCHAR e VARBINARY. Quando OFF, espaços à direita são truncados.


-- ============================================================
-- ANSI_NULLS: Comportamento de comparações com NULL
-- ============================================================
-- Quando SET ANSI_NULLS é OFF, os operadores = e <> não seguem o padrão ISO.
-- Uma instrução SELECT com WHERE column_name = NULL retorna as linhas que
-- têm valores nulos em column_name.


-- ============================================================
-- SET ANSI_WARNINGS: Exibição de avisos em funções de agregação
-- ============================================================
-- ON: gera aviso quando valores nulos aparecem em funções de agregação
-- (SUM, AVG, MAX, MIN, STDEV, STDEVP, VAR, VARP, COUNT)
SET ANSI_WARNINGS ON


-- ============================================================
-- SET FORCEPLAN: Força ordem de JOINs 
-- conforme aparecem no FROM
-- ============================================================
-- ON: o otimizador de consultas processa os JOINs na mesma ordem
-- em que as tabelas aparecem na cláusula FROM
SET FORCEPLAN ON


-- ============================================================
-- SET STATISTICS XML: Gera plano de execução em formato XML
-- ============================================================
-- ON: executa as instruções e gera informações detalhadas sobre
-- a execução na forma de um documento XML
-- (SET SHOWPLAN_XML ON apenas exibe o plano sem executar a consulta)
SET STATISTICS XML ON

-- Exemplo de uso:
 SELECT
       t1.TextData
     , t1.StartTime
 FROM
     Management.TraceSlowQuery AS t1
 WHERE
     t1.StartTime >= '20171120'


SET SHOWPLAN_XML OFF

-- Exemplo de uso:
 SELECT
       t1.TextData
     , t1.StartTime
 FROM
     Management.TraceSlowQuery AS t1
 WHERE
     t1.StartTime >= '20171120'


-- ============================================================
-- SET ANSI_NULL_DFLT_ON: Permite NULL 
-- em novas colunas por padrão
-- ============================================================
-- ON: novas colunas criadas com ALTER TABLE e CREATE TABLE aceitarão
-- NULL se a nulabilidade não for especificada explicitamente
SET ANSI_NULL_DFLT_ON ON


-- ============================================================
-- SET XACT_ABORT: Define comportamento de rollback automático
-- ============================================================
-- ON: o SQL Server reverte (ROLLBACK) automaticamente a transação atual
-- quando uma instrução T-SQL gera erro em tempo de execução
SET XACT_ABORT ON

-- Cria tabelas de teste para demonstrar o comportamento do XACT_ABORT
-- t1: tabela de origem com chave primária
-- t2: tabela de destino com foreign key referenciando t1
CREATE TABLE t1 (
      a INT NOT NULL PRIMARY KEY
);

CREATE TABLE t2 (
      a INT NOT NULL REFERENCES t1(a)
);
GO

-- Insere valores válidos na tabela de origem
INSERT INTO t1 VALUES (1);
INSERT INTO t1 VALUES (3);
INSERT INTO t1 VALUES (4);
INSERT INTO t1 VALUES (6);
GO

-- Desativa XACT_ABORT para demonstrar comportamento sem rollback automático
SET XACT_ABORT OFF;
GO

-- Sem XACT_ABORT, o erro de foreign key não reverte a transação inteira.
-- Apenas a instrução que falhou é descartada; as demais são executadas.
BEGIN TRANSACTION;
INSERT INTO t2 VALUES (1);
INSERT INTO t2 VALUES (2);  -- Erro de foreign key: 2 não existe em t1
INSERT INTO t2 VALUES (3);  -- Este INSERT será executado normalmente
COMMIT TRANSACTION;
GO

-- Ativa XACT_ABORT: agora qualquer erro reverte toda a transação
SET XACT_ABORT ON;
GO

-- Com XACT_ABORT ON, o erro de foreign key reverte toda a transação.
-- Nenhum dos INSERTs será confirmado.
BEGIN TRANSACTION;
INSERT INTO t2 VALUES (4);
INSERT INTO t2 VALUES (5);  -- Erro de foreign key: 5 não existe em t1
INSERT INTO t2 VALUES (6);  -- Não será executado (transação revertida)
COMMIT TRANSACTION;
GO

-- Verifica os dados inseridos em ambas as tabelas
SELECT
    *
FROM
    dbo.t1

SELECT
    *
FROM
    dbo.t2


-- ============================================================
-- Tratamento de transações com TRY...CATCH e XACT_STATE()
-- ============================================================
-- Demonstra o uso de TRY...CATCH com controle de estado da transação
-- via XACT_STATE(): retorna -1 (incompatível, rollback necessário),
-- 1 (compatível, commit possível) ou 0 (sem transação ativa)
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
        , ERROR_MESSAGE() AS ErrMsg;

    -- Verifica se a transação está em estado incompatível (rollback obrigatório)
    IF (XACT_STATE()) = -1
    BEGIN
        PRINT 'A transação está em um estado incompatível. Retrocedendo transação.'
        ROLLBACK TRANSACTION;
    END

    -- Verifica se a transação está em estado compatível (commit possível)
    IF (XACT_STATE()) = 1
    BEGIN
        PRINT 'A transação é compatível. Transação completada.'
        COMMIT TRANSACTION;
    END
END CATCH
GO

-- OBS: A função @@ROWCOUNT é atualizada mesmo quando SET NOCOUNT é ON.
