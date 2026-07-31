/*
 *
	OBJETIVO: Atualização em massa de dados entre bases de diferentes databases
			  utilizando UPDATE com JOIN em subquery derivada, sincronizando
			  campos de unidade referencial e fator de conversão de produtos.
	PROJETO: mssqlserver-solution-exacional
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/t-sql/queries/update-transact-sql
 */
-- ============================================================
-- Atualização em Massa entre Databases
-- ============================================================

-- Início da transação para garantir atomicidade da operação
BEGIN TRAN;

-- Atualização dos campos ProUndReferencial e ProFatConversao
-- com base nos dados da base TICRAVIL
UPDATE YOUR_DATABASE.dbo.PRODUTOS
SET ProUndReferencial = deriva.ProUnidReferencial
    ,ProFatConversao = deriva.ProFatConversao
FROM (
    SELECT 
        pn.ProCod
        ,pn.ProUnidReferencial
        ,pn.ProFatConversao
    FROM TICRAVIL.dbo.ProdutosNew AS pn
) AS deriva
WHERE deriva.ProCod = PRODUTOS.ProCod;

-- Confirmação da transação (executar apenas se bem-sucedido)
COMMIT;

-- Reversão da transação (executar apenas em caso de erro)
-- ROLLBACK;
