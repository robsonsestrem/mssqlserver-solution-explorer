/*
    OBJETIVO: Demonstrar paginação de resultados utilizando OFFSET/FETCH com CTE e ROW_NUMBER
              para controle de duplicatas e ordenação em consultas de movimentação de estoque.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- SEÇÃO 1: Declaração de variáveis de período
-- ============================================================

-- Declaração das variáveis para definir o intervalo de datas da consulta
DECLARE @dataInicio DATETIME;
DECLARE @dataFim DATETIME;

SET @dataInicio = '20170301';
SET @dataFim = '20171231';

-- ============================================================
-- SEÇÃO 2: CTE para preparação dos dados com ROW_NUMBER
-- ============================================================

-- CTE que prepara os dados de movimentação de estoque, identificando duplicatas
-- através de ROW_NUMBER particionado por número de NF e data de emissão
WITH cte AS (
    SELECT 
        m.NfNumDoc AS [NF-e]
        , m.NfDatEmis AS [Data Emissão]
        , CASE 
              WHEN m.NfeChNfe = '' THEN ''
              ELSE ISNULL(m.NfeChNfe, '')
          END AS [Chave]
        , m.NfOpeEstCod AS [Operação]
        , op.OpeEstNom AS [Nome Operação]
        , ROW_NUMBER() OVER (
            PARTITION BY m.nfnumdoc 
            ORDER BY m.nfnumdoc
        ) AS rn
    FROM MOVESTOQUE AS m WITH (NOLOCK)
    INNER JOIN MOVESTOQUELEVEL1 AS i WITH (NOLOCK)
        ON m.NfFilCod = i.NfFilCod
        AND m.NfDatEmis = i.NfDatEmis
        AND m.NfNumero = i.NfNumero
    INNER JOIN TRANSACIONADORES AS t WITH (NOLOCK)
        ON t.TraCod = m.NfForCod
    LEFT JOIN MUNICIPIOS AS city WITH (NOLOCK)
        ON city.muncod = t.tramuncod
        AND city.estcod = t.traestcod
        AND city.paicod = t.trapaicod
    INNER JOIN OPERACAO AS op
        ON op.OpeEstCod = m.NfOpeEstCod
    INNER JOIN PRODUTOS AS p
        ON p.ProCod = i.ItemProCod
    WHERE m.NfOpeEstCod IN (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204, 5, 236)
        AND m.nfecstat NOT IN (101, 102)
        AND m.NfSituacao NOT IN (1, 4)
        AND i.NfDatEmis BETWEEN @dataInicio AND @dataFim
        AND i.ItemProCod IN (42312, 39580, 39621, 42311)
)
-- ============================================================
-- SEÇÃO 3: Consulta final com paginação OFFSET/FETCH
-- ============================================================

-- Seleção dos dados paginados, filtrando duplicatas (rn < 2) e aplicando paginação
SELECT 
    CONVERT(VARCHAR(30), t2.[Data Emissão], 103) AS [Data]
    , t2.[NF-e]
    , t2.Operação
    , t2.[Nome Operação]
    , ROW_NUMBER() OVER (
        ORDER BY t2.[Data Emissão]
    ) AS Contagem
    , '' AS [Status]
FROM cte AS t2
WHERE t2.rn < 2
ORDER BY t2.[Data Emissão]
OFFSET 300 ROWS
FETCH NEXT 100 ROWS ONLY;
