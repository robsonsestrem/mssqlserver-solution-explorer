SELECT
    cp.objtype AS Tipo_Plano,
    cp.usecounts AS Qtde_Execucoes,
    st.text AS Texto_SQL,
    cp.size_in_bytes / 1024 AS TamanhoKB,
    cp.cacheobjtype AS Tipo_Cache
FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st
WHERE cp.cacheobjtype = 'Compiled Plan'
  AND cp.objtype = 'Adhoc'
ORDER BY cp.usecounts ASC, cp.size_in_bytes DESC

