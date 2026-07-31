/*
 *
	OBJETIVO: Verificação de gaps (lacunas) de datas em integração de dados CMV,
			  identificando intervalos de dias ausentes em Bi.HistoricoCMV para
			  um mês/ano específico, utilizando subconsultas correlacionadas e
			  NOT EXISTS para detecção de discontinuidades temporais.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/t-sql/queries/select-transact-sql
 */
-- ============================================================
-- Verificação de Gaps de Datas em Integração CMV
-- ============================================================

USE IntegraTICravil
GO

-- Declaração de variáveis de filtro temporal (mês e ano de referência)
DECLARE @mes INT = 04
       ,@ano INT = 2017

-- ============================================================
-- SEÇÃO 1: DETECÇÃO DE GAPS
-- Identifica intervalos de dias ausentes no histórico CMV
-- ============================================================

-- Consulta principal: retorna o dia de início e término de cada gap encontrado
-- Utiliza subconsulta correlacionada para encontrar o próximo dia existente
SELECT
    DAY(t1.DataEmissao) + 1 AS Inicio
    ,(
        -- Subconsulta correlacionada: busca o menor dia subsequente existente
        SELECT MIN(DAY(t2.DataEmissao))
        FROM Bi.HistoricoCMV AS t2
        WHERE DAY(t2.DataEmissao) > DAY(t1.DataEmissao)
            AND MONTH(t2.DataEmissao) = @mes
            AND YEAR(t2.DataEmissao) = @ano
    ) - 1 AS Termino
FROM Bi.HistoricoCMV AS t1
WHERE NOT EXISTS
(
    -- Verifica se o dia seguinte não existe no histórico (condição de gap)
    SELECT *
    FROM Bi.HistoricoCMV AS t2
    WHERE DAY(t2.DataEmissao) = DAY(t1.DataEmissao) + 1
        AND MONTH(t2.DataEmissao) = @mes
        AND YEAR(t2.DataEmissao) = @ano
)
AND DAY(t1.DataEmissao) <
(
    -- Limita a busca para não considerar o último dia do mês como gap
    SELECT MAX(DAY(t1.DataEmissao))
    FROM Bi.HistoricoCMV AS t1
    WHERE MONTH(t1.DataEmissao) = @mes
        AND YEAR(t1.DataEmissao) = @ano
)
AND MONTH(t1.DataEmissao) = @mes
AND YEAR(t1.DataEmissao) = @ano

-- ============================================================
-- SEÇÃO 2: VALIDAÇÃO PONTO-A-PONTO
-- Consulta registros em data específica para conferência manual
-- ============================================================

-- Consulta de validação para inspecionar registros em data crítica
SELECT *
FROM Bi.HistoricoCMV AS c
WHERE c.DataEmissao >= '20170416 00:00:00.000'
    AND c.DataEmissao <= '20170416 23:59:59.997'
