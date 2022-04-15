-------------------------------------------------------------------------------------------------------
-- Criando a Table Tabela1
-------------------------------------------------------------------------------------------------------
CREATE TABLE Tabela1 (
  Codigo SMALLINT IDENTITY PRIMARY KEY CLUSTERED
 ,Valor INT
 ,DataCriacao DATE
 ,DataManipulacao DATE
) ON [Primary]


-------------------------------------------------------------------------------------------------------
-- Inserindo Dados na Tabela1 e Retornando os valores para cla�sula Output
-------------------------------------------------------------------------------------------------------
INSERT INTO Tabela1 (Valor, DataCriacao, DataManipulacao)
OUTPUT INSERTED.Codigo, INSERTED.Valor, INSERTED.DataCriacao, INSERTED.DataManipulacao
  VALUES (10, GETDATE(), GETDATE() + 1), (20, GETDATE(), GETDATE() + 2),
  (30, GETDATE(), GETDATE() + 3), (40, GETDATE(), GETDATE() + 4)
GO


-------------------------------------------------------------------------------------------------------
-- Atualizando dados na Tabela1 e Retornando os valores para cla�sula Output
-------------------------------------------------------------------------------------------------------
UPDATE Tabela1
SET DataManipulacao = GETDATE() + 1
OUTPUT INSERTED.DataManipulacao AS [Data de Manipula��o Atualizada],
DELETED.DataManipulacao AS [Data de Manipula��o Antiga]
WHERE Codigo = 1
GO


-------------------------------------------------------------------------------------------------------
-- Exclu�ndo dados na Tabela1 e Retornando os valores para cla�sula Output
-------------------------------------------------------------------------------------------------------
DELETE FROM Tabela1
OUTPUT DELETED.*
WHERE Codigo IN (2, 4)
GO

