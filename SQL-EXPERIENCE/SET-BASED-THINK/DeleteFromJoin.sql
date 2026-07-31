/*
	OBJETIVO: Excluir registros da tabela TRANSACIONADORES que possuem
			  correspondência em uma subconsulta que combina dados da própria
			  tabela e da tabela TRACONTASLEVEL1, filtrados por condição
			  específica de banco.
	PROJETO: mssqlserver-solution-explorer
*/
USE YOUR_DATABASE
GO

BEGIN TRY
    BEGIN TRANSACTION
        DELETE FROM YOUR_DATABASE.dbo.TRANSACIONADORES
        FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS t1
        INNER JOIN
        (
            SELECT
                  Cod
            FROM
            (
                SELECT
                      TRACOD                                                                  AS Cod
                    , TRANOM                                                                  AS Nome
                    , TRANATJURIDICA                                                          AS Nat
                    , TRACPF                                                                  AS CPF
                    , TraCnpj                                                                 AS CNPJ
                    , 'Transacionadores'                                                      AS Origem
                    , TRABANCOD                                                               AS Banco
                    , TRAAGECOD                                                               AS Age
                    , TRACODCONTABANCO                                                        AS Conta
                FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
                WHERE T.TRASIT = 1

                UNION

                SELECT
                      TRACOD
                    , TRANOM
                    , TRANATJURIDICA
                    , TRACPF
                    , TraCnpj
                    , 'TraContasLevel1'
                    , TraConBanCod
                    , TraconAgeCod
                    , TraConNumCon
                FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
                INNER JOIN YOUR_DATABASE.dbo.TRACONTASLEVEL1 AS C
                        ON T.TRACOD = C.TRACONCOD
                WHERE T.TRASIT = 1
            ) AS x
            WHERE X.Banco IN (1)
        ) AS t2
            ON t1.TraCod = t2.Cod;
    COMMIT TRANSACTION
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION
    SELECT
          ERROR_NUMBER() AS ErrorNumber
        , ERROR_MESSAGE() AS ErrorMessage;
END CATCH;

-- COMMIT TRANSACTION;
-- SELECT @@TRANCOUNT;
