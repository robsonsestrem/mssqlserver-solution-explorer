CREATE TRIGGER trgAU_AudOF 
ON OperacaoFinanceira
FOR UPDATE
AS
DECLARE @Col INT, @qCols INT, @NomeCol VARCHAR(50)
DECLARE @bitVerificador INT, @Pot INT

SET @Col = 0

-- Conta quantas colunas existem na tabela contemplada pela Trigger
SET @qCols = (SELECT COUNT(*) FROM sys.columns WHERE object_id =
    (SELECT Parent_ID FROM sys.triggers WHERE object_id = @@procid))

-- Coloca a tabela Deleted em uma variável XML
DECLARE @Deleted XML, @DeletedTMP XML
SET @Deleted = (SELECT * FROM Deleted FOR XML RAW, ROOT('Deleted'))

-- Coloca a tabela Inserted em uma variável XML
DECLARE @Inserted XML, @InsertedTMP XML
SET @Inserted = (SELECT * FROM Inserted FOR XML RAW, ROOT('Inserted'))

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

        -- Substitui a TAG no XML da DELETED e faz a extração dos dados
        SET @DeletedTMP = REPLACE(CAST(@Deleted As VARCHAR(MAX)),@NomeCol + '=','Col=')

        -- Substitui a TAG no XML da INSERTED e faz a extração dos dados
        SET @InsertedTMP = REPLACE(CAST(@Inserted As VARCHAR(MAX)),@NomeCol + '=','Col=')

        INSERT INTO AudOF (IDOperacaoFinanceira, DataAlteracao, Coluna, ValorAntigo, ValorNovo)
        SELECT INS.IDOperacaoFinanceira, GETDATE(), @NomeCol,
            (SELECT E.e.value('
                (/Deleted/row[@IDOperacaoFinanceira = sql:column(INS.IDOperacaoFinanceira)]/@Col)[1]','varchar(100)')
            FROM @DeletedTMP.nodes('.') E(e)) As ValorAntigo,
            (SELECT E.e.value('
                (/Inserted/row[@IDOperacaoFinanceira = sql:column(INS.IDOperacaoFinanceira)]/@Col)[1]','varchar(100)')
            FROM @InsertedTMP.nodes('.') E(e)) As ValorNovo
        FROM Inserted As Ins
    END
END


--------------------------------------------------------------------------------------------------------------------------
-- Após fazer um create table OperacaoFinanceira com as colunas : 
-- IDAudOF - IDOperacaoFinanceira - DataAlteracao - Coluna - ValorAntigo - ValorNovo
--------------------------------------------------------------------------------------------------------------------------

-- Atualiza as colunas CodStatusOpFin e IDUsuario cuja operação financeira tenha o ID igual a 27
UPDATE OperacaoFinanceira SET CodStatusOpFin = 4, IDUsuario = 'Teles_0003' WHERE IDOperacaoFinanceira = 27

-- Atualiza a coluna IDProduto onde as operações financeiras tenham data de operação igual ou superior a 03/05/2010
UPDATE OperacaoFinanceira SET IDProduto = 21 WHERE DataOpFinanceira >= '20100503'



-- Adiciona mais uma coluna na tabela OperacaoFinanceira
ALTER TABLE OperacaoFinanceira ADD IDInstituicao INT

-- Atualiza todos os registros
UPDATE OperacaoFinanceira SET IDInstituicao = 1

-- Verifica a tabela de Auditoria
SELECT IDAudOF, IDOperacaoFinanceira, DataAlteracao, Coluna, ValorAntigo, ValorNovo
FROM AudOF WHERE Coluna = 'IDInstituicao'
--------------------------------------------------------------------------------------------------------------------------




CREATE TABLE OperacaoFinanceira (
    IDOperacaoFinanceira INT NOT NULL, DataOpFinanceira DATE,
    DataProcessamento DATE, CodStatusOpFin TINYINT,
    CodTipoMovimento INT, IDUsuario VARCHAR(100),
    IDProduto INT, IDModalidade INT, Valor SMALLMONEY,
    BolEstorno TINYINT, BolAuditada TINYINT,
    CONSTRAINT PK_OperacaoFinanceira PRIMARY KEY (IDOperacaoFinanceira))

INSERT INTO OperacaoFinanceira VALUES (25,'20100501','20100503',1,4,'Diego_0003',23,2,550.01,0,0)
INSERT INTO OperacaoFinanceira VALUES (26,'20100501','20100503',1,5,'Marco_0004',15,1,945.13,1,0)
INSERT INTO OperacaoFinanceira VALUES (27,'20100502','20100503',2,1,'Tiago_0003',28,3,126.67,1,1)
INSERT INTO OperacaoFinanceira VALUES (28,'20100503','20100503',1,2,'Fabio_0007',11,4,437.55,0,1)
INSERT INTO OperacaoFinanceira VALUES (29,'20100504','20100504',3,3,'Diana_0008',18,2,682.39,0,1)


CREATE TABLE AudOF (
IDAudOF INT IDENTITY(1,1),
IDOperacaoFinanceira INT, 
DataAlteracao DATETIME, 
Coluna SYSNAME,-- mesma função de um nvarchar(128), só que já seta como not null
ValorAntigo VARCHAR(100), 
ValorNovo VARCHAR(100))



--OBS.: SÓ FUNCIONA PARA OPERAÇÕES DE UPDATE
--testes abaixo

  --delete from OperacaoFinanceira
  --where IDOperacaoFinanceira = 29

  --update OperacaoFinanceira set CodStatusOpFin = 3
  --where IDOperacaoFinanceira = 26

  --insert into OperacaoFinanceira 
  --(
  --[IDOperacaoFinanceira]
  --    ,[DataOpFinanceira]
  --    ,[DataProcessamento]
  --    ,[CodStatusOpFin]
  --    ,[CodTipoMovimento]
  --    ,[IDUsuario]
  --    ,[IDProduto]
  --    ,[IDModalidade]
  --    ,[Valor]
  --    ,[BolEstorno]
  --    ,[BolAuditada]
  --    ,[IDInstituicao]
	 -- )
	 -- values(
	 -- 55, '20150303', '20160302', 6, 23, '34', 123432, 234, 300, 20, 30, 3
	 -- )









 
