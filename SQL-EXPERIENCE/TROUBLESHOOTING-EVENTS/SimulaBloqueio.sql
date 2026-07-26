/*
	OBJETIVO: Simular uma condição de bloqueio (lock) no SQL Server utilizando
			  duas sessões concorrentes realizando atualizações sem WHERE,
			  demonstrando o comportamento de espera por locks.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- ATENÇÃO: Ordem dos passos é crítica.
-- Utilizar duas sessões no mesmo banco (Sessão 1 e Sessão 2).
-- ============================================================

-- ============================================================
-- Passo 1: Criação da tabela de teste (executar uma única vez)
-- ============================================================
CREATE TABLE tb_TesteLock
(
      id          INT
    , produto     VARCHAR(255)
    , imobiliaria INT
    , faixa_preco INT
    , observacao  VARCHAR(MAX)
);

-- ============================================================
-- Passo 2: Inserção de registro de teste
-- ============================================================
INSERT INTO tb_TesteLock
(
      id
    , produto
    , imobiliaria
    , faixa_preco
    , observacao
)
VALUES
(
      1
    , 'a'
    , 1
    , 1
    , 'b'
);

-- ============================================================
-- Passo 3: Sessão 01 - Iniciar transação e atualizar sem filtro
-- ============================================================
BEGIN TRANSACTION;

UPDATE tb_TesteLock
SET observacao = 'C';

-- ============================================================
-- Passo 4: Sessão 02 - Iniciar transação e tentar atualizar
-- Após aproximadamente 10 segundos, a sessão entrará em estado
-- de espera (suspended) devido ao bloqueio da Sessão 01.
-- ============================================================
BEGIN TRANSACTION;

UPDATE tb_TesteLock
SET observacao = 'D';

-- ============================================================
-- Para finalizar os testes, executar COMMIT ou ROLLBACK
-- nas sessões conforme necessário.
-- ============================================================
