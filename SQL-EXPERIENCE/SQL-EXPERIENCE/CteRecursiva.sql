/*
	OBJETIVO: Demonstrar o uso de CTE recursiva para calcular a diferença de
			  tempo entre registros consecutivos de uma mesma ocorrência
			  (id_Aviso_Receb), ordenados pela situação, utilizando a função
			  ROW_NUMBER para criar uma sequência numérica.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Criação da tabela temporária #Atendimentos
-- ============================================================
CREATE TABLE #Atendimentos
(
      id_Status_Entrega   INT IDENTITY PRIMARY KEY
    , id_Aviso_Receb      INT
    , Situacao            INT
    , DataHoraRegistro    DATETIME DEFAULT GETDATE()
    , Quem_Recebeu        VARCHAR(20)
);

-- ============================================================
-- Inserção dos dados de exemplo
-- ============================================================
INSERT INTO #Atendimentos
(
      id_Aviso_Receb
    , Situacao
    , DataHoraRegistro
    , Quem_Recebeu
)
VALUES
      (52505, 0, '2014-12-29 11:36', 'julio.mallioti')
    , (52505, 1, '2014-12-29 13:05', 'julio.mallioti')
    , (52505, 2, '2014-12-29 14:05', 'julio.mallioti');

-- ============================================================
-- CTE recursiva para calcular a diferença de tempo entre
-- registros consecutivos da mesma ocorrência
-- ============================================================
WITH cte
AS
(
    SELECT
          *
        , ROW_NUMBER() OVER (PARTITION BY id_Aviso_Receb ORDER BY Situacao) AS rownum
    FROM #Atendimentos
)
, cte2
AS
(
    -- Âncora: primeiro registro de cada ocorrência
    SELECT
          *
        , CAST(NULL AS DATETIME)                                                AS Diferenca
    FROM cte
    WHERE rownum = 1

    UNION ALL

    -- Parte recursiva: calcula a diferença entre o registro atual e o anterior
    SELECT
          cte.*
        , CAST((cte.DataHoraRegistro - cte2.DataHoraRegistro) AS DATETIME)      AS Diferenca
    FROM cte
    INNER JOIN cte2
            ON cte.rownum = cte2.rownum + 1
               AND cte.id_Aviso_Receb = cte2.id_Aviso_Receb
)

-- ============================================================
-- Consulta final com a diferença formatada como TIME
-- ============================================================
SELECT
      *
    , CAST(Diferenca AS TIME)                                                   AS Diferenca_Time
FROM cte2
ORDER BY
      id_Aviso_Receb
    , Situacao;

-- ============================================================
-- Limpeza da tabela temporária
-- ============================================================
DROP TABLE #Atendimentos;
