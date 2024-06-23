---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://www.devmedia.com.br/melhoria-de-desempenho-utilizando-estatisticas-e-indices/32631
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- SELECT top 1 * FROM sys.dm_tran_current_transaction
CREATE DATABASE TEST;
go
ALTER DATABASE TEST SET Recovery Simple
go
USE TEST
go
-- cria a tabela NUMERO
CREATE TABLE numero(n INT NOT NULL PRIMARY KEY);
go
-- insere os registros na tabela numero
INSERT numero(n)
   SELECT rn FROM (SELECT ROW_NUMBER()
              OVER(ORDER BY current_timestamp) AS rn
            FROM sys.trace_event_bindings AS b1
              ,sys.trace_event_bindings AS b2) AS rd
   WHERE rn <= 1000000
go
-- cria uma tabela de teste
IF (object_id('T0', 'U') IS NOT NULL)
 DROP TABLE T0;
go
CREATE TABLE T0
 ( c1 INT NOT NULL
  ,c2 nchar(200) NOT NULL DEFAULT '#'
 )
go
-- Insere 100000 linhas com o valor 1000 para a coluna c1
INSERT T0(c1)
  SELECT 1000 FROM numero
  WHERE n <= 100000
go
-- insere uma linha com valor 2000
INSERT T0(c1) VALUES(2000)
go
--cria um índice nonclustered para a coluna c1
CREATE NONCLUSTERED INDEX ix_T0_1 ON T0(c1)


---------------------------------------------------------------------------
-- Problemas que ocorrem com estimativa e variáveis locais 
---------------------------------------------------------------------------
DECLARE @x int
SET @x = 2000
SELECT c1,c2
 FROM T0
 WHERE c1 = @x

-- solução com proc - melhora plano de execução
CREATE PROCEDURE getT0Values(@x int) AS
SELECT c1,c2 FROM T0
WHERE c1 = @x

EXEC getT0Values 2000

-- solução com sql dinâmico - melhora plano de execução mas tem efeitos colaterais muito negativos
DECLARE @x int
    ,@cmd nvarchar(300)
SET @x = 2000
SET @cmd = 'SELECT c1,c2 FROM T0 WHERE c1=' + CAST(@x as nvarchar(8))
EXEC (@cmd)

-- melhor forma com sql dinâmico
EXEC sp_executesql N'SELECT c1, c2 FROM T0 WHERE c1 = @x', N'@x int', @x = 2000



---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- AQUI EXPLICA COMO AS ESTATÍSTICAS NÃO ATUALIZAM AUTOMATICAMENTE
-- Estatísticas remotas
-- A sincronização de estatísticas sempre fica para trás nas modificações de dados reais. Por isso, quase todos os objetos estatísticos são obsoletos, pelo menos até um certo nível.
-- Em muitos casos, esse comportamento é absolutamente aceitável, mas há também situações em que o desvio entre os dados de origem e as estatísticas pode ser muito grande.
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE produto
 ( id_produto int IDENTITY(1,1) NOT NULL
  ,valor decimal(8,2) NOT NULL
  ,data_alteracao datetime NOT NULL default current_timestamp
)
GO
ALTER TABLE produto ADD CONSTRAINT pk_produto
 PRIMARY KEY CLUSTERED (id_produto)


CREATE NONCLUSTERED INDEX ix_produto_data_alteracao ON produto(data_alteracao)

-- insert de massa de dados
INSERT produto(data_alteracao, valor)
 SELECT DATEADD(day, abs(checksum(newid())) % 3250,01/01/2010)
    ,0.01*(ABS(checksum(newid())) % 20000)
  FROM numero
 WHERE n <= 500000
GO
--
UPDATE STATISTICS produto WITH FULLSCAN;


-- Utilizou-se alguns valores calculados de forma aleatória para data_alteracao e valor, 
-- além de atualizar todas as estatísticas existentes após o comando insert ser concluído. Em seguida, faz-se a inserção de mais 100 mil registros, estes, 
-- porém, todos com a data fixa em 01/01/2015:

INSERT produto(data_alteracao, valor)
   SELECT '01/01/2015', 100 FROM numero WHERE n <= 100000

SELECT * FROM produto WHERE data_alteracao = '01/01/2015'

-- RODE O PLANO E VERÁ A DISCREPÂNCIA NA DIFERENÇA DE VALORES ESTIMADOS
-- SOLUÇÃO -> ATUALIZE MANUALMENTE
UPDATE STATISTICS produto WITH FULLSCAN;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Estatísticas para colunas correlatas não são suportadas
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE veiculo_aluguel(
 id_veiculo_aluguel INT NOT NULL IDENTITY(1,1) PRIMARY KEY clustered
 ,tipo_veiculo nvarchar(20) NOT NULL
 ,valor_diaria decimal(6,2)
)

CREATE NONCLUSTERED INDEX ix_veiculo_aluguel_tipo_veic_valor_diaria
ON veiculo_aluguel(tipo_veiculo, valor_diaria)


-- Inserção de registros na tabela de aluguel de veículos.
;WITH tipo_veiculo(minimo, maximo, tipo) AS
 ( SELECT 40, 69, 'Básico'
  UNION ALL SELECT 70, 99, 'Sedan'
  UNION ALL SELECT 100, 149, 'Camionete'
  UNION ALL SELECT 149, 250, 'Luxo'
 )
INSERT veiculo_aluguel(tipo_veiculo, valor_diaria)
 SELECT tipo, minimo + abs(checksum(newid())) % (maximo-minimo)
  FROM tipo_veiculo
     INNER JOIN numero ON n <= 25000
GO

UPDATE STATISTICS veiculo_aluguel WITH FULLSCAN

SELECT * FROM Veiculo_aluguel
   WHERE Tipo_veiculo='Luxo'
    AND Valor_diaria < 149

-- usando índice filtrado
CREATE NONCLUSTERED INDEX ix_veiculo_aluguel_tipo_luxo_valor_diaria
    ON veiculo_aluguel(valor_diaria)
   WHERE tipo_veiculo='Luxo'






