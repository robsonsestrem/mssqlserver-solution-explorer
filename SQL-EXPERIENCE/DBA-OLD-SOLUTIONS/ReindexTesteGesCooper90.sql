--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://blogfabiano.com/2010/05/25/plano-de-manutencao-reindex-vs-estatisticas/
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Se você usar o ALTER INDEX REBUILD passando um índice ele só atualiza as estatisticas deste índice
-- ALTER INDEX XPKTabela ON <tabela> REBUILD
/*
name                          DataAtualizacao

XPKTabela                      2010-05-25 14:26:07.607 — ATUALIZAOU O INDICE

ix_Coluna                      2010-05-25 14:25:17.070

_WA_Sys_ID_Pessoa_0DFC52CF      2010-05-25 14:25:15.127

_WA_Sys_ID_Endereco_0DFC52CF  2010-05-25 14:25:15.140
*/

-- alter index PK_CMVTransf on HistoricoCMVTransf rebuild
use Maintenance
go

select
t1.DatabaseName, t1.SchemaName, t1.TableName, t1.IndexName, IndexTypeDesc, t1.AvgFragmentationInPercent
, t1.AvgPageSpaceUsedInPercent, t1.IndexLevel, t1.IndexDepth
, t1.PageCount , t1.RecordCount, t1.IndexUsage, t1.IndexUserScans, t1.IndexUserSeeks, t1.IndexUserLookups
from Management.HistoryIndexFragmentation as t1
where t1.DateReference >= '20180701' and t1.DateReference < '20180710'
and t1.DatabaseId = 6
and t1.IndexName = 'PK__MOVESTOQUELEVEL1__2D52A092'
and t1.AvgFragmentationInPercent > 5
and t1.PageCount > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0
--and t1.AvgPageSpaceUsedInPercent > 75
order by t1.TableName asc, t1.AvgFragmentationInPercent desc


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando o script
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
select
'ALTER INDEX '+ t1.IndexName +' ON '+ t1.DatabaseName + '.' + t1.SchemaName + '.' + t1.TableName + ' '
+ case when t1.AvgFragmentationInPercent < 30 then 'REORGANIZE'
	   else 'REBUILD'
  end
+ '; BACKUP LOG GesCooper90 TO DISK = ''G:\Backup\GesCooper90_log.TRN'' WITH INIT;' + ' --Frag. = '+cast(t1.AvgFragmentationInPercent as varchar(50)) + '%' + ' - PageCont = '+ cast(t1.PageCount as varchar(50))
AS SCRIPTS
from Management.HistoryIndexFragmentation as t1
where t1.DateReference >= '20180301' and t1.DateReference < '20180302'
and t1.DatabaseId = 6
and t1.AvgFragmentationInPercent > 5
and t1.PageCount > 1000
and t1.AllocUnitTypeDesc = 'IN_ROW_DATA'
and t1.IndexLevel = 0
order by t1.PageCount desc -- buscando os maiores índices por 1º


--------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo de resultSet
--------------------------------------------------------------------------------------------------------------------------------------------------------------------
ALTER INDEX PK__MOVESTOQUELEVEL1__2D52A092 ON GesCooper90.dbo.MOVESTOQUELEVEL1 REBUILD; BACKUP LOG GesCooper90 TO DISK = 'G:\Backup\GesCooper90_log.TRN' WITH INIT; --Frag. = 36.58% - PageCont = 21596144