-------------------------------------------------------------------------
-- Exemplo simples
-------------------------------------------------------------------------
CREATE SEQUENCE dbo.demoSequence
AS INT
START WITH 1
INCREMENT BY 1;
GO
CREATE TABLE dbo.tblDemo (
  SeqCol INT PRIMARY KEY
 ,ItemName NVARCHAR(25) NOT NULL
);
GO

INSERT INTO dbo.tblDemo (SeqCol, ItemName)
  VALUES (NEXT VALUE FOR dbo.demoSequence, 'Item');
GO

SELECT
  *
FROM tblDemo

-- cada vez que chama ele, faz um incremento
SELECT NEXT VALUE FOR dbo.demoSequence

-- altera para o valor inicial
ALTER SEQUENCE dbo.demoSequence RESTART WITH 1


-------------------------------------------------------------------------
-- mostrar valor anterior
-------------------------------------------------------------------------
CREATE SEQUENCE Seq AS INT	-- Tipo
START WITH 1				-- Valor Inicial (1)
INCREMENT BY 1				-- Avança de um em um
MINVALUE 1					-- Valor mínimo 1
MAXVALUE 1000				-- Valor máximo 10000
CACHE 10					-- Mantém 10 posições em cache
NO CYCLE					-- Não irá reciclar

DECLARE @Tabela TABLE (
  data DATE
 ,Valor DECIMAL(18, 2)
)

INSERT INTO @Tabela (data, Valor)

  SELECT
    GETDATE() - 1
   ,100
  UNION ALL
  SELECT
    GETDATE() - 2
   ,200
  UNION ALL
  SELECT
    GETDATE() - 3
   ,200
  UNION ALL
  SELECT
    GETDATE() - 4
   ,300
  UNION ALL
  SELECT
    GETDATE() - 5
   ,400
  UNION ALL
  SELECT
    GETDATE() - 6
   ,500
  UNION ALL
  SELECT
    GETDATE() - 7
   ,600
  UNION ALL
  SELECT
    GETDATE() - 8
   ,700
  UNION ALL
  SELECT
    GETDATE() - 9
   ,800

SELECT
  NEXT VALUE FOR Seq OVER (ORDER BY Data) Ordem
 ,T1.data
 ,T1.Valor
 ,ISNULL(Anterior.Valor, 0) AS [Valor Anterior]
FROM @Tabela T1
OUTER APPLY (SELECT TOP 1
    T.Valor
  FROM @Tabela AS T
  WHERE T.data < T1.data) Anterior
GO