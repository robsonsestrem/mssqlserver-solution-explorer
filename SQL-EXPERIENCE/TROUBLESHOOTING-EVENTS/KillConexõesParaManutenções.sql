-----------------------------------------------------------------------------------------------------------
--						Fechar conexões para manutenções
-----------------------------------------------------------------------------------------------------------
DECLARE @query VARCHAR(MAX) = ''

SELECT
    @query = COALESCE(@query, ',') + 'KILL ' + CONVERT(VARCHAR, spid) + '; '
FROM
    master..sysprocesses
WHERE
    dbid = DB_ID('YOUR_DATABASE') -- Nome do database
    AND dbid > 4 -- Não eliminar sessões em databases de sistema
    AND spid <> @@SPID -- Não eliminar a sua própria sessão

IF (LEN(@query) > 0)
    EXEC(@query)


