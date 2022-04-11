------------------------------------------------------------------------------------------------------------------------------------------------------
-- CTE recursividade e/ou consultas derivadas
------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @calculos TABLE (
  codigo INT
)
INSERT INTO @calculos
  VALUES (10)

;WITH calc
AS
(
  -- conjunto 01
  SELECT
    codigo AS incrementa
  FROM @calculos

  UNION ALL

  -- conjunto 02 (onde ocorre o laço)
  SELECT
    incrementa + 1
  FROM calc
  WHERE incrementa < 1000 -- limites
)
SELECT
  *
FROM calc
OPTION (MAXRECURSION 1000)  -- limita a quantidade de "laços"


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo com incrementos de datas
------------------------------------------------------------------------------------------------------------------------------------------------------
;WITH datas
AS
(SELECT
    GETDATE() AS atual

  UNION ALL

  SELECT
    DATEADD(DAY, 1, atual)
  FROM datas
  WHERE atual <= '20180101'
)
SELECT
  atual
FROM datas
--option (maxrecursion 10)


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando listas de números aleatórios
------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo 1: Usando CTE recursiva (meu preferido!)
;WITH cte_seq
AS
(SELECT
    1 AS sequencia
   ,CHECKSUM(NEWID()) AS int_aleatorio_positivo

  UNION ALL

  SELECT
    sequencia + 1
   ,CHECKSUM(NEWID())
  FROM cte_seq
  WHERE sequencia < 1000
)
SELECT
  *
FROM cte_seq
OPTION (MAXRECURSION 0) -- option (maxrecursion 0) permite loops + de 100 itens


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo de rotina com tabela temporária e recursividade
------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE #Atendimentos (
  id_Status_Entrega INT IDENTITY PRIMARY KEY
 ,id_Aviso_Receb INT
 ,Situacao INT
 ,DataHoraRegistro DATETIME DEFAULT GETDATE()
 ,Quem_Recebeu VARCHAR(20)
)

INSERT INTO #Atendimentos (id_Aviso_Receb, Situacao, DataHoraRegistro, Quem_Recebeu)
  VALUES (52505, 0, '2014-12-29 11:36', 'julio.mallioti'),
  (52505, 1, '2014-12-29 13:05', 'julio.mallioti'),
  (52505, 2, '2014-12-29 14:05', 'julio.mallioti')

;
WITH cte
AS
(SELECT
    *
   ,ROW_NUMBER() OVER (PARTITION BY id_Aviso_Receb ORDER BY Situacao) AS rownum
  FROM #Atendimentos
),
cte2
AS
(SELECT
    *
   ,CAST(NULL AS DATETIME) Diferenca
  FROM cte
  WHERE rownum = 1 --anchor

  UNION ALL

  SELECT
    cte.*
   ,CAST((cte.DataHoraRegistro - cte2.DataHoraRegistro) AS DATETIME) Diferenca
  FROM cte
  JOIN cte2
    ON cte.rownum = cte2.rownum + 1
    AND cte.id_Aviso_Receb = cte2.id_Aviso_Receb
 )

SELECT
  *
 ,CAST(diferenca AS TIME) Diferenca_Time
FROM cte2
ORDER BY id_Aviso_Receb, Situacao

DROP TABLE #Atendimentos


------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo prático - union all
------------------------------------------------------------------------------------------------------------------------------------------------------
;WITH myCTE
AS
(SELECT
    DB_NAME(database_id) AS TheDatabase
   ,last_user_seek
   ,last_user_scan
   ,last_user_lookup
   ,last_user_update
  FROM sys.dm_db_index_usage_stats
)
SELECT
  ServerRestartedDate = (SELECT
      CREATE_DATE
    FROM sys.databases
    WHERE name = 'tempdb')
 ,x.TheDatabase
 ,MAX(x.last_read) AS last_read
 ,MAX(x.last_write) AS last_write
FROM (SELECT
      TheDatabase
     ,last_user_seek AS last_read
     ,NULL AS last_write
    FROM myCTE
  
    UNION ALL
  
    SELECT
      TheDatabase
     ,last_user_scan
     ,NULL
    FROM myCTE
  
    UNION ALL
  
    SELECT
      TheDatabase
     ,last_user_lookup
     ,NULL
    FROM myCTE
  
    UNION ALL
  
    SELECT
      TheDatabase
     ,NULL
     ,last_user_update
    FROM myCTE
  ) AS x

GROUP BY TheDatabase
ORDER BY TheDatabase