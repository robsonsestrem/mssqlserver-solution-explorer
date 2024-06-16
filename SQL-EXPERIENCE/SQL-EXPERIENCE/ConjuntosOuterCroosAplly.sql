Declare @Tabela1 Table
 (Codigo Int,
  Valor Int)

Declare @Tabela2 Table
 (Codigo Int,
  Valor Int)

Insert Into @Tabela1 Values (1,1),(2,2),(Null, Null)
Insert Into @Tabela2 Values (1,1),(2,2),(3,3),(4,4),(5,5), (Null, Null)

-- Utilizando Union All --
Select * From @Tabela1
Union all
Select * From @Tabela2

-- Utilizando operador Outer Apply --
Select T.Codigo,
       T.Valor
From @Tabela1 T Outer Apply (Select Codigo From @Tabela2
                           Where Codigo = T.Codigo) As T2

-- Utilizando operador Cross Apply --
Select T.Codigo,
       T.Valor
From @Tabela1 T Cross Apply (Select Codigo From @Tabela2
                           Where Codigo = T.Codigo) As T2
