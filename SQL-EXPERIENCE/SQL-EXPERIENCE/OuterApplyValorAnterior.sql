Declare @Tabela TABLE
 (data Date,
 Valor Decimal(18,2)
)

Insert Into @Tabela (data,Valor)

Select  GETDATE()-1,100
Union All
Select  GETDATE()-2,200
Union All
Select  GETDATE()-3,200
Union All
Select  GETDATE()-4,300
Union All
Select  GETDATE()-5,400
Union All
Select  GETDATE()-6,500
Union All
Select  GETDATE()-7,600
Union All
Select  GETDATE()-8,700
Union All
Select  GETDATE()-9,800

Select Ordem = Row_Number() Over (Order By Data),
       T1.data,
       T1.Valor,
       ISNULL(Anterior.Valor,0) As 'Valor Anterior'
FROM @Tabela T1 OUTER APPLY 
             (Select TOP 1 T.Valor 
			  FROM @Tabela AS T
		      WHERE T.data < T1.data) Anterior
ORDER BY T1.data
Go

-- Exemplo com Sequence --
-- Criando uma nova Sequência de Valores --
CREATE SEQUENCE Seq As INT -- Tipo
 START WITH 1 -- Valor Inicial (1)
 INCREMENT BY 1 -- Avança de um em um
 MINVALUE 1 -- Valor mínimo 1
 MAXVALUE 1000 -- Valor máximo 10000
 CACHE 10 -- Mantém 10 posições em cache
 NO CYCLE -- Não irá reciclar

Declare @Tabela TABLE
 (data Date,
 Valor Decimal(18,2)
)

Insert Into @Tabela (data,Valor)

Select  GETDATE()-1,100
Union All
Select  GETDATE()-2,200
Union All
Select  GETDATE()-3,200
Union All
Select  GETDATE()-4,300
Union All
Select  GETDATE()-5,400
Union All
Select  GETDATE()-6,500
Union All
Select  GETDATE()-7,600
Union All
Select  GETDATE()-8,700
Union All
Select  GETDATE()-9,800

Select Next Value For Seq Over (Order By Data) Ordem,
       T1.data,
       T1.Valor,
       ISNULL(Anterior.Valor,0) As 'Valor Anterior'
FROM @Tabela T1 OUTER APPLY 
             (Select TOP 1 T.Valor 
			  FROM @Tabela AS T
		      WHERE T.data < T1.data) Anterior
Go
