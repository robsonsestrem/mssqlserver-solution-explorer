/*
	OBJETIVO: Demonstrar problemas de desempenho relacionados a estimativas de
			  cardinalidade, uso de variáveis locais, estatísticas desatualizadas
			  e correlação entre colunas, apresentando soluções práticas como
			  procedimentos armazenados, SQL dinâmico com sp_executesql e
			  índices filtrados.
	PROJETO: mssqlserver-solution-explorer

	REFERÊNCIAS E AUTORIA:
	https://www.devmedia.com.br/melhoria-de-desempenho-utilizando-estatisticas-e-indices/32631
*/

-- ============================================================
-- Criação do banco de dados de teste
-- ============================================================
CREATE DATABASE TEST;
GO

ALTER DATABASE TEST
SET RECOVERY SIMPLE;
GO

USE TEST;
GO

-- ============================================================
-- Criação da tabela auxiliar "numero"
-- ============================================================
CREATE TABLE numero
(
      n INT NOT NULL PRIMARY KEY
);
GO

-- ============================================================
-- Inserção de 1.000.000 registros na tabela "numero"
-- ============================================================
INSERT INTO numero
(
      n
)
SELECT rn
FROM
(
    SELECT
          ROW_NUMBER() OVER (ORDER BY CURRENT_TIMESTAMP) AS rn
    FROM sys.trace_event_bindings AS b1
    CROSS JOIN sys.trace_event_bindings AS b2
) AS rd
WHERE rn <= 1000000;
GO

-- ============================================================
-- Criação da tabela de teste "T0" com índice nonclustered
-- ============================================================
IF (OBJECT_ID('T0', 'U') IS NOT NULL)
BEGIN
    DROP TABLE T0;
END;
GO

CREATE TABLE T0
(
      c1 INT NOT NULL
    , c2 NCHAR(200) NOT NULL DEFAULT '#'
);
GO

-- ============================================================
-- Inserção de 100.000 registros com c1 = 1000
-- ============================================================
INSERT INTO T0
(
      c1
)
SELECT 1000
FROM numero
WHERE n <= 100000;
GO

-- ============================================================
-- Inserção de 1 registro com c1 = 2000
-- ============================================================
INSERT INTO T0
(
      c1
)
VALUES
(
      2000
);
GO

-- ============================================================
-- Criação de índice nonclustered na coluna c1
-- ============================================================
CREATE NONCLUSTERED INDEX ix_T0_1
ON T0(c1);
GO

-- ============================================================
-- Problemas com estimativa e variáveis locais
-- ============================================================

-- Caso 1: Uso de variável local (estimativa ruim)
DECLARE @x INT = 2000;

SELECT
      c1
    , c2
FROM T0
WHERE c1 = @x;
GO

-- ============================================================
-- Solução 1: Utilizar procedimento armazenado (melhora o plano)
-- ============================================================
CREATE PROCEDURE getT0Values
(
      @x INT
)
AS
BEGIN
    SELECT
          c1
        , c2
    FROM T0
    WHERE c1 = @x;
END;
GO

EXEC getT0Values 2000;

-- ============================================================
-- Solução 2: SQL dinâmico com concatenação (melhora o plano,
-- mas tem efeitos colaterais negativos - risco de SQL Injection)
-- ============================================================
DECLARE @x    INT = 2000;
DECLARE @cmd  NVARCHAR(300) = 'SELECT c1, c2 FROM T0 WHERE c1=' + CAST(@x AS NVARCHAR(8));

EXEC (@cmd);

-- ============================================================
-- Solução 3: SQL dinâmico com sp_executesql (melhor abordagem)
-- ============================================================
EXEC sp_executesql
     N'SELECT c1, c2 FROM T0 WHERE c1 = @x'
   , N'@x INT'
   , @x = 2000;

-- ============================================================
-- Demonstração: Estatísticas desatualizadas
-- ============================================================

