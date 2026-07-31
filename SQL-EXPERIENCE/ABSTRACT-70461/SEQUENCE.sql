/*
 *
	OBJETIVO: Demonstração do uso de SEQUENCE no SQL Server para geração
			  automática de valores numéricos sequenciais, incluindo criação,
			  utilização em INSERT, consulta do próximo valor, reinicialização,
			  e uso com OVER para ordenação em consultas.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIA: Curso ProWay - https://proway.com.br/
 *	
 */
-- ============================================================
-- Exemplo simples de SEQUENCE
-- ============================================================
CREATE SEQUENCE dbo.demoSequence
AS INT
START WITH 1
INCREMENT BY 1
GO

CREATE TABLE dbo.tblDemo
(
    SeqCol INT PRIMARY KEY,
    ItemName NVARCHAR(25) NOT NULL
)
GO

INSERT INTO dbo.tblDemo
(
    SeqCol,
    ItemName
)
VALUES
(
    NEXT VALUE FOR dbo.demoSequence,
    'Item'
)
GO

SELECT
    *
FROM tblDemo
GO

-- Cada vez que é chamado, faz um incremento
SELECT NEXT VALUE FOR dbo.demoSequence
GO

-- Altera para o valor inicial
ALTER SEQUENCE dbo.demoSequence RESTART WITH 1
GO


-- ============================================================
-- Exemplo com parâmetros de sequência e valor anterior
-- ============================================================
CREATE SEQUENCE Seq
AS INT              -- Tipo
START WITH 1        -- Valor Inicial
INCREMENT BY 1      -- Avança de um em um
MINVALUE 1          -- Valor mínimo
MAXVALUE 1000       -- Valor máximo
CACHE 10            -- Mantém 10 posições em cache
NO CYCLE            -- Não irá reciclar
GO

DECLARE @Tabela TABLE
(
    data DATE,
    Valor DECIMAL(18, 2)
)

INSERT INTO @Tabela
(
    data,
    Valor
)
SELECT GETDATE() - 1, 100
UNION ALL
SELECT GETDATE() - 2, 200
UNION ALL
SELECT GETDATE() - 3, 200
UNION ALL
SELECT GETDATE() - 4, 300
UNION ALL
SELECT GETDATE() - 5, 400
UNION ALL
SELECT GETDATE() - 6, 500
UNION ALL
SELECT GETDATE() - 7, 600
UNION ALL
SELECT GETDATE() - 8, 700
UNION ALL
SELECT GETDATE() - 9, 800

SELECT
    NEXT VALUE FOR Seq OVER (ORDER BY Data) AS Ordem,
    T1.data,
    T1.Valor,
    ISNULL(Anterior.Valor, 0) AS [Valor Anterior]
FROM @Tabela AS T1
OUTER APPLY
(
    SELECT TOP 1
        T.Valor
    FROM @Tabela AS T
    WHERE T.data < T1.data
) AS Anterior
GO
