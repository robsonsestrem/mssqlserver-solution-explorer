/*
    OBJETIVO: Ranquear operações de estoque (OP) por volume diário, calculando percentual
              acumulado sobre o total geral através de funções de janela (DENSE_RANK e LAST_VALUE)
              para análise de cooperativas e identificação das operações mais representativas.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- SEÇÃO 1: Consulta ranqueada de operações de estoque
-- ============================================================

-- Seleção final com ranking e percentual acumulado das operações por dia
SELECT 
    y.DataEmissao
    , y.OP
    , y.NomeOP
    , y.TotalPorDia
    , DENSE_RANK() OVER (ORDER BY y.TotalPorDia DESC) AS [Rank]
    , CAST(
        100. * y.TotalPorDia / LAST_VALUE(y.Somatoria) OVER (
            ORDER BY y.Somatoria
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS DECIMAL(18, 2)
    ) AS Percentual
FROM (
    -- Agregação diária por operação com soma acumulada ordenada por volume
    SELECT 
        x.DataEmissao
        , COUNT(x.DataEmissao) AS TotalPorDia
        , x.OP
        , x.NomeOP
        , SUM(COUNT(x.DataEmissao)) OVER (
            ORDER BY COUNT(x.DataEmissao)
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Somatoria
    FROM (
        -- Extração da base de movimentação de estoque com filtro de data
        SELECT 
            -- t1.NfFilCod AS Filial
            CAST(t1.NfDatEmis AS DATE) AS DataEmissao
            , t1.NfOpeEstCod AS OP
            , t2.OpeEstNom AS NomeOP
        FROM MOVESTOQUE AS t1 WITH (NOLOCK)
        INNER JOIN OPERACAO AS t2
            ON t1.NfOpeEstCod = t2.OpeEstCod
        WHERE t1.NfDatEmis >= '20181003'
            -- AND t1.NfeCStat NOT IN (101, 102)
            -- AND t1.NfSituacao NOT IN (1, 4)
    ) AS x
    GROUP BY 
        x.DataEmissao,
        x.OP,
        x.NomeOP
) AS y
ORDER BY y.TotalPorDia DESC;

-- ============================================================
-- SEÇÃO 2: Consulta de teste (contador de documentos)
-- ============================================================

-- Contagem de documentos para validação de filtros específicos
-- SELECT COUNT(t1.NfNumDoc)
-- FROM MOVESTOQUE AS t1
-- WHERE t1.NfOpeEstCod = 5
--     AND t1.NfeCStat NOT IN (101, 102)
--     AND t1.NfSituacao NOT IN (1, 4)
--     AND t1.NfDatEmis = '20181003';