-- ============================================================
-- Criação da tabela "produto"
-- ============================================================
CREATE TABLE produto
(
      id_produto     INT IDENTITY(1, 1) NOT NULL
    , valor          DECIMAL(8, 2) NOT NULL
    , data_alteracao DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
GO

ALTER TABLE produto
ADD CONSTRAINT pk_produto PRIMARY KEY CLUSTERED (id_produto);

CREATE NONCLUSTERED INDEX ix_produto_data_alteracao
ON produto(data_alteracao);

-- ============================================================
-- Inserção de 500.000 registros na tabela "produto"
-- ============================================================
INSERT INTO produto
(
      data_alteracao
    , valor
)
SELECT
      DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 3250, '01/01/2010')
    , 0.01 * (ABS(CHECKSUM(NEWID())) % 20000)
FROM numero
WHERE n <= 500000;
GO

-- ============================================================
-- Atualização completa das estatísticas
-- ============================================================
UPDATE STATISTICS produto WITH FULLSCAN;

-- ============================================================
-- Inserção de mais 100.000 registros com data fixa (01/01/2015)
-- Causa desatualização das estatísticas
-- ============================================================
INSERT INTO produto
(
      data_alteracao
    , valor
)
SELECT
      '01/01/2015'
    , 100
FROM numero
WHERE n <= 100000;

-- ============================================================
-- Consulta com estimativa incorreta (discrepância entre
-- valores estimados e reais no plano de execução)
-- ============================================================
SELECT *
FROM produto
WHERE data_alteracao = '01/01/2015';

-- ============================================================
-- Solução: Atualizar manualmente as estatísticas
-- ============================================================
UPDATE STATISTICS produto WITH FULLSCAN;

-- ============================================================
-- Demonstração: Estatísticas para colunas correlatas
-- (não são suportadas automaticamente)
-- ============================================================

-- ============================================================
-- Criação da tabela "veiculo_aluguel"
-- ============================================================
CREATE TABLE veiculo_aluguel
(
      id_veiculo_aluguel INT NOT NULL IDENTITY(1, 1) PRIMARY KEY CLUSTERED
    , tipo_veiculo       NVARCHAR(20) NOT NULL
    , valor_diaria       DECIMAL(6, 2)
);
GO

CREATE NONCLUSTERED INDEX ix_veiculo_aluguel_tipo_veic_valor_diaria
ON veiculo_aluguel(tipo_veiculo, valor_diaria);

-- ============================================================
-- Inserção de registros na tabela de aluguel de veículos
-- ============================================================
WITH tipo_veiculo(minimo, maximo, tipo) AS
(
    SELECT 40, 69, 'Básico'
    UNION ALL
    SELECT 70, 99, 'Sedan'
    UNION ALL
    SELECT 100, 149, 'Camionete'
    UNION ALL
    SELECT 149, 250, 'Luxo'
)
INSERT INTO veiculo_aluguel
(
      tipo_veiculo
    , valor_diaria
)
SELECT
      tipo
    , minimo + ABS(CHECKSUM(NEWID())) % (maximo - minimo)
FROM tipo_veiculo
INNER JOIN numero
        ON n <= 25000;
GO

UPDATE STATISTICS veiculo_aluguel WITH FULLSCAN;

-- ============================================================
-- Consulta com duas condições correlatas.
-- O otimizador não tem estatísticas 
-- de correlação entre colunas.
-- ============================================================
SELECT *
FROM veiculo_aluguel
WHERE tipo_veiculo = 'Luxo'
      AND valor_diaria < 149;

-- ============================================================
-- Solução: Utilizar índice filtrado para melhorar a estimativa
-- ============================================================
CREATE NONCLUSTERED INDEX ix_veiculo_aluguel_tipo_luxo_valor_diaria
ON veiculo_aluguel(valor_diaria)
WHERE tipo_veiculo = 'Luxo';
