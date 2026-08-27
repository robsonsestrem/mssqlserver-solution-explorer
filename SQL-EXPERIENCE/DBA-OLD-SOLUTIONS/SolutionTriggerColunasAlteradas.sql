/*
 *
    OBJETIVO: Trigger de teste para identificar colunas alteradas em UPDATE
              usando COLUMNS_UPDATED e bitmask de colunas, com script de teste.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://learn.microsoft.com/pt-br/sql/t-sql/functions/columns-updated-transact-sql
 *  https://learn.microsoft.com/pt-br/sql/relational-databases/system-catalog-views/sys-columns-transact-sql
 */
-- ============================================================
-- Trigger tr_ColunasAlteradas
-- Identifica colunas atualizadas na tabela T e imprime a lista.
-- ============================================================
CREATE OR ALTER TRIGGER tr_ColunasAlteradas
ON T
FOR UPDATE
AS
BEGIN
    DECLARE @Col INT
          , @Cols VARCHAR(1000)
          , @qCols INT
          , @NomeCol VARCHAR(50)
          , @bitVerificador INT
          , @Pot INT

    SET @Col = 0
    SET @Cols = ''

    -- Conta quantas colunas existem na tabela contemplada pela trigger
    SET @qCols =
    (
        SELECT COUNT(*)
        FROM sys.columns
        WHERE object_id =
        (
            SELECT Parent_ID
            FROM sys.triggers
            WHERE object_id = @@PROCID
        )
    )

    -- Percorre o bitmask de colunas atualizadas
    WHILE (@Col < @qCols)
    BEGIN
        SET @Col = @Col + 1
        SET @Pot = (@Col - 1) % 8 + 1
        SET @Pot = POWER(2, @Pot - 1)
        SET @bitVerificador = ((@Col - 1) / 8) + 1

        IF (SUBSTRING(COLUMNS_UPDATED(), @bitVerificador, 1) & @Pot > 0)
        BEGIN
            SET @NomeCol =
            (
                SELECT Name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT Parent_ID
                    FROM sys.triggers
                    WHERE object_id = @@PROCID
                )
                AND column_id = @Col
            )

            SET @Cols = @Cols + @NomeCol + ';'
        END
    END

    PRINT @Cols
END
GO

-- ============================================================
-- Tabela de teste T
-- ============================================================
CREATE TABLE [dbo].[T]
(
    [C1] [INT] NULL
  , [C2] [INT] NULL
  , [C3] [INT] NULL
  , [C4] [INT] NULL
  , [C5] [INT] NULL
  , [C6] [INT] NULL
  , [C7] [INT] NULL
  , [C8] [INT] NULL
) ON [PRIMARY]

-- ============================================================
-- Carga inicial da tabela de teste
-- ============================================================
INSERT INTO T
VALUES
(
    1
  , 2
  , 3
  , 4
  , 5
  , 6
  , 7
  , 8
)

-- ============================================================
-- Consulta da tabela de teste
-- ============================================================
SELECT *
FROM T

-- ============================================================
-- Testes de atualização para disparar a trigger
-- ============================================================
UPDATE T
SET C1 = 0

UPDATE T
SET C4 = 0
  , C6 = 0
  , C7 = 0
  , C8 = 0
