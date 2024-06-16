-----------------------------------------------------------------------------------------------------------------------------------------------------
-- Referências
-- https://technet.microsoft.com/pt-br/library/bb630317(v=sql.105).aspx
-- Vitor Fava
-----------------------------------------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------------------------------------------------------------------
--Criar a sessão de monitoração
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE EVENT SESSION [XE_SORTWARNING] ON SERVER 
ADD EVENT sqlserver.sort_warning(
    ACTION(sqlserver.database_name,sqlserver.sql_text,
	sqlserver.username)) 
ADD TARGET package0.ring_buffer
GO

ALTER EVENT SESSION [XE_SORTWARNING]  
ON SERVER  
STATE = start;  
GO

DROP EVENT SESSION [XE_SORTWARNING]  
ON SERVER  


-----------------------------------------------------------------------------------------------------------------------------------------------------
-- SIMULAÇÃO - Criar a TabelaTeste 
-----------------------------------------------------------------------------------------------------------------------------------------------------
CREATE TABLE dbo.TabelaTeste (
	Col1 int IDENTITY(1,1), 
	Col2 varchar(8000)
) 
GO
-- Inserir dados na tabela
INSERT INTO dbo.TabelaTeste (Col2) 
	SELECT REPLICATE('A','8000') 
GO 200 

-- Gerar Sort Warning
DECLARE @T1 TABLE (
	Col1 int, 
	Col2 varchar(8000)
) 
INSERT INTO @T1 SELECT * FROM dbo.TabelaTeste 
SELECT Col2, COUNT(*) FROM @T1 GROUP BY Col2


