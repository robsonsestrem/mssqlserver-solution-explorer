/*
    OBJETIVO: Coleta do script SQL da sessão bloqueadora raiz em uma cadeia
              de bloqueios, contabilizando bloqueios diretos, indiretos e
              totais, com extração do comando via sys.dm_exec_sql_text e
              sys.dm_exec_connections.
    PROJETO: mssqlserver-solution-explorer
*/

-- ===============================================================
-- Cadeia de bloqueios: identifica a sessão bloqueadora raiz,
-- percorre a árvore de dependências recursivamente e contabiliza
-- bloqueios diretos, indiretos e totais por SPID bloqueador.
-- ===============================================================

-- CTE Âncora (Sessoes): identifica todas as sessões envolvidas em bloqueios.
-- Parte 1: sessões que estão sendo bloqueadas (blocking_session_id > 0).
-- Parte 2: sessões raiz que bloqueiam outras, mas não aparecem como bloqueadas.
;WITH Sessoes (Sessao, Bloqueadora)
AS
(
    SELECT
        Session_Id
        , Blocking_Session_Id
    FROM sys.dm_exec_requests AS R
    WHERE blocking_session_id > 0

    UNION ALL

    SELECT
        Session_Id
        , CAST(0 AS SMALLINT)
    FROM sys.dm_exec_sessions AS S
    WHERE EXISTS (
        SELECT *
        FROM sys.dm_exec_requests AS R
        WHERE S.Session_Id = R.Blocking_Session_Id
    )
    AND NOT EXISTS (
        SELECT *
        FROM sys.dm_exec_requests AS R
        WHERE S.Session_Id = R.Session_Id
    )
),

-- CTE Recursiva (Bloqueios): constrói a cadeia de dependências
-- percorrendo a árvore de sessões bloqueadoras em profundidade,
-- mantendo a referência (Ref) ao SPID raiz da cadeia.
Bloqueios
AS
(
    -- Membro âncora: inicializa a cadeia com cada sessão de origem
    SELECT
        Sessao
        , Bloqueadora
        , Sessao AS Ref
        , 1 AS Nivel
    FROM Sessoes

    UNION ALL

    -- Membro recursivo: propaga a referência raiz (Ref) ao percorrer a cadeia
    SELECT
        S.Sessao
        , B.Sessao
        , B.Ref
        , Nivel + 1
    FROM Bloqueios AS B
    INNER JOIN Sessoes AS S
        ON B.Sessao = S.Bloqueadora
)

-- Resultado final: agrega bloqueios por SPID raiz e extrai o comando
-- SQL da sessão bloqueadora via sys.dm_exec_connections + sys.dm_exec_sql_text
SELECT
    Ref AS Spid_Bloqueador
    , COUNT(DISTINCT R.Session_Id) AS Bloqueios_Diretos
    , COUNT(DISTINCT B.Sessao) - 1 AS Total_Bloqueios
    , COUNT(DISTINCT B.Sessao) - COUNT(DISTINCT R.Session_Id) - 1 AS Bloqueios_Indiretos
    -- Subquery: obtém o sql_handle mais recente da conexão do SPID bloqueador
    -- e extrai o texto do comando em execução
    , (
        SELECT
            text
        FROM sys.dm_exec_sql_text((
            SELECT
                most_recent_sql_handle
            FROM sys.dm_exec_connections
            WHERE session_id = B.Ref
        ))
    ) AS Comando_Bloqueador
FROM Bloqueios AS B
INNER JOIN sys.dm_exec_requests AS R
    ON B.Ref = R.blocking_session_id
GROUP BY
    Ref;
