/*
    OBJETIVO: Criar e gerenciar um trace personalizado para monitorar
              eventos de RPC:Completed e SQL:BatchCompleted, com filtros
              por texto, hostname, program name e loginname, além de
              consultar os dados coletados e finalizar o trace adequadamente.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Criação do trace
-- ============================================================

DECLARE @rc INT;
DECLARE @TraceID INT;
DECLARE @maxfilesize BIGINT;

SET @maxfilesize = 10000; -- em megabytes

EXEC @rc = sp_trace_create
    @TraceID OUTPUT
  , 0
  , N'C:\DBACravil\Trace\TraceFilter'
  , @maxfilesize
  , NULL;

IF (@rc != 0)
    GOTO error;

-- ============================================================
-- Configuração dos eventos
-- ============================================================

DECLARE @on BIT;
SET @on = 1;

-- Evento 10: RPC:Completed
EXEC sp_trace_setevent @TraceID, 10, 1, @on;
EXEC sp_trace_setevent @TraceID, 10, 6, @on;
EXEC sp_trace_setevent @TraceID, 10, 8, @on;
EXEC sp_trace_setevent @TraceID, 10, 10, @on;
EXEC sp_trace_setevent @TraceID, 10, 11, @on;
EXEC sp_trace_setevent @TraceID, 10, 12, @on;
EXEC sp_trace_setevent @TraceID, 10, 13, @on;
EXEC sp_trace_setevent @TraceID, 10, 14, @on;
EXEC sp_trace_setevent @TraceID, 10, 15, @on;
EXEC sp_trace_setevent @TraceID, 10, 16, @on;
EXEC sp_trace_setevent @TraceID, 10, 17, @on;
EXEC sp_trace_setevent @TraceID, 10, 18, @on;
EXEC sp_trace_setevent @TraceID, 10, 26, @on;
EXEC sp_trace_setevent @TraceID, 10, 35, @on;
EXEC sp_trace_setevent @TraceID, 10, 40, @on;
EXEC sp_trace_setevent @TraceID, 10, 48, @on;
EXEC sp_trace_setevent @TraceID, 10, 64, @on;

-- Evento 12: SQL:BatchCompleted
EXEC sp_trace_setevent @TraceID, 12, 1, @on;
EXEC sp_trace_setevent @TraceID, 12, 6, @on;
EXEC sp_trace_setevent @TraceID, 12, 8, @on;
EXEC sp_trace_setevent @TraceID, 12, 10, @on;
EXEC sp_trace_setevent @TraceID, 12, 11, @on;
EXEC sp_trace_setevent @TraceID, 12, 12, @on;
EXEC sp_trace_setevent @TraceID, 12, 13, @on;
EXEC sp_trace_setevent @TraceID, 12, 14, @on;
EXEC sp_trace_setevent @TraceID, 12, 15, @on;
EXEC sp_trace_setevent @TraceID, 12, 16, @on;
EXEC sp_trace_setevent @TraceID, 12, 17, @on;
EXEC sp_trace_setevent @TraceID, 12, 18, @on;
EXEC sp_trace_setevent @TraceID, 12, 26, @on;
EXEC sp_trace_setevent @TraceID, 12, 35, @on;
EXEC sp_trace_setevent @TraceID, 12, 40, @on;
EXEC sp_trace_setevent @TraceID, 12, 48, @on;
EXEC sp_trace_setevent @TraceID, 12, 64, @on;

-- ============================================================
-- Configuração dos filtros
-- ============================================================

DECLARE @intfilter INT;
DECLARE @bigintfilter BIGINT;

-- Filtro 1: TextData LIKE
EXEC sp_trace_setfilter @TraceID, 1, 0, 6, N'%movestoque%';
-- Filtro 8: HostName LIKE
EXEC sp_trace_setfilter @TraceID, 8, 0, 6, N'cti-000492';
-- Filtro 10: ProgramName LIKE
EXEC sp_trace_setfilter @TraceID, 10, 0, 6, N'%net%';
-- Filtro 10: ProgramName NOT LIKE
EXEC sp_trace_setfilter @TraceID, 10, 0, 7, N'%Profiler%';
-- Filtro 11: LoginName LIKE
EXEC sp_trace_setfilter @TraceID, 11, 0, 6, N'cravil\ti-04';

-- Filtro por duração (descomentar se necessário)
-- SET @bigintfilter = 10000000; -- 10 segundos
-- EXEC sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter;

-- ============================================================
-- Iniciar o trace
-- ============================================================

EXEC sp_trace_setstatus @TraceID, 1;

GOTO finish;

error:
    SELECT ErrorCode = @rc;

finish:
GO


-- ============================================================
-- Análise dos dados coletados
-- ============================================================

SELECT
    TextData
  , NTUserName
  , HostName
  , ApplicationName
  , LoginName
  , SPID
  , CAST(Duration / 1000 / 1000.00 AS NUMERIC(15, 2))                       AS DurationSegundos
  , Duration                                                                AS DurationMicrossegundos
  , StartTime
  , EndTime
  , Reads
  , Writes
  , CPU
  , ServerName
  , DatabaseName
  , RowCounts
  , SessionLoginName
FROM
    ::fn_trace_gettable(N'C:\DBACravil\Trace\TraceFilter.trc', DEFAULT)
WHERE
    TextData LIKE '%produtos%'
-- ORDER BY StartTime;


-- ============================================================
-- Finalizar e fechar o trace (antes de excluir o arquivo)
-- ============================================================

DECLARE @Trace_Id INT;

SELECT @Trace_Id = TraceId
FROM
    fn_trace_getinfo(0)
WHERE
    CAST(value AS VARCHAR(100)) = N'C:\DBACravil\Trace\TraceFilter.trc';

-- Interrompe o rastreamento especificado
EXEC sp_trace_setstatus @TraceID = @Trace_Id, @status = 0;

-- Fecha o rastreamento especificado e exclui sua definição do servidor
EXEC sp_trace_setstatus @TraceID = @Trace_Id, @status = 2;
