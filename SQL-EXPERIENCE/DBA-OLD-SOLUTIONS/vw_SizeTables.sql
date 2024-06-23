--------------------------------------------------------------------------------------------------------------
-- Usada para análise de crescimento de tabelas em toda a instância.
--------------------------------------------------------------------------------------------------------------
USE IntegraTICravil
GO

if object_id('Management.vw_SizeTables') is not null
	drop view Management.vw_SizeTables
GO

create view Management.vw_SizeTables
WITH ENCRYPTION
AS
select A.DtReferencia, B.NmServidor, C.NmDatabase,D.NmTabela ,A.NmDrive, A.NrTamanhoTotal, A.NrTamanhoDados,
	A.NrTamanhoIndice, A.QtLinhas
from Management.HistorySizeTables A
	join Management.InstanceServer B on A.IdServidor = B.IdServidor
	join Management.InstanceDatabases C on A.IdBaseDados = C.IdBaseDados
	join Management.InstanceTables D on A.IdTabela = D.IdTabela	
GO