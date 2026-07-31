/*
 *
	OBJETIVO: Atualização em massa da tabela TRACONTASLEVEL1 utilizando JOIN com subconsulta
			  para definir o código do banco (TraConBanCod) com base em dados da tabela
			  TRANSACIONADORES, com tratamento de transação e rollback em caso de erro.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Atualização com JOIN e subconsulta para definir TraConBanCod
-- ============================================================
USE YOUR_DATABASE
GO

BEGIN TRANSACTION

BEGIN TRY
    UPDATE YOUR_DATABASE.dbo.TRACONTASLEVEL1
    SET TraConBanCod = 0
    FROM YOUR_DATABASE.dbo.TRACONTASLEVEL1 AS t1
    INNER JOIN
    (
        SELECT Cod
        FROM
        (
            SELECT
                Cod = TRACOD,
                Nome = TRANOM,
                Nat = TRANATJURIDICA,
                CPF = TRACPF,
                CNPJ = TraCnpj,
                Origem = 'Transacionadores',
                Banco = TRABANCOD,
                Age = TRAAGECOD,
                Conta = TRACODCONTABANCO
            FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
            WHERE T.TRASIT = 1

            UNION

            SELECT
                TRACOD,
                TRANOM,
                TRANATJURIDICA,
                TRACPF,
                TraCnpj,
                'TraContasLevel1',
                TraConBanCod,
                TraconAgeCod,
                TraConNumCon
            FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
            INNER JOIN YOUR_DATABASE.dbo.TRACONTASLEVEL1 AS C
                ON T.TRACOD = C.TRACONCOD
            WHERE T.TRASIT = 1
        ) AS x
        WHERE X.BANCO = 1
    ) AS t2
        ON t1.TraConCod = t2.Cod
    WHERE TraConBanCod = 1
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    SELECT
        ERROR_NUMBER(),
        ERROR_MESSAGE()
END CATCH

COMMIT TRANSACTION
GO

-- SELECT @@TRANCOUNT
