/*
    OBJETIVO: Consultar e filtrar o error log do SQL Server utilizando sp_readerrorlog,
              incluindo lógica para varrer múltiplos arquivos de log históricos e aplicar
              filtros de exclusão para mensagens irrelevantes.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- SEÇÃO 1: Consulta simples em variável de tabela
-- ============================================================

-- Declaração da variável de tabela para armazenar os dados do error log
DECLARE @logs TABLE (
    data DATETIME,
    ProcessInfo VARCHAR(50),
    Text VARCHAR(4000)
);

-- Inserção dos dados do error log atual na variável de tabela
INSERT INTO @logs
EXEC sys.sp_readerrorlog 
    @p1 = 0,    -- Valor inteiro do log (0 = atual, 1 = anterior, etc.)
    @p2 = NULL, -- 1 ou NULL = Log de Erro, 2 = Log do SQL Agent
    @p3 = N'',  -- Primeira string para busca
    @p4 = N'';  -- Segunda string para refinar a busca

-- Seleção dos dados com filtros de data e exclusão de mensagens irrelevantes
SELECT 
    l.data
    , l.ProcessInfo
    , l.Text
FROM @logs AS l
WHERE l.data >= '20250413 00:00:00.000'
    AND l.data <= '20250501 18:00:00.000'
    AND l.[Text] NOT LIKE '%Login failed%'
    AND l.Text NOT LIKE '%Error: 18456%'
    AND l.Text NOT LIKE '%Error: 17836%'
    AND l.Text NOT LIKE '%Error: 17832%'
    AND l.Text NOT LIKE '%Error: 17806%'
    AND l.Text NOT LIKE '%Error: 18452%'
    AND l.Text NOT LIKE '%Error: 17828%'
ORDER BY l.data DESC;

-- Exemplo com mais parâmetros e ordenação
-- EXEC master.dbo.xp_readerrorlog 0, 1, N'backup', N'failed', NULL, NULL, N'asc';

-- ============================================================
-- SEÇÃO 2: Varredura de múltiplos arquivos de log com loop
-- ============================================================

-- Criação da tabela temporária para consolidar dados de múltiplos arquivos de log
IF OBJECT_ID('tempdb..#logs') IS NOT NULL
BEGIN
    DROP TABLE #logs;
END;

CREATE TABLE #logs (
    RowID INT IDENTITY(1, 1) PRIMARY KEY,
    EntryTime DATETIME,
    ProcessInfo VARCHAR(50),
    Text NVARCHAR(MAX)
);

-- Criação de índice para otimizar consultas por data
CREATE NONCLUSTERED INDEX IX_logs_EntryTime ON #logs(EntryTime);

-- Declaração das variáveis de controle para o loop de varredura
DECLARE @logIndex INT = 0;
DECLARE @hasData BIT = 1;
DECLARE @endDate DATETIME = GETDATE();
DECLARE @startDate DATETIME = DATEADD(HOUR, -24, @endDate);

-- Loop para varrer múltiplos arquivos de log até encontrar dados fora do período
WHILE @hasData = 1
BEGIN
    -- Criação da tabela temporária para processar o arquivo de log atual
    CREATE TABLE #tempLogs (
        EntryTime DATETIME,
        ProcessInfo VARCHAR(50),
        Text NVARCHAR(MAX)
    );

    BEGIN TRY
        -- Inserção dos dados do arquivo de log atual na tabela temporária
        INSERT INTO #tempLogs
        EXEC sys.sp_readerrorlog 
            @p1 = @logIndex,
            @p2 = NULL,
            @p3 = N'',
            @p4 = N'';

        -- Verifica se existem dados dentro do período desejado
        IF EXISTS (
            SELECT 1 
            FROM #tempLogs 
            WHERE EntryTime BETWEEN @startDate AND @endDate
        )
        BEGIN
            -- Remoção de mensagens de login failed e erros específicos
            DELETE FROM #tempLogs
            WHERE [Text] LIKE '%Login failed%'
                OR [Text] LIKE '%Error: 18456%';

            -- Filtragem de mensagens irrelevantes mantendo apenas logs com palavras-chave de erro
            DELETE FROM #tempLogs
            WHERE (
                [Text] NOT LIKE '%err%'
                AND [Text] NOT LIKE '%warn%'
                AND [Text] NOT LIKE '%kill%'
                AND [Text] NOT LIKE '%dead%'
                AND [Text] NOT LIKE '%cannot%'
                AND [Text] NOT LIKE '%could%'
                AND [Text] NOT LIKE '%fail%'
                AND [Text] NOT LIKE '%not%'
                AND [Text] NOT LIKE '%stop%'
                AND [Text] NOT LIKE '%terminate%'
                AND [Text] NOT LIKE '%bypass%'
                AND [Text] NOT LIKE '%roll%'
                AND [Text] NOT LIKE '%truncate%'
                AND [Text] NOT LIKE '%upgrade%'
                AND [Text] NOT LIKE '%victim%'
                AND [Text] NOT LIKE '%recover%'
                AND [Text] NOT LIKE '%IO requests taking longer than%'
                AND [Text] NOT LIKE '%adjustment%'
                AND [Text] NOT LIKE '%disk%'
                AND [Text] NOT LIKE '%memory%'
                AND [Text] NOT LIKE '%processor%'
                AND [Text] NOT LIKE '%socket%'
            )
            OR [Text] LIKE '%The Service Broker endpoint is in disabled or stopped state%';

            -- Inserção dos dados filtrados na tabela consolidada
            INSERT INTO #logs
            SELECT * 
            FROM #tempLogs;

            -- Incrementa o índice para processar o próximo arquivo de log
            SET @logIndex += 1;
        END
        ELSE
        BEGIN
            -- Para o loop quando não houver mais dados no período
            SET @hasData = 0;
        END;
    END TRY
    BEGIN CATCH
        -- Em caso de erro, para o loop
        SET @hasData = 0;
    END CATCH;

    -- Remoção da tabela temporária do arquivo atual
    DROP TABLE #tempLogs;
END;

-- Seleção final dos dados consolidados de todos os arquivos de log
SELECT 
    EntryTime,
    ProcessInfo,
    Text
FROM #logs
WHERE EntryTime BETWEEN @startDate AND @endDate
ORDER BY EntryTime DESC;
