/*
    OBJETIVO: Simulação de deadlock no SQL Server utilizando tabelas temporárias
              globais (##Empregados e ##Departamentos), com dois UPDATEs
              cruzados entre sessões distintas para forçar deadlock circular,
              seguido de limpeza (DROP + ROLLBACK) e verificação de @@TRANCOUNT.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Bloco 1: Criação das tabelas temporárias globais
-- ============================================================

-- Primeiro vamos criar as tabelas
CREATE TABLE ##Empregados
(
    cod_Empregado INT IDENTITY
    , nom_Empregado VARCHAR(16)
    , des_Cargo VARCHAR(16)
);
GO

CREATE TABLE ##Departamentos
(
    cod_Departamento INT IDENTITY
    , des_Departamento VARCHAR(64)
    , des_Unidade VARCHAR(16)
);
GO

-- ============================================================
-- Bloco 2: Inserção de dados de teste
-- ============================================================
INSERT INTO [##Departamentos] (des_Departamento, des_Unidade)
VALUES
    ('Desenvolvimento', 'São Paulo/SP')
    , ('Banco de Dados', 'São Paulo/SP')
;
GO

INSERT INTO [##Empregados] (nom_Empregado, des_Cargo)
VALUES
    ('Fausto', 'DBA')
    , ('Maria', 'Desenvolvedor');
GO

-- ============================================================
-- Bloco 3: Simulação de deadlock entre duas sessões
-- ============================================================

-- Agora muita atenção na ordem dos passos, vamos utilizar duas sessões
-- no mesmo banco, sessão 1 e sessão 2.

-- Passo 1: Sessão 01
-- Abre transação e atualiza a tabela ##Empregados (lock exclusivo na linha 1)
BEGIN TRAN;

UPDATE ##Empregados
SET
    nom_Empregado = 'Fausto.Branco'
WHERE cod_Empregado = 1;

-- Passo 2: Sessão 02
-- Abre transação e atualiza a tabela ##Departamentos (lock exclusivo na linha 1)
BEGIN TRAN;

UPDATE ##Departamentos
SET
    des_Unidade = N'Av. Paulista/SP'
WHERE cod_Departamento = 1;

-- Passo 3: Na sessão 1 (ela vai ficar bloqueada)
-- Tenta atualizar ##Departamentos, que está com lock exclusivo da sessão 2
UPDATE ##Departamentos
SET
    des_Unidade = N'Av. Paulista'
WHERE cod_Departamento = 1;

-- Passo 4: Na sessão 2 (aqui vai ocorrer o deadlock em segundos)
-- Tenta atualizar ##Empregados, que está com lock exclusivo da sessão 1
-- O ciclo de dependência circular força o SQL Server a escolher uma vítima
UPDATE ##Empregados
SET
    des_Cargo = 'DBA/SR'
WHERE cod_Empregado = 1;

-- Provavelmente na Sessão 1 o resultado agora foi:
-- Msg 1205, Level 13, State 45, Line 21
-- Transaction (Process ID 53) was deadlocked on lock resources with another
-- process and has been chosen as the deadlock victim. Rerun the transaction.

-- ============================================================
-- Bloco 4: Limpeza e verificação
-- ============================================================

-- Feito isso pode executar Rollback Transaction nas duas sessões
-- e drop nas tabelas temporárias
DROP TABLE ##Empregados
;
DROP TABLE ##Departamentos
;
ROLLBACK TRANSACTION
;
ROLLBACK TRANSACTION
;
SELECT
    @@TRANCOUNT
;
