/*
 *
    OBJETIVO: Criação de rotina de rastreamento (SQL Trace) para captura de consultas lentas
              em background no servidor, incluindo tabela de armazenamento, procedure de criação
              do trace, e steps de Job para rotação diária do arquivo de trace.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS:
 *  Documentação oficial: sp_trace_create, sp_trace_setevent, sp_trace_setfilter, sp_trace_setstatus
 */
-- ============================================================
-- Rastreamento Diário de Consultas Lentas (SQL Trace)
-- ============================================================

-- ============================================================
-- Criação da tabela de armazenamento do log de queries demoradas
-- Deve-se escolher a database adequada do ambiente para armazenar essa tabela.
-- Índice clustered criado para efetuar buscas pela data de execução da query.
-- ============================================================
USE [DBA_PerformanceHub]
GO

CREATE TABLE [Management].[TraceSlowQuery]
(
      [TextData]         VARCHAR(MAX) NULL
    , [NTUserName]       VARCHAR(128) NULL
    , [HostName]         VARCHAR(128) NULL
    , [ApplicationName]  VARCHAR(128) NULL
    , [LoginName]        VARCHAR(128) NULL
    , [SPID]             INT NULL
    , [Duration]         NUMERIC(15, 2) NULL      -- no insert já fica em segundos
    , [StartTime]        DATETIME NULL
    , [EndTime]          DATETIME NULL
    , [Reads]            BIGINT NULL
    , [Writes]           BIGINT NULL
    , [CPU]              BIGINT NULL
    , [ServerName]       VARCHAR(128) NULL
    , [DataBaseName]     VARCHAR(128) NULL
    , [RowCounts]        BIGINT NULL
    , [SessionLoginName] VARCHAR(128) NULL
)
ON [PRIMARY]
GO

-- ============================================================
-- Índice clustered para busca por data de execução
-- ============================================================
CREATE CLUSTERED INDEX [SK01_Traces]
    ON [Management].[TraceSlowQuery] ([StartTime])
    WITH (FILLFACTOR = 95)
GO

-- Ajustes históricos de tipo de dados (estouro para INT)
-- ALTER TABLE [TraceSlowQuery] ALTER COLUMN [Reads] BIGINT;
-- ALTER TABLE [TraceSlowQuery] ALTER COLUMN [Writes] BIGINT;
-- ALTER TABLE [TraceSlowQuery] ALTER COLUMN [CPU] BIGINT;
-- ALTER TABLE [TraceSlowQuery] ALTER COLUMN [RowCounts] BIGINT;

-- ============================================================
-- Procedure para criação do arquivo de trace em background
-- sp_trace_create: especifica o caminho de armazenamento
-- sp_trace_setevent: define os eventos coletados (IDs 10 e 12)
-- sp_trace_setfilter: filtro na coluna 13 (Duration) >= 20 segundos
-- ============================================================
USE [DBA_PerformanceHub]
GO

