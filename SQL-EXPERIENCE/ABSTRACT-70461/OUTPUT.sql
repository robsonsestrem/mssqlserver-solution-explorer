/*
 *
	OBJETIVO: Demonstração do uso da cláusula OUTPUT no SQL Server para capturar
			  e retornar dados inseridos, atualizados ou excluídos durante operações
			  DML (INSERT, UPDATE, DELETE), permitindo auditoria e validação
			  imediata das alterações realizadas.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *	
 */
-- ============================================================
-- Criando a tabela Tabela1
-- ============================================================
CREATE TABLE Tabela1
(
    Codigo SMALLINT IDENTITY PRIMARY KEY CLUSTERED,
    Valor INT,
    DataCriacao DATE,
    DataManipulacao DATE
) ON [PRIMARY]
GO

-- ============================================================
-- Inserindo dados na Tabela1 e retornando os valores com OUTPUT
-- ============================================================
INSERT INTO Tabela1
(
    Valor,
    DataCriacao,
    DataManipulacao
)
OUTPUT
    INSERTED.Codigo,
    INSERTED.Valor,
    INSERTED.DataCriacao,
    INSERTED.DataManipulacao
VALUES
    (10, GETDATE(), GETDATE() + 1),
    (20, GETDATE(), GETDATE() + 2),
    (30, GETDATE(), GETDATE() + 3),
    (40, GETDATE(), GETDATE() + 4)
GO

-- ============================================================
-- Atualizando dados na Tabela1 e retornando os valores com OUTPUT
-- ============================================================
UPDATE Tabela1
SET DataManipulacao = GETDATE() + 1
OUTPUT
    INSERTED.DataManipulacao AS [Data de Manipulação Atualizada],
    DELETED.DataManipulacao AS [Data de Manipulação Antiga]
WHERE Codigo = 1
GO

-- ============================================================
-- Excluindo dados na Tabela1 e retornando os valores com OUTPUT
-- ============================================================
DELETE FROM Tabela1
OUTPUT DELETED.*
WHERE Codigo IN (2, 4)
GO
