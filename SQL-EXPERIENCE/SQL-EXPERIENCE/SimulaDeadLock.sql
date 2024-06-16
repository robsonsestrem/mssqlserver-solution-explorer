---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Vamos primeiro simular um deadlock utilizando uma tabela temporário e em seguida mostrar como se extrai os dados e o gráfico do deadlock.
--Primeiro vamos criar as tabelas:
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE ##Empregados (
    cod_Empregado INT IDENTITY,
    nom_Empregado VARCHAR(16),
    des_Cargo     VARCHAR(16)
)
GO

CREATE TABLE ##Departamentos(
    cod_Departamento INT IDENTITY,
    des_Departamento VARCHAR(64),
    des_Unidade      VARCHAR(16)
)
GO

INSERT INTO [##Departamentos] (des_Departamento, des_Unidade)
VALUES 
('Desenvolvimento', 'São Paulo/SP'), 
('Banco de Dados', 'São Paulo/SP')
GO

INSERT INTO [##Empregados] (nom_Empregado, des_Cargo)
VALUES 
('Fausto', 'DBA'), 
('Maria', 'Desenvolvedor')
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Agora muita atenção na ordem dos passos, vamos utilizar duas sessões no mesmo banco, sessão 1 e sessão 2.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 2)	sessão 01
BEGIN TRAN;   

UPDATE ##Empregados
  SET
      nom_Empregado = 'Fausto.Branco'
 WHERE cod_Empregado = 1;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2)	sessão 02
BEGIN TRAN;

UPDATE ##Departamentos
  SET
      des_Unidade = N'Av. Paulista/SP'
 WHERE cod_Departamento = 1;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3)	Na sessão 1 (Ela vai ficar bloqueada):
UPDATE ##Departamentos
  SET
      des_Unidade = N'Av. Paulista'
 WHERE cod_Departamento = 1;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4)	Na sessão 2 (Aqui vai ocorrer o Deadlock em segundos):
UPDATE ##Empregados
  SET
      des_Cargo = 'DBA/SR'
 WHERE cod_Empregado = 1;

-- Provavelmente na Sessão 1 o resultado agora foi:
--Msg 1205, Level 13, State 45, Line 21
--Transaction (Process ID 53) was deadlocked on lock resources with another process and has been chosen as the deadlock victim. Rerun the transaction.


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--Feito isso pode executar Rollback Transaction nas duas sessões e drop nas tabelas temporárias.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
drop table ##Empregados
drop table ##Departamentos
ROLLBACK TRANSACTION
ROLLBACK TRANSACTION

SELECT @@TRANCOUNT