CREATE OR ALTER PROCEDURE [Management].[sp_CreateTrace]
    WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @rc            INT
          , @TraceID       INT
          , @maxfilesize   BIGINT
          , @on            BIT
          , @intfilter     INT
          , @bigintfilter  BIGINT

    BEGIN TRY
        BEGIN TRANSACTION

        SELECT
            @on            = 1
          , @maxfilesize   = 100000

        -- ============================================================
        -- Criação do trace (nome gerado: Querys_Demoradas)
        -- ============================================================
        EXEC @rc = sp_trace_create
            @TraceID       OUTPUT
          , 0
          , N'C:\Data\Trace\Querys_Demoradas'
          , @maxfilesize
          , NULL

        IF (@rc <> 0)
            GOTO error

        -- ============================================================
        -- Eventos coletados para RPC:Completed (ID 10)
        -- ============================================================
        EXEC sp_trace_setevent @TraceID, 10, 1, @on
        EXEC sp_trace_setevent @TraceID, 10, 6, @on
        EXEC sp_trace_setevent @TraceID, 10, 8, @on
        EXEC sp_trace_setevent @TraceID, 10, 10, @on
        EXEC sp_trace_setevent @TraceID, 10, 11, @on
        EXEC sp_trace_setevent @TraceID, 10, 12, @on
        EXEC sp_trace_setevent @TraceID, 10, 13, @on
        EXEC sp_trace_setevent @TraceID, 10, 14, @on
        EXEC sp_trace_setevent @TraceID, 10, 15, @on
        EXEC sp_trace_setevent @TraceID, 10, 16, @on
        EXEC sp_trace_setevent @TraceID, 10, 17, @on
        EXEC sp_trace_setevent @TraceID, 10, 18, @on
        EXEC sp_trace_setevent @TraceID, 10, 26, @on
        EXEC sp_trace_setevent @TraceID, 10, 35, @on
        EXEC sp_trace_setevent @TraceID, 10, 40, @on
        EXEC sp_trace_setevent @TraceID, 10, 48, @on
        EXEC sp_trace_setevent @TraceID, 10, 64, @on

        -- ============================================================
        -- Eventos coletados para SQL:BatchCompleted (ID 12)
        -- ============================================================
        EXEC sp_trace_setevent @TraceID, 12, 1, @on
        EXEC sp_trace_setevent @TraceID, 12, 6, @on
        EXEC sp_trace_setevent @TraceID, 12, 8, @on
        EXEC sp_trace_setevent @TraceID, 12, 10, @on
        EXEC sp_trace_setevent @TraceID, 12, 11, @on
        EXEC sp_trace_setevent @TraceID, 12, 12, @on
        EXEC sp_trace_setevent @TraceID, 12, 13, @on
        EXEC sp_trace_setevent @TraceID, 12, 14, @on
        EXEC sp_trace_setevent @TraceID, 12, 15, @on
        EXEC sp_trace_setevent @TraceID, 12, 16, @on
        EXEC sp_trace_setevent @TraceID, 12, 17, @on
        EXEC sp_trace_setevent @TraceID, 12, 18, @on
        EXEC sp_trace_setevent @TraceID, 12, 26, @on
        EXEC sp_trace_setevent @TraceID, 12, 35, @on
        EXEC sp_trace_setevent @TraceID, 12, 40, @on
        EXEC sp_trace_setevent @TraceID, 12, 48, @on
        EXEC sp_trace_setevent @TraceID, 12, 64, @on

        -- ============================================================
        -- Filtro de duração: >= 20 segundos (20.000.000 microssegundos)
        -- ============================================================
        SET @bigintfilter = 20000000
        EXEC sp_trace_setfilter
            @TraceID
          , 13
          , 0
          , 4
          , @bigintfilter

        -- ============================================================
        -- Inicia o trace
        -- ============================================================
        EXEC sp_trace_setstatus
            @TraceID
          , 1

        GOTO finish

        error:
            SELECT [ErrorCode] = @rc

        finish:
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject    VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na Job "TI_CapturaRequisicoesLentas"'
        SET @recipients = 'robson@cravil.com.br'

        SET @corpoFalha = '
        <html>
        <head>
        <meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
        </head>
        <body>
        <div align="left">'

        SELECT @corpoFalha = @corpoFalha + '
        <table border="0" cellpadding="0" cellspacing="0" width="402" style="border-collapse: collapse; table-layout: fixed; width: 1000pt; font-family: Arial; font-size: 14px;">
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <b>Falha na Procedure [sp_CreateTrace]:</b><br>
                </td>
            </tr>
            <tr height="20" style="height: 20.0pt;">
                <td height="20" colspan="7" style="height: 20.0pt; text-align: left;">
                    <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                    <br><br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                    <br><br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                </td>
            </tr>
        </table>'

        SELECT @corpoFalha = @corpoFalha + '
        </div>
        </body>
        </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'Cravil_ERP'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'
    END CATCH

    SET NOCOUNT OFF
END
GO

-- ============================================================
-- Execução da procedure para criar o trace
-- ============================================================
USE [DBA_PerformanceHub]
GO

EXEC [Management].[sp_CreateTrace]
GO

-- ============================================================
-- Conferência do trace criado via fn_trace_getinfo
-- ============================================================
SELECT *
FROM ::fn_trace_getinfo(DEFAULT)
WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc'
GO

