/*
 *
    OBJETIVO: Procedure para consulta personalizada do log de erro do SQL Server (arquivo 0),
              permitindo filtros por tempo, data, processo, texto e nome do servidor.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://www.ibm.com/developerworks/community/blogs/fd26864d-cb41-49cf-b719-d89c6b072893/entry/consultando_o_log_de_erro_do_sql_server_usando_t_sql2?lang=en
 *  http://adeilsonrbrito.wordpress.com
 */
-- ============================================================
-- Refatoração estética e documental de ProcedureCustomErrorLog
-- ============================================================
USE YOUR_DATABASE
GO

-- ============================================================
-- Remoção da procedure existente (legado)
-- ============================================================
IF OBJECT_ID('Management.sp_ErrorLog') IS NOT NULL
BEGIN
    DROP PROCEDURE Management.sp_ErrorLog;
END
GO

-- ============================================================
-- Criação da procedure de consulta do Error Log
-- Autor: Adeilson Rocha Brito
-- Notas:
--   a) Todos os parâmetros desta SP são opcionais.
--   b) Esta SP pesquisa apenas o log de erro corrente (arquivo 0).
-- Exemplos:
--   EXEC dbo.sp_ErrorLog 60, NULL, NULL, NULL, 'database';
--   EXEC dbo.sp_ErrorLog 5, NULL, NULL, NULL, NULL, 'NOTEWIN7\SQL2012';
-- ============================================================
CREATE OR ALTER PROCEDURE Management.sp_ErrorLog
(
    @MinutosRetroagir INT = 30
  , @DataInicial DATETIME = NULL
  , @DataFinal DATETIME = NULL
  , @Processo VARCHAR(50) = NULL
  , @Texto VARCHAR(100) = NULL
  , @NomeServidor VARCHAR(128) = NULL
)
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    -- ============================================================
    -- Bloco 01: Tabela em memória para carga do log
    -- ============================================================
    DECLARE @Tmp TABLE
    (
        ID INT IDENTITY(1,1)
      , Data DATETIME
      , Processo VARCHAR(50)
      , Texto VARCHAR(4000)
    );

    -- ============================================================
    -- Bloco 02: Leitura do error log para a tabela em memória
    -- ============================================================
    INSERT INTO @Tmp
    (
        Data
      , Processo
      , Texto
    )
    EXEC sp_readerrorlog;

    -- ============================================================
    -- Bloco 03: Consulta filtrada dos registros do log
    -- ============================================================
    SELECT
        t.ID
      , t.Data
      , t.Processo
      , t.Texto
    FROM @Tmp AS t
    WHERE t.Data =
        CASE
            WHEN @MinutosRetroagir IS NOT NULL THEN DATEADD(MINUTE, -@MinutosRetroagir, GETDATE())
            ELSE t.Data
        END
    AND t.Data = ISNULL(@DataInicial, t.Data)
    AND t.Data = ISNULL(@DataFinal, t.Data)
    AND t.Processo LIKE
        CASE
            WHEN @Processo IS NOT NULL THEN '%' + @Processo + '%'
            ELSE t.Processo
        END
    AND t.Texto LIKE
        CASE
            WHEN @Texto IS NOT NULL THEN '%' + @Texto + '%'
            ELSE t.Texto
        END
    AND SERVERPROPERTY('ServerName') = ISNULL(@NomeServidor, CONVERT(VARCHAR(128), SERVERPROPERTY('ServerName')))
    ORDER BY
        t.ID DESC;
END
GO
