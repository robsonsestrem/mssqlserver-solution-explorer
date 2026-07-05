/*
    OBJETIVO: DDL trigger de banco de dados que bloqueia operações de criação,
              alteração e exclusão de índices para o login 'healthmap',
              lançando um erro controlado via THROW.
    PROJETO: mssqlserver-solution-explorer
*/

USE HEALTHCARE_DEMO;
GO

-- Cria ou altera o trigger de banco de dados com criptografia de definição
CREATE OR ALTER TRIGGER INDEX_PREVENTION
ON DATABASE
WITH ENCRYPTION
FOR CREATE_INDEX, ALTER_INDEX, DROP_INDEX
AS
BEGIN

    -- Captura o login original que disparou o evento DDL
    DECLARE @UserName NVARCHAR(100) = ORIGINAL_LOGIN();

    -- Verifica se o usuário restrito está tentando manipular índices
    IF @UserName = 'healthmap'
    BEGIN

        -- Lança erro controlado e aborta a operação DDL
        ;THROW 50000, 'User does not have permission to manipulate indexes, contact your database administrator.', 1;

    END;

END;
GO

/*
    ABORDAGEM ALTERNATIVA (dentro do bloco IF):
    -- PRINT 'User does not have permission to manipulate indexes, contact your database administrator.';
    -- ROLLBACK;
*/