-- ============================================================
-- Conferência de todos os dados armazenados no arquivo de trace
-- ============================================================
SELECT
      [TextData]
    , [NTUserName]
    , [HostName]
    , [ApplicationName]
    , [LoginName]
    , [SPID]
    , CAST([Duration] / 1000 / 1000.00 AS NUMERIC(15, 2)) AS [DurationSegundos]
    , [Duration] AS [DurationMicrossegundos]
    , [StartTime]
    , [EndTime]
    , [Reads]
    , [Writes]
    , [CPU]
    , [ServerName]
    , [DatabaseName]
    , [RowCounts]
    , [SessionLoginName]
FROM ::fn_trace_gettable(N'C:\Data\Trace\Querys_Demoradas.trc', DEFAULT)
WHERE [Duration] IS NOT NULL
ORDER BY
    [StartTime]
GO

-- ============================================================
-- JOB: DBA - Trace Querys Demoradas
-- STEP 1: Parar o trace momentaneamente e enviar resultado para tabela de log
-- Observação: problema conhecido quando existe mais de um valor nulo no campo VALUE do fn_trace_getinfo
-- ============================================================
DECLARE @Trace_Id INT

-- ============================================================
-- Validação de existência do trace com múltiplos cenários de valores nulos
-- ============================================================
IF (
    (SELECT COUNT(*) FROM ::fn_trace_getinfo(DEFAULT) WHERE [value] IS NULL) > 1
    AND (SELECT COUNT([value]) FROM ::fn_trace_getinfo(DEFAULT) WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc') = 0
)
BEGIN
    PRINT 'Sem definição'
    RETURN
END
ELSE IF (
    (SELECT COUNT(*) FROM ::fn_trace_getinfo(DEFAULT) WHERE [value] IS NULL) > 1
    AND (SELECT COUNT([value]) FROM ::fn_trace_getinfo(DEFAULT) WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc') = 1
)
BEGIN
    PRINT 'Tem mais de um nulo mas tem o trace'
    SET @Trace_Id = (
        SELECT [traceid]
        FROM ::fn_trace_getinfo(DEFAULT)
        WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc'
    )
END
ELSE IF (
    (SELECT COUNT(*) FROM ::fn_trace_getinfo(DEFAULT) WHERE [value] IS NULL) = 1
    AND (SELECT COUNT([value]) FROM ::fn_trace_getinfo(DEFAULT) WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc') = 1
)
BEGIN
    PRINT 'Tem nulo e tem nome do trace'
    SET @Trace_Id = (
        SELECT [traceid]
        FROM ::fn_trace_getinfo(DEFAULT)
        WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc'
    )
END
ELSE IF (
    (SELECT COUNT(*) FROM ::fn_trace_getinfo(DEFAULT) WHERE [value] IS NULL) = 1
    AND (SELECT COUNT([value]) FROM ::fn_trace_getinfo(DEFAULT) WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc') = 0
)
BEGIN
    PRINT 'Tem nulo e ta sem nome do trace'
    SET @Trace_Id = (
        SELECT [traceid]
        FROM ::fn_trace_getinfo(DEFAULT)
        WHERE [value] IS NULL
    )
END
ELSE IF (
    (SELECT COUNT(*) FROM ::fn_trace_getinfo(DEFAULT) WHERE [value] IS NULL) = 0
    AND (SELECT COUNT([value]) FROM ::fn_trace_getinfo(DEFAULT) WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc') = 1
)
BEGIN
    PRINT 'Não tem nulo e tem nome do trace'
    SET @Trace_Id = (
        SELECT [traceid]
        FROM ::fn_trace_getinfo(DEFAULT)
        WHERE CAST([value] AS VARCHAR(100)) = N'C:\Data\Trace\Querys_Demoradas.trc'
    )
END

-- ============================================================
-- Interrompe o rastreamento especificado
-- ============================================================
EXEC sp_trace_setstatus
    @traceid = @Trace_Id
  , @status  = 0

-- ============================================================
-- Fecha o rastreamento especificado e exclui sua definição do servidor
-- ============================================================
EXEC sp_trace_setstatus
    @traceid = @Trace_Id
  , @status  = 2

-- ============================================================
-- Inserção dos dados do trace na tabela de histórico
-- ============================================================
INSERT INTO [Management].[TraceSlowQuery]
(
      [TextData]
    , [NTUserName]
    , [HostName]
    , [ApplicationName]
    , [LoginName]
    , [SPID]
    , [Duration]
    , [StartTime]
    , [EndTime]
    , [Reads]
    , [Writes]
    , [CPU]
    , [ServerName]
    , [DatabaseName]
    , [RowCounts]
    , [SessionLoginName]
)
SELECT
      [TextData]
    , [NTUserName]
    , [HostName]
    , [ApplicationName]
    , [LoginName]
    , [SPID]
    , CAST([Duration] / 1000 / 1000.00 AS NUMERIC(15, 2)) AS [Duration]
    , [StartTime]
    , [EndTime]
    , [Reads]
    , [Writes]
    , [CPU]
    , [ServerName]
    , [DatabaseName]
    , [RowCounts]
    , [SessionLoginName]
FROM ::fn_trace_gettable(N'C:\Data\Trace\Querys_Demoradas.trc', DEFAULT)
WHERE [Duration] IS NOT NULL
ORDER BY
    [StartTime]

-- ============================================================
-- STEP 2: Excluir o arquivo de trace para que um novo seja criado
-- Comando: del C:\Trace\Querys_Demoradas.trc /Q
-- ============================================================

-- ============================================================
-- STEP 3: Recriar o trace (similar ao STEP 1)
-- ============================================================
USE [DBA_PerformanceHub]
GO

EXEC [Management].[sp_CreateTrace]
GO

-- ============================================================
-- DOCUMENTAÇÃO DAS PROCEDURES DE TRACE
-- ============================================================

-- sp_trace_create:
-- Cria um trace. Funciona como o botão "New Trace" do SQL Profiler.
-- Ao ser executada, uma variável OUTPUT é retornada com o ID interno do trace.

-- sp_trace_setevent:
-- Funciona como o EventSelection do SQL Profiler.
-- Executando-a e informando o traceid retornado na execução da sp_trace_create,
-- podemos configurar o que coletaremos. Devemos informar o ID do trace, o ID do evento,
-- o ID das informações que serão retornadas e 0 ou 1 para ativar/desativar aquele registro.
-- Exemplo: EXEC sp_trace_setevent @TraceID, 10, 1, 1 (TextData do RPC:Completed)

-- sp_trace_setfilter:
-- Funciona como a seleção de filtros do SQL Profiler.
-- Informamos o ID do trace, o ID do filtro e o parâmetro de seleção.
-- Exemplo: EXEC sp_trace_setfilter @TraceID, 13, 0, 4, '500000'
-- Adiciona filtro de duração (ID 13) >= (ID 4) 0,5 segundo (500000 microssegundos).

-- sp_trace_setstatus:
-- Funciona como o botão "Run" do SQL Profiler.
-- Informando o ID do trace e opção 1, inicia a coleta.
-- Executando com opção 0, o trace é finalizado.
-- Exemplos:
--   EXEC sp_trace_setstatus @TraceID, 1  -- Inicia o trace
--   EXEC sp_trace_setstatus @TraceID, 0  -- Para o trace

-- ============================================================
-- Retenção dos dados
-- ============================================================
USE YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE Management.sp_DeleteSlowQuery
(
    @qtdadeManterDias INT = 365 -- Quantidade de dias para manter
)
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY

        BEGIN TRANSACTION

        -- ============================================================
        -- Bloco 06.1: Busca quantidade de dias distintos registrados
        -- ============================================================
        DECLARE @qtdadeDias INT
              , @dataMin    DATE

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Registros)
            FROM
            (
                SELECT COUNT(*) AS [Registros]
                FROM [YOUR_DATABASE].[Management].TraceSlowQuery AS t1
                GROUP BY CAST(t1.StartTime AS DATE)
            ) AS x
        )

        -- ============================================================
        -- Bloco 06.2: Loop para tratamento e exclusão dos dias excedentes
        -- ============================================================
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT CAST(DATEADD(DAY, 1, ((SELECT MIN(t1.StartTime) FROM [YOUR_DATABASE].[Management].TraceSlowQuery AS t1))) AS DATE)
            )

            DELETE FROM [YOUR_DATABASE].[Management].TraceSlowQuery
            WHERE StartTime < @dataMin

            SET @qtdadeDias = @qtdadeDias - 1
        END

        COMMIT TRANSACTION

    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject    VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content=text/html; charset=windows-1252>
            </head>
            <body>
            <div align=left>'

        SELECT @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteSlowQuery]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'

    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

END
GO
