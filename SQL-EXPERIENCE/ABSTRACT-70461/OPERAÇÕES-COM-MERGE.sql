----------------------------------------------------------------------------------------------------------------------------------------------
-- O comando com MERGE Realiza operações de inserção, atualização ou exclusão em uma tabela de destino com base nos resultados 
-- da junção com a tabela de origem. Por exemplo, você pode sincronizar duas tabelas inserindo, 
-- atualizando ou excluindo linhas em uma tabela com base nas diferenças encontradas na outra tabela.
----------------------------------------------------------------------------------------------------------------------------------------------
-- 1  Exemplo – Stored Procedure + Comando Merge + Output:

-- Criando a Tabela Producao —
CREATE TABLE Producao (
  ControleProducao INT IDENTITY (1, 1) PRIMARY KEY
 ,OrdemProducao VARCHAR(20) NOT NULL
 ,DataProducao DATETIME NOT NULL
 ,Quantidade INT NOT NULL
)

-- Popula
INSERT INTO Producao (OrdemProducao, DataProducao, Quantidade)
  VALUES (1, GETDATE(), 1),
  (2, GETDATE(), 1),
  (3, GETDATE(), 1)

-- Criando a Stored Procedure P_FindProducao —
CREATE PROCEDURE P_FindProducao @OrdemProducao VARCHAR(20)
, @DataProducao DATETIME
AS
BEGIN
  SET NOCOUNT ON;

  MERGE Producao AS Target
  USING
  -- junção
  (SELECT
      @OrdemProducao
     ,@DataProducao) AS Source (OrdemProducao, DataProducao)
  ON (Target.OrdemProducao = Source.OrdemProducao
    AND Target.DataProducao = Source.DataProducao)
  -- condição 1
  WHEN MATCHED
    THEN UPDATE
      SET Quantidade = Quantidade + 1
         ,DataProducao = GETDATE()

  WHEN NOT MATCHED
    THEN INSERT (OrdemProducao, DataProducao, Quantidade)
        VALUES (Source.OrdemProducao, Source.DataProducao, 1)

  -- mostra o que foi deletado e o que foi inserido
  OUTPUT DELETED.*
        ,$ACTION   -- $action retorna o tipo de DML
        ,INSERTED.*;

END
GO

-- Teste
EXEC P_FindProducao 1, '2014-07-08 10:06:50.297'

SELECT
  *
FROM Producao


----------------------------------------------------------------------------------------------------------------------------------------------
-- 2 – Exemplo – Stored Procedure + Comando Merge + Output + Try….Catch:
----------------------------------------------------------------------------------------------------------------------------------------------
-- Criando a Tabela Producao —
CREATE TABLE Producao (
  OrdemProducao VARCHAR(20) NOT NULL PRIMARY KEY CLUSTERED
 ,DataProducao DATETIME NOT NULL
 ,Quantidade INT NOT NULL
)

-- Criando a Stored Procedure P_FindProducao —
CREATE PROCEDURE P_FindProducao @OrdemProducao VARCHAR(20), @DataProducao DATETIME
AS
BEGIN
  SET NOCOUNT ON;
  BEGIN TRY
    MERGE Producao AS Target
    USING (SELECT
        @OrdemProducao
       ,@DataProducao) AS Source (OrdemProducao, DataProducao)
    ON (Target.OrdemProducao = Source.OrdemProducao
      AND Target.DataProducao = Source.DataProducao)
    WHEN MATCHED
      THEN UPDATE
        SET Quantidade = Quantidade + 1
           ,DataProducao = GETDATE()
    WHEN NOT MATCHED
      THEN INSERT (OrdemProducao, DataProducao, Quantidade)
          VALUES (Source.OrdemProducao, Source.DataProducao, 1);
  END TRY
  BEGIN CATCH
    SELECT
      ERROR_NUMBER() AS ErrorNumber
     ,ERROR_SEVERITY() AS ErrorSeverity
     ,ERROR_STATE() AS ErrorState
     ,ERROR_PROCEDURE() AS ErrorProcedure
     ,ERROR_MESSAGE() AS ErrorMessage
     ,ERROR_LINE() AS ErrorLine;
  END CATCH
END
GO

SELECT
  *
FROM Producao

INSERT INTO Producao (OrdemProducao, DataProducao, Quantidade)
  VALUES (1, GETDATE(), 1),
  (2, GETDATE(), 1),
  (3, GETDATE(), 1)
EXEC P_FindProducao 3, '2014-07-08 10:26:25.250'