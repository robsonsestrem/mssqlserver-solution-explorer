USE IntegraTICravil
GO

SELECT i.id        AS ObjectId, 
       t.NAME      AS TableName,     
       i.indid     AS Index_Stat_Id,     -- id de statistics na tabela sysindexes 
       i.NAME      AS Index_Stat_Name,   -- nome de statistics para coluna da tabela  
       i.rowmodctr AS Status_DML,        -- número de alterações que sofreu desde última atualização
       i.rows      AS Total_Rows_Column, -- Nº de linhas que tem statistics por coluna 
       i.dpages 
FROM   sysindexes i 
       JOIN sys.tables t 
         ON i.id = t.object_id
         
WHERE  t.NAME = 'contabil' 
       AND i.rowmodctr > ( ( 0.20 ) * (SELECT Count(*) 
                                       FROM   Bi.HistoricoCMV WITH(nolock)) + 500 ) 
                                       
ORDER  BY i.rowmodctr



-----------------------------------------------------------------------------------
USE GesCooper90
GO
EXEC sp_helpstats 'contabil', 'all'