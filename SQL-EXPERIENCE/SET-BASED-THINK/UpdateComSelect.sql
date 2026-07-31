/*
 *
	OBJETIVO: Demonstração de atualização em massa utilizando UPDATE com FROM e subconsulta,
			  substituindo abordagem com cursor para condicionar a classe dos funcionários
			  com base na faixa salarial definida na tabela Classes.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS: Curso da Proway
 *	
 */
-- ============================================================
-- Substitui um cursor - O script condiciona 
-- classes ao novo campo adicionado (Classe) na tabela 
-- funcionários - alteração pega de
-- uma tabela e condicionada a outra
-- ============================================================

-- ============================================================
-- Estrutura das tabelas utilizadas no exemplo
-- ============================================================
-- CREATE TABLE [dbo].[Funcionarios](
--     [Id] [int] NOT NULL,
--     [Nome] [nvarchar](max) NOT NULL,
--     [Salario] [money] NOT NULL,
--     [Classe] [int] NOT NULL
-- ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

-- CREATE TABLE [dbo].[Classes](
--     [Id] [int] NOT NULL,
--     [Minimo] [money] NOT NULL,
--     [Maximo] [money] NOT NULL,
--     [Descricao] [nvarchar](max) NOT NULL
-- ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

-- ============================================================
-- Dados de exemplo para testes
-- ============================================================
-- INSERT INTO Classes VALUES(1, 600, 700, 'H')
-- INSERT INTO Classes VALUES(2, 750, 900, 'G')
-- INSERT INTO Classes VALUES(3, 950, 1100, 'F')
-- INSERT INTO Classes VALUES(4, 1200, 1300, 'D')
-- INSERT INTO Classes VALUES(5, 1400, 1500, 'C')
-- INSERT INTO Classes VALUES(6, 1600, 1700, 'B')
-- INSERT INTO Classes VALUES(7, 1800, 2500, 'A')

-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(1, 'Chunda', 1000)
-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(2, 'Censi', 1200)
-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(3, 'Bituca', 1300)
-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(4, 'Cabelo', 1400)
-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(5, 'Voltrurdes', 1600)
-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(6, 'Aristica', 1800)
-- INSERT INTO Funcionarios (Id, Nome, Salario) VALUES(7, 'Zelda', 1900)

-- ============================================================
-- UPDATE com FROM e subconsulta para 
-- definir a classe do funcionário
-- ============================================================
UPDATE Funcionarios
SET Classe = deriva.class
FROM
(
    SELECT
        c.id AS class,
        e.id AS func
    FROM Funcionarios AS e
    INNER JOIN Classes AS c
        ON e.Salario BETWEEN c.minimo AND c.maximo
) AS deriva
WHERE deriva.func = Funcionarios.id
GO
