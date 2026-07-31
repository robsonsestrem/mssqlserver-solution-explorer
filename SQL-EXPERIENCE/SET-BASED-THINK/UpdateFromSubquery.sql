/*
 *
	OBJETIVO: Atualização condicional de registros em TRACONTASLEVEL1 com base em
			  subquery derivada que combina dados de TRANSACIONADORES e TRACONTASLEVEL1,
			  utilizando controle transacional com tratamento de erros (TRY...CATCH).
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/t-sql/queries/update-transact-sql
 */
-- ============================================================
-- Atualização com Subquery Derivada e Controle Transacional
-- ============================================================

USE YOUR_DATABASE
GO

BEGIN TRANSACTION
BEGIN TRY
    -- Atualização de TraConBanCod para 0 quando atender aos critérios da subquery
    UPDATE YOUR_DATABASE.dbo.TRACONTASLEVEL1
    SET TraConBanCod = 0
    WHERE TraConCod IN
    (
        -- Subquery derivada que combina dados de TRANSACIONADORES e TRACONTASLEVEL1
        SELECT Cod
        FROM
        (
            -- Primeira parte: dados de TRANSACIONADORES com TRASIT = 1
            SELECT 
                Cod = TRACOD
                ,Nome = TRANOM
                ,Nat = TRANATJURIDICA
                ,CPF = TRACPF
                ,CNPJ = TraCnpj
                ,Origem = 'Transacionadores'
                ,Banco = TRABANCOD
                ,Age = TRAAGECOD
                ,Conta = TRACODCONTABANCO
            FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
            WHERE T.TRASIT = 1

            UNION

            -- Segunda parte: dados combinados de TRANSACIONADORES e TRACONTASLEVEL1
            SELECT 
                Cod = TRACOD
                ,Nome = TRANOM
                ,Nat = TRANATJURIDICA
                ,CPF = TRACPF
                ,CNPJ = TraCnpj
                ,Origem = 'TraContasLevel1'
                ,Banco = TraConBanCod
                ,Age = TraconAgeCod
                ,Conta = TraConNumCon
            FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
            INNER JOIN YOUR_DATABASE.dbo.TRACONTASLEVEL1 AS C
                ON T.TRACOD = C.TRACONCOD
            WHERE T.TRASIT = 1
        ) AS X
        WHERE X.Banco = 1
        AND X.Cod = TraConCod
    )
    AND TraConBanCod = 1

    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    -- Reversão da transação em caso de erro
    ROLLBACK TRANSACTION

    -- Exibição das informações do erro ocorrido
    SELECT 
        ERROR_NUMBER() AS ErrorNumber
        ,ERROR_MESSAGE() AS ErrorMessage
END CATCH

-- Reversão manual da transação (executar apenas em caso de erro não capturado)
-- ROLLBACK TRANSACTION

-- Validação do contador de transações
-- SELECT @@TRANCOUNT
