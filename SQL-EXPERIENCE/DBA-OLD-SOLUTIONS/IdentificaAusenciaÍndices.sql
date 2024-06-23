---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Referências
-- https://www.dirceuresende.com/blog/entendendo-o-funcionamento-dos-indices-no-sql-server/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    mid.statement,
    migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 ) * 
	( migs.user_seeks + migs.user_scans )																		AS improvement_measure,
    OBJECT_NAME(mid.object_id)																					AS TableName,
	--
    'CREATE INDEX [missing_index_' + CONVERT (VARCHAR, mig.index_group_handle) + '_' + 
	CONVERT (VARCHAR, mid.index_handle) + '_' + LEFT(PARSENAME(mid.statement, 1), 32) + ']' + 
	' ON ' + mid.statement + ' (' + ISNULL(mid.equality_columns, '') + 
	CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END + 
	ISNULL(mid.inequality_columns, '') + ')' + ISNULL(' INCLUDE (' + mid.included_columns + ')', '')			AS create_index_statement,
	--
    migs.*,
    mid.database_id,
    mid.[object_id]
FROM
    sys.dm_db_missing_index_groups mig
    INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
    INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE
    migs.avg_total_user_cost * ( migs.avg_user_impact / 100.0 ) * ( migs.user_seeks + migs.user_scans ) > 10
ORDER BY
    migs.avg_total_user_cost * migs.avg_user_impact * ( migs.user_seeks + migs.user_scans ) DESC


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Ajudando a identificar o melhor candidato a índice clustered
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
    TableName = OBJECT_NAME(idx.object_id),
    NonUsefulClusteredIndex = idx.name,
    ShouldBeClustered = nc.nonclusteredname,
    Clustered_User_Seeks = c.user_seeks,
    NonClustered_User_Seeks = nc.user_seeks,
    Clustered_User_Lookups = c.user_lookups,
    DatabaseName = DB_NAME(c.database_id)
FROM
    sys.indexes idx
    LEFT JOIN sys.dm_db_index_usage_stats c ON idx.object_id = c.object_id AND idx.index_id = c.index_id
    JOIN (
           SELECT
                idx.object_id,
                nonclusteredname = idx.name,
                ius.user_seeks
           FROM
                sys.indexes idx
                JOIN sys.dm_db_index_usage_stats ius ON idx.object_id = ius.object_id AND idx.index_id = ius.index_id
           WHERE
                idx.type_desc = 'nonclustered' AND ius.user_seeks = (
                                                                  SELECT
                                                                    MAX(user_seeks)
                                                                  FROM
                                                                    sys.dm_db_index_usage_stats
                                                                  WHERE
                                                                    object_id = ius.object_id AND type_desc = 'nonclustered'
                                                                )
           GROUP BY
                idx.object_id,
                idx.name,
                ius.user_seeks
         ) nc ON nc.object_id = idx.object_id
WHERE
    idx.type_desc IN ( 'clustered', 'heap' )
    AND nc.user_seeks > ( c.user_seeks * 1.50 ) -- 150%
    AND nc.user_seeks >= ( c.user_lookups * 0.75 ) -- 75%
ORDER BY
    nc.user_seeks DESC