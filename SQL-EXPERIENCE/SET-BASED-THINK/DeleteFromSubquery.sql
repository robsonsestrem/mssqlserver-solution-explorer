/*
    OBJETIVO: Excluir registros da tabela TRANSACIONADORES com base em uma subquery
              que identifica códigos específicos através de UNION entre duas consultas,
              utilizando transação com tratamento de erros via TRY/CATCH.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- SEÇÃO 1: Exclusão com transação e tratamento de erros
-- ============================================================

BEGIN TRY
    -- Início da transação para garantir atomicidade da operação
    BEGIN TRANSACTION;

    -- Exclusão de registros da tabela TRANSACIONADORES
    -- Filtra apenas códigos presentes na subquery com Banco = 1
    DELETE FROM YOUR_DATABASE.dbo.TRANSACIONADORES
    WHERE TraCod IN (
        -- Subquery que seleciona códigos através de UNION
        SELECT x.Cod
        FROM (
            -- Primeira parte do UNION: dados da tabela TRANSACIONADORES
            SELECT 
                T.TRACOD AS Cod
                , T.TRANOM AS Nome
                , T.TRANATJURIDICA AS Nat
                , T.TRACPF AS CPF
                , T.TraCnpj AS CNPJ
                , 'Transacionadores' AS Origem
                , T.TRABANCOD AS Banco
                , T.TRAAGECOD AS Age
                , T.TRACODCONTABANCO AS Conta
            FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
            WHERE T.TRASIT = 1

            UNION

            -- Segunda parte do UNION: dados do JOIN com TRACONTASLEVEL1
            SELECT 
                T.TRACOD AS Cod
                , T.TRANOM AS Nome
                , T.TRANATJURIDICA AS Nat
                , T.TRACPF AS CPF
                , T.TraCnpj AS CNPJ
                , 'TraContasLevel1' AS Origem
                , C.TraConBanCod AS Banco
                , C.TraconAgeCod AS Age
                , C.TraConNumCon AS Conta
            FROM YOUR_DATABASE.dbo.TRANSACIONADORES AS T
            INNER JOIN YOUR_DATABASE.dbo.TRACONTASLEVEL1 AS C
                ON T.TRACOD = C.TRACONCOD
            WHERE T.TRASIT = 1
        ) AS x
        WHERE x.Banco IN (1)
    );

    -- Confirmação da transação em caso de sucesso
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    -- Reversão da transação em caso de erro
    ROLLBACK TRANSACTION;

    -- Retorno das informações do erro ocorrido
    SELECT 
        ERROR_NUMBER() AS ErrorNumber
        , ERROR_MESSAGE() AS ErrorMessage;
END CATCH;

-- COMMIT TRANSACTION;
-- SELECT @@TRANCOUNT;
