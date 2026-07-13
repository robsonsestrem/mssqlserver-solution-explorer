/*
================================================================================
OBJETIVO : Algoritmo de validação de intervalo de dias úteis entre datas,
           detectando falha quando o ciclo de comunicação ultrapassa o limite
           tolerado de dias corridos de segunda a sexta-feira.
PROJETO  : mssqlserver-solution-explorer
================================================================================
*/

-- =============================================================================
-- CONTEXTO DE BANCO (desativado para execução isolada)
-- =============================================================================
-- USE YOUR_DATABASE;
-- GO
-- SELECT filcod, FilNfeDatHorManDes
-- FROM FILIAIS
-- WHERE FilCod = 1
--   AND FilCod <> 90;
-- -- filflag2 = 0

-- =============================================================================
-- CICLO DE TESTE (combinações de datas cobertas pelo algoritmo)
-- @sexta02  -> @quinta02
-- @sexta02  -> @quarta
-- @sexta02  -> @segunda
-- @segunda  -> @sexta01
-- @segunda  -> @quinta01
-- @segunda  -> @quarta01
-- =============================================================================
-- SELECT DATEPART(WEEKDAY, GETDATE()), DATEPART(WEEKDAY, DATEADD(DAY, -1, GETDATE()));

-- =============================================================================
-- CRITERIO: DIFERENCA DE 1 DIA UTIL SOMENTE DE SEGUNDA A SEXTA
-- =============================================================================

-- Declaracao das variaveis de data representando os cenarios do ciclo de teste
DECLARE
	 @quarta01 DATETIME = '20170607'
	,@quinta01 DATETIME = '20170608'
	,@sexta01  DATETIME = '20170609'
	,@sabado   DATETIME = '20170610'
	,@domingo  DATETIME = '20170611'
	,@segunda  DATETIME = '20170612'
	,@terca    DATETIME = '20170613'
	,@quarta   DATETIME = '20170614'
	,@quinta02 DATETIME = '20170615'
	,@sexta02  DATETIME = '20170616';

-- =============================================================================
-- TESTES INDIVIDUAIS (desativados -- consolidados na logica simplificada abaixo)
-- =============================================================================
-- IF (DATEDIFF(DAY, @quinta01, @sexta02) <= 3 AND DATEPART(WEEKDAY, @quinta01) = 6)
-- BEGIN
--     PRINT 'funcionando';
-- END;

-- IF (DATEDIFF(DAY, @quinta01, @sexta02) < 2 AND DATEPART(WEEKDAY, @quinta01) <> 6)
-- BEGIN
--     PRINT 'funcionando';
-- END;

-- IF (DATEDIFF(DAY, @quinta01, @sexta02) >= 2 AND DATEPART(WEEKDAY, @quinta01) <> 6)
-- BEGIN
--     PRINT 'falha';
-- END;

-- IF (DATEDIFF(DAY, @quinta01, @sexta02) > 3 AND DATEPART(WEEKDAY, @quinta01) = 6)
-- BEGIN
--     PRINT 'falha';
-- END;

-- =============================================================================
-- LOGICA SIMPLIFICADA: SE FALHOU NUM DIA, NO OUTRO DIA VAI SER ALERTADO
-- =============================================================================

-- Verifica se o intervalo esta dentro do tolerado (status: funcionando)
-- Regra: sexta-feira tolera ate 3 dias de diferenca (cobre o fim de semana)
--        demais dias uteis aceitam somente 1 dia de diferenca
IF (
	(DATEDIFF(DAY, @quinta02, @sexta02) <= 3 AND DATEPART(WEEKDAY, @quinta02) = 6)
	OR (DATEDIFF(DAY, @quinta02, @sexta02) < 2 AND DATEPART(WEEKDAY, @quinta02) <> 6)
)
BEGIN
	PRINT 'funcionando';
END;

-- Verifica se o intervalo esta fora do tolerado (status: falha)
-- Regra: sexta-feira com mais de 3 dias ou demais dias com 2+ dias de diferenca
IF (
	(DATEDIFF(DAY, @quinta02, @sexta02) >= 2 AND DATEPART(WEEKDAY, @quinta02) <> 6)
	OR (DATEDIFF(DAY, @quinta02, @sexta02) > 3 AND DATEPART(WEEKDAY, @quinta02) = 6)
)
BEGIN
	PRINT 'falha';
END;
