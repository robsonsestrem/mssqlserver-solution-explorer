----------------------------------------------------------------------------------------------------------
-- Substitui um cursor - O script condiciona classes ao novo campo 
-- adicionado (Classe) na tabela funcionários - alteração pega de uma tabela e condicionada a outra
----------------------------------------------------------------------------------------------------------


update Funcionarios set Classe = deriva.class
from (
		select  c.id as class, e.id as func 
		from Funcionarios as e, Classes as c
		where e.Salario between c.minimo and c.maximo
	  ) deriva
where deriva.func = Funcionarios.id	



--insert into Classes values(1, 600, 700, 'H')
--insert into Classes values(2, 750, 900, 'G')
--insert into Classes values(3, 950, 1100, 'F')
--insert into Classes values(4, 1200, 1300, 'D')
--insert into Classes values(5, 1400, 1500, 'C')
--insert into Classes values(6, 1600, 1700, 'B')
--insert into Classes values(7, 1800, 2500, 'A')

--insert into Funcionarios (Id, Nome, Salario) values(1, 'Chunda', 1000)
--insert into Funcionarios (Id, Nome, Salario) values(2, 'Censi', 1200)
--insert into Funcionarios (Id, Nome, Salario) values(3, 'Bituca', 1300)
--insert into Funcionarios (Id, Nome, Salario) values(4, 'Cabelo', 1400)
--insert into Funcionarios (Id, Nome, Salario) values(5, 'Voltrurdes', 1600)
--insert into Funcionarios (Id, Nome, Salario) values(6, 'Aristica', 1800)
--insert into Funcionarios (Id, Nome, Salario) values(7, 'Zelda', 1900)


--CREATE TABLE [dbo].[Funcionarios](
--	[Id] [int] NOT NULL,
--	[Nome] [nvarchar](max) NOT NULL,
--	[Salario] [money] NOT NULL,
--	[Classe] [int] NOT NULL
--) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]


--CREATE TABLE [dbo].[Classes](
--	[Id] [int] NOT NULL,
--	[Minimo] [money] NOT NULL,
--	[Maximo] [money] NOT NULL,
--	[Descricao] [nvarchar](max) NOT NULL
--) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
