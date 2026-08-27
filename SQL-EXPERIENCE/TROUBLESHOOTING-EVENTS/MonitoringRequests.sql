/*
	OBJETIVO: Monitorar processos ativos no SQL Server, exibindo informações de CPU, I/O,
			  bloqueios, memória cache e outros indicadores de performance. Inclui também
			  exemplos de conversão de tempo e uso do DBCC INPUTBUFFER para depuração.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Requisições com maiores processos cumulativos na CPU
-- ============================================================
USE master;
GO

SELECT
      s.spid                                                                          AS spid          -- ID da sessão do SQL Server
    , s.status                                                                        AS status
    , s.open_tran                                                                     AS open_tran
    , s.request_id                                                                    AS request_id    -- ID da solicitação
    , s.blocked                                                                       AS blocked       -- ID da sessão de quem bloqueia
    , s.waittime                                                                      AS temp          -- tempo de espera atual em milissegundos
    , DB_NAME(s.dbid)                                                                 AS DB            -- ID do banco de dados usado atualmente pelo processo
    -- , CONVERT(TIME, DATEADD(MILLISECOND, CAST(s.cpu AS BIGINT) + 86400000, 0), 114) AS CPU_Time     -- sem conversão dava overflow (comentário original mantido)
    , CAST(s.cpu AS BIGINT)                                                           AS CPU           -- tempo de CPU cumulativo para o processo
    , s.physical_io                                                                   AS physical_io   -- IO cumulativas para o processo em disco
    , CAST(s.memusage AS BIGINT)                                                      AS Paginas_Cache -- número de páginas no cache de procedimento que estão atualmente alocadas para este processo.
    -- Um número negativo indica que o processo está liberando memória alocada por outro processo (comentário original mantido)
    , s.program_name                                                                  AS program_name  -- aplicativo
    , s.hostname                                                                      AS hostname      -- PC que fez a requisição
    , s.loginame                                                                      AS loginame      -- usuário
    , s.hostprocess                                                                   AS hostprocess   -- número de ID do processo da estação de trabalho
FROM master..sysprocesses                                                             AS s
WHERE
      -- status = 'sleeping'                                                          -- Filtro opcional comentado
      -- AND open_tran = 0                                                           -- Filtro opcional comentado
      DB_NAME(s.dbid) IN ('d_YOUR_OBJECT_admYOUR_OBJECT')
      -- AND (s.cpu > 0 OR s.physical_io > 0)                                        -- Filtro opcional comentado
      -- AND s.loginame = 'sa'                                                       -- Filtro opcional comentado
      -- AND s.hostname IN ('cti-000640')                                            -- Filtro opcional comentado
      -- AND DB_NAME(s.dbid) = 'guru5'                                               -- Filtro opcional comentado
      -- AND s.spid = 227                                                            -- Filtro opcional comentado
ORDER BY
      s.status ASC;

-- ================================================================================================
-- DBCC INPUTBUFFER - Exibe a última instrução enviada de um cliente a uma instância do SQL Server
-- ================================================================================================
-- O parâmetro é o spid que é a sessão do SQL Server
-- Retornará três colunas e na EventInfo terá o script da requisição
--
-- Tipos de evento:
--   - Evento RPC: EventInfo contém apenas o nome do procedimento
--   - Evento Language: são exibidos apenas os primeiros 4000 caracteres do evento
--   - No Event: quando não for detectado nenhum último evento
DBCC INPUTBUFFER(266);

-- ================================================================================================
-- Conversão de campos do tipo int para milissegundos / tempo
-- ================================================================================================
-- Converter 5.874.502 Milissegundos para tempo
SELECT CONVERT(TIME, DATEADD(MILLISECOND, 5874502 + 86400000, 0), 114) AS Tempo_Milissegundos;

-- Converter 587 Segundos para tempo
SELECT CONVERT(TIME, DATEADD(SECOND, 587 + 86400000, 0), 114) AS Tempo_Segundos;

-- Converter 457 Minutos para tempo
SELECT CONVERT(TIME, DATEADD(MINUTE, 457 + 86400000, 0), 114) AS Tempo_Minutos;

-- Converter 5.874.502 Milissegundos para string (formato HH:MI:SS:mmm)
SELECT CONVERT(VARCHAR(12), DATEADD(MILLISECOND, 5874502 + 86400000, 0), 114) AS Tempo_String;

-- Exemplo de uso com a coluna 'waittime':
-- CONVERT(TIME, DATEADD(MILLISECOND, waittime + 86400000, 0), 114) AS temp,

-- ================================================================================================
-- Coluna status (nchar(30)) - Status do ID do processo
-- ================================================================================================
-- Valores possíveis:
--   dormant   : SQL Server está redefinindo a sessão (inativo)
--   running   : a sessão está executando um ou mais lotes (com MARS, pode executar vários)
--   Background: a sessão está executando uma tarefa em segundo plano (ex: detecção de deadlock)
--   rollback  : a sessão tem uma reversão de transação em processo
--   pending   : a sessão está aguardando um thread de trabalho se tornar disponível
--   runnable  : a tarefa está na fila executável de um agendador aguardando quantum de tempo
--   spinloop  : a tarefa está esperando um spinlock ficar livre
--   suspended : a sessão está aguardando um evento (ex: I/O) para concluir
--   sleeping  : a sessão está aguardando, em processo de retorno
