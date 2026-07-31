/*
 *
	OBJETIVO: Desenho estético de pinheiro de natal via T-SQL, utilizando
			  window function MAX() OVER() para calcular a altura máxima
			  do conjunto e REPLICATE para gerar padrões visuais por linha,
			  demonstrando uso criativo de funções analíticas em contextos
			  não convencionais.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/t-sql/queries/select-over-clause-transact-sql
 */
-- ============================================================
-- Pinheiro de Natal via Window Function e REPLICATE
-- ============================================================

-- Declaração da table variable com as linhas do pinheiro
DECLARE @image AS TABLE
(
    row_id TINYINT
)

-- População da table variable com 9 linhas (altura do pinheiro)
INSERT INTO @image
(
    row_id
)
VALUES
    (1)
    ,(2)
    ,(3)
    ,(4)
    ,(5)
    ,(6)
    ,(7)
    ,(8)
    ,(9)

-- ============================================================
-- Renderização visual do pinheiro
-- ============================================================

-- Ramificação lógica: linhas acima do tronco usam REPLICATE para
-- centralizar e expandir os galhos; a última linha desenha o tronco
SELECT
    CASE
        WHEN MAX(i.row_id) OVER () - i.row_id > 1
            THEN REPLICATE(' ', MAX(i.row_id) OVER () - 2 - i.row_id)
                + REPLICATE('*', i.row_id)
                + REPLICATE('*', i.row_id - 1)
        ELSE REPLICATE(' ', MAX(i.row_id) OVER () - 3)
            + '|'
    END AS img
FROM @image AS i
