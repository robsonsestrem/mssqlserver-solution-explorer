/*
    OBJETIVO: Encerrar todas as conexões ativas em um banco de dados específico
              para permitir manutenções (como restore, alteração de configuração
              ou desanexação), excluindo sessões do sistema e a própria sessão.
    PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Fechar conexões para manutenções
-- ============================================================

DECLARE @query VARCHAR(MAX) = '';

SELECT
    @query = COALESCE(@query, ',') + 'KILL ' + CONVERT(VARCHAR, spid) + '; '
FROM
    master.dbo.sysprocesses
WHERE
    dbid = DB_ID('YOUR_DATABASE')               -- Nome do banco de dados
    AND dbid > 4                                -- Não eliminar sessões em databases de sistema
    AND spid <> @@SPID;                         -- Não eliminar a própria sessão

IF (LEN(@query) > 0)
    EXEC(@query);
