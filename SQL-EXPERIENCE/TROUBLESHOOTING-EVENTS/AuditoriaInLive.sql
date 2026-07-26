/*
    OBJETIVO: Auditoria de sessões ativas no SQL Server (In Live), identificando
              requisições em execução, tipos de espera e contexto da sessão.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Auditoria In Live: monitora requisições ativas no SQL Server,
-- excluindo sessões de sistema e a própria sessão atual
-- ============================================================

SELECT
    session_Id AS [Spid]                                    -- ID da sessão do SQL Server
    , sp.kpid                                               -- ID do thread do Windows
    , sp.ecid                                               -- Identifica subthreads que operam em nome de um único processo
    , DB_NAME(sp.dbid) AS [Database]                        -- Nome do banco de dados da sessão
    , nt_username AS [User]                                 -- Usuário de rede da sessão
    , er.status AS [Status]                                 -- Status da requisição (running, sleeping, etc.)
    , wait_type AS [Wait]                                   -- Tipo de espera da requisição
    -- Extrai o texto individual da instrução em execução usando offsets de statement
    , SUBSTRING(
        qt.text,
        er.statement_start_offset / 2,
        (
            CASE
                WHEN er.statement_end_offset = -1
                    THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
                ELSE er.statement_end_offset
            END - er.statement_start_offset
        ) / 2
    ) AS [Individual Query]                                 -- Query individual em execução
    , qt.text AS [Parent Query]                             -- Query completa (batch pai)
    , program_name AS [Program]                             -- Nome da aplicação cliente
    , Hostname                                              -- Nome do host cliente
    , nt_domain                                             -- Domínio NT do usuário
    , start_time                                            -- Horário de início da requisição
FROM sys.dm_exec_requests AS er
INNER JOIN sys.sysprocesses AS sp
    ON er.session_id = sp.spid
CROSS APPLY sys.dm_exec_sql_text(er.sql_handle) AS qt
WHERE session_Id > 50                                       -- Ignora SPIDs de sistema
    AND session_Id NOT IN (@@SPID)                          -- Ignora a própria sessão atual
ORDER BY 1, 2;
GO
