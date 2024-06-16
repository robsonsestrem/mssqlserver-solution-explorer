CREATE TRIGGER tr_ColunasAlteradas ON T
FOR UPDATE
AS
DECLARE @Col INT, @Cols VARCHAR(1000), @qCols INT, @NomeCol VARCHAR(50)
DECLARE @bitVerificador INT, @Pot INT

SET @Col = 0
SET @Cols = ''

-- Conta quantas colunas existem na tabela contemplada pela Trigger
SET @qCols = (SELECT COUNT(*) FROM sys.columns WHERE object_id =
    (SELECT Parent_ID FROM sys.triggers WHERE object_id = @@procid))

WHILE (@Col < @qCols)
BEGIN
    SET @Col = @Col + 1
    SET @Pot = (@Col - 1) % 8 + 1
    SET @Pot = POWER(2,@Pot - 1)
    SET @bitVerificador = ((@Col - 1) / 8) + 1
    IF (SUBSTRING(COLUMNS_UPDATED(),@bitVerificador, 1) & @Pot > 0)
    BEGIN
        SET @NomeCol = (
            SELECT Name FROM sys.columns WHERE object_id =
                (SELECT Parent_ID FROM sys.triggers
                WHERE object_id = @@procid) AND column_id = @Col)
        SET @Cols = @Cols + @NomeCol + ';'
    END
END

PRINT @Cols

---------------------------------------------------------------------------------


CREATE TABLE [dbo].[T](
	[C1] [int] NULL,
	[C2] [int] NULL,
	[C3] [int] NULL,
	[C4] [int] NULL,
	[C5] [int] NULL,
	[C6] [int] NULL,
	[C7] [int] NULL,
	[C8] [int] NULL
) ON [PRIMARY]

--------------------------------------------------------------------------------


INSERT INTO T VALUES (1,2,3,4,5,6,7,8)


select * from T

UPDATE T SET C1 = 0
UPDATE T SET C4 = 0, C6 = 0, C7 = 0, C8 = 0