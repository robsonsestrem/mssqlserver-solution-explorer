DECLARE @Tabela1 TABLE (
  Codigo INT
 ,Valor INT
)

DECLARE @Tabela2 TABLE (
  Codigo INT
 ,Valor INT
)

INSERT INTO @Tabela1
  VALUES (1, 1), (2, 2), (NULL, NULL)
INSERT INTO @Tabela2
  VALUES (1, 1), (2, 2), (3, 3), (4, 4), (5, 5), (NULL, NULL)

-- Utilizando Union All --
SELECT
  *
FROM @Tabela1
UNION ALL
SELECT
  *
FROM @Tabela2

-- Utilizando operador Outer Apply --
SELECT
  T.Codigo
 ,T.Valor
FROM @Tabela1 T
OUTER APPLY (SELECT
    Codigo
  FROM @Tabela2
  WHERE Codigo = T.Codigo) AS T2

-- Utilizando operador Cross Apply --
SELECT
  T.Codigo
 ,T.Valor
FROM @Tabela1 T
CROSS APPLY (SELECT
    Codigo
  FROM @Tabela2
  WHERE Codigo = T.Codigo) AS T2
						   
						   
