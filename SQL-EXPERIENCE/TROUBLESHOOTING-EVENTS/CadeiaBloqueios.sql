/*
    OBJETIVO: Identificar a cadeia de bloqueios (blocking chain) entre sessões
              ativas no SQL Server, mapeando dependências recursivas entre SPIDs
              bloqueadores e bloqueados via DMVs sys.dm_exec_requests e
              sys.dm_exec_sessions.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Cadeia de bloqueios: identifica dependências recursivas
-- entre os "spids" (sessões bloqueadoras e bloqueadas)
-- ============================================================

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
-- percorrendo a árvore de sessões bloqueadoras em profundidade.
Bloqueios
AS
(
    -- Membro âncora: inicializa a cadeia com cada sessão de origem
    SELECT
        CAST(Sessao AS VARCHAR(200)) AS Cadeia
        , Sessao
        , Bloqueadora
        , 1 AS Nivel
    FROM Sessoes

    UNION ALL

    -- Membro recursivo: concatena cada sessão bloqueada à cadeia existente
    SELECT
        CAST(B.Cadeia + ' -> ' + CAST(S.Sessao AS VARCHAR(5)) AS VARCHAR(200))
        , S.Sessao
        , B.Sessao
        , Nivel + 1
    FROM Bloqueios AS B
    INNER JOIN Sessoes AS S
        ON B.Sessao = S.Bloqueadora
)

-- Resultado final: retorna a cadeia de bloqueios mais longa (maior nível de recursão)
SELECT
    Cadeia AS Cadeia_Dependencias_Bloqueadores
FROM Bloqueios
WHERE Nivel = (
    SELECT
        MAX(Nivel)
    FROM Bloqueios
)
ORDER BY
    Cadeia;
