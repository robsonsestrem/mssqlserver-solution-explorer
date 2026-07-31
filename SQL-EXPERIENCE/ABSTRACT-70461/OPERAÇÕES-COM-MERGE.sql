/*
 *
    OBJETIVO: Scripts de demonstração do comando MERGE no SQL Server para
              sincronização de tabelas (INSERT, UPDATE e DELETE em uma única
              instrução). Inclui dois exemplos: (1) MERGE com OUTPUT para
              visualizar DML executada e (2) MERGE com tratamento de erros
              via TRY...CATCH e funções de erro.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIA: Curso ProWay - https://proway.com.br/
 * 
 */
-- ============================================================
-- Exemplo 1: Stored Procedure + MERGE + OUTPUT
-- ============================================================
-- Cria a tabela de produção com chave primária identity
CREATE TABLE Producao (
      ControleProducao INT IDENTITY(1, 1) PRIMARY KEY
    , OrdemProducao    VARCHAR(20) NOT NULL
    , DataProducao     DATETIME NOT NULL
    , Quantidade       INT NOT NULL
)

-- Popula a tabela com dados iniciais de teste
INSERT INTO Producao (OrdemProducao, DataProducao, Quantidade)
VALUES
      (1, GETDATE(), 1)
    , (2, GETDATE(), 1)
    , (3, GETDATE(), 1)
GO

-- Cria a stored procedure que utiliza MERGE para fazer upsert:
-- se o registro já existe (MATCHED), atualiza a quantidade e a data;
-- se não existe (NOT MATCHED), insere um novo registro.
-- A cláusula OUTPUT retorna os valores antes (DELETED) e depois (INSERTED)
-- da operação, além de $ACTION que indica o tipo de DML executado.
CREATE PROCEDURE P_FindProducao
      @OrdemProducao VARCHAR(20)
    , @DataProducao  DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    -- MERGE: sincroniza a tabela Producao com os parâmetros de entrada
    MERGE Producao AS Target
    USING (
        SELECT
              @OrdemProducao
            , @DataProducao
    ) AS Source (OrdemProducao, DataProducao)
    ON (
        Target.OrdemProducao = Source.OrdemProducao
        AND Target.DataProducao = Source.DataProducao
    )
    -- Condição 1: registro existe → atualiza quantidade e data
    WHEN MATCHED
        THEN UPDATE
            SET
                  Quantidade = Quantidade + 1
                , DataProducao = GETDATE()
    -- Condição 2: registro não existe → insere novo
    WHEN NOT MATCHED
        THEN INSERT (OrdemProducao, DataProducao, Quantidade)
            VALUES (Source.OrdemProducao, Source.DataProducao, 1)
    -- Retorna o que foi alterado: DELETED (antes), $ACTION (tipo de DML), INSERTED (depois)
    OUTPUT
          DELETED.*
        , $ACTION
        , INSERTED.*;
END
GO

-- Teste: executa a procedure com ordem de produção 1 (já existe → UPDATE)
EXEC P_FindProducao 1, '2014-07-08 10:06:50.297'

-- Verifica o resultado na tabela
SELECT
    *
FROM
    Producao
GO


-- ============================================================
-- Exemplo 2: Stored Procedure + MERGE + OUTPUT + TRY...CATCH
-- ============================================================
-- OBS: Este exemplo recria a tabela Producao com estrutura diferente.
--      Se executado após o Exemplo 1, é necessário dropar a tabela primeiro.
-- Cria a tabela de produção com OrdemProducao como chave primária clusterizada
CREATE TABLE Producao (
      OrdemProducao VARCHAR(20) NOT NULL PRIMARY KEY CLUSTERED
    , DataProducao  DATETIME NOT NULL
    , Quantidade    INT NOT NULL
)
GO

-- Cria a stored procedure com MERge encapsulado em TRY...CATCH:
-- em caso de erro, captura detalhes via funções ERROR_* no bloco CATCH.
CREATE PROCEDURE P_FindProducao
      @OrdemProducao VARCHAR(20)
    , @DataProducao  DATETIME
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- MERGE: sincroniza a tabela Producao com os parâmetros de entrada
        MERGE Producao AS Target
        USING (
            SELECT
                  @OrdemProducao
                , @DataProducao
        ) AS Source (OrdemProducao, DataProducao)
        ON (
            Target.OrdemProducao = Source.OrdemProducao
            AND Target.DataProducao = Source.DataProducao
        )
        -- Condição 1: registro existe → atualiza quantidade e data
        WHEN MATCHED
            THEN UPDATE
                SET
                      Quantidade = Quantidade + 1
                    , DataProducao = GETDATE()
        -- Condição 2: registro não existe → insere novo
        WHEN NOT MATCHED
            THEN INSERT (OrdemProducao, DataProducao, Quantidade)
                VALUES (Source.OrdemProducao, Source.DataProducao, 1);
    END TRY
    BEGIN CATCH
        -- Captura detalhes do erro ocorrido durante o MERGE
        SELECT
              ERROR_NUMBER()     AS ErrorNumber
            , ERROR_SEVERITY()   AS ErrorSeverity
            , ERROR_STATE()      AS ErrorState
            , ERROR_PROCEDURE()  AS ErrorProcedure
            , ERROR_MESSAGE()    AS ErrorMessage
            , ERROR_LINE()       AS ErrorLine;
    END CATCH
END
GO

-- Verifica o estado atual da tabela (vazia neste ponto)
SELECT
    *
FROM
    Producao

-- Popula a tabela com dados iniciais de teste
INSERT INTO Producao (OrdemProducao, DataProducao, Quantidade)
VALUES
      (1, GETDATE(), 1)
    , (2, GETDATE(), 1)
    , (3, GETDATE(), 1)

-- Teste: executa a procedure com ordem de produção 3 (já existe → UPDATE)
EXEC P_FindProducao 3, '2014-07-08 10:26:25.250'
