-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplos para remover ou apenas encontrar - Registros Duplicados
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Com CTE */
CREATE TABLE #prod (
  Product_Code VARCHAR(10)
 ,Product_Name VARCHAR(100)
)

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('123', 'Product_1')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('234', 'Product_2')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('345', 'Product_3')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('345', 'Product_3')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('456', 'Product_4')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('567', 'Product_5')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('678', 'Product_6')

INSERT INTO #prod (Product_Code, Product_Name)
  VALUES ('789', 'Product_7')

SELECT
  *
FROM #prod;

WITH Dups
AS
(SELECT
    *
   ,ROW_NUMBER() OVER (PARTITION BY Product_Code ORDER BY Product_Code) AS RowNum
  FROM #prod)

DELETE FROM Dups
WHERE rownum > 1;

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Outras formas otimizadas de se fazer isso, imaginando que a massa de dados esteja numa tabela de nome "[Table_Having _Duplicates]"
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/* Primeiro, vá apenas para os registros que estão recebendo duplicatas e insira somentes esses numa tabela temporária */
SELECT DISTINCT C1
INTO #OnlyUniqueFromDuplicates
FROM [Table_Having _Duplicates]
GROUP BY C1
HAVING COUNT(C1) > 1;

/* Exclua apenas os registros duplicados da tabela [Table Having Duplicates] */
DELETE FROM [Table_Having _Duplicates]
WHERE EXISTS (SELECT
               C1
              FROM #OnlyUniqueFromDuplicates AS I
              WHERE I.C1 = [Table_Having _Duplicates].C1
             );

/* Agora insira os registros exclusivos da tabela temporária #OnlyUniqueFromDuplicates para a tabela [Table Having Duplicates] */
INSERT INTO [Table_Having _Duplicates] (C1)
SELECT C1
FROM #OnlyUniqueFromDuplicates







