--------------------------------------------------------------------------------------------------------------
-- Visualiza todas conexões abertas
--------------------------------------------------------------------------------------------------------------
SELECT *
FROM master.dbo.sysprocesses
WHERE dbid = DB_ID('gescooper90_homolog')


--------------------------------------------------------------------------------------------------------------
-- Quantidade de Conexões por banco de dados
--------------------------------------------------------------------------------------------------------------
SELECT db_name(dbid) as Banco_de_Dados,
count(dbid) as Qtd_Conexoes
FROM sys.sysprocesses
WHERE --dbid > 50
db_name(dbid) = 'gescooper90_homolog'
GROUP BY dbid, loginame -- agrupado por número de sessões abertas por usuário


/*************************************************************************************************************/
--------------------------------------------------------------------------------------------------------------
-- Colocando o Banco de Dados para Single_User 
--------------------------------------------------------------------------------------------------------------
Alter Database Maintenance
Set Single_User With Rollback Immediate


--------------------------------------------------------------------------------------------------------------
-- Colocando o Banco de Dados que esta como Single_User para Multi_User
--------------------------------------------------------------------------------------------------------------
Alter Database Maintenance
Set Multi_User With Rollback Immediate


/*************************************************************************************************************/
-----------------------------------------------------------------------------------------------------------
--						Fechar conexões para manutenções
-----------------------------------------------------------------------------------------------------------
DECLARE @query VARCHAR(MAX) = ''

SELECT
    @query = COALESCE(@query, ',') + 'KILL ' + CONVERT(VARCHAR, spid) + '; '
FROM
    master..sysprocesses
WHERE
    dbid = DB_ID('gescooper90') -- Nome do database
    AND dbid > 4 -- Não eliminar sessões em databases de sistema
    AND spid <> @@SPID -- Não eliminar a sua própria sessão

IF (LEN(@query) > 0)
    EXEC(@query)


-----------------------------------------------------------------------------------------------------------
--						Matar conexões fantasma
-----------------------------------------------------------------------------------------------------------
declare @killspidpreza varchar(30)

declare kill_proc_preza cursor for

select 'kill ' + cast(t1.spid as varchar(10))
from sys.sysprocesses as t1 inner join sys.dm_exec_sessions as t2
on t1.spid = t2.session_id
where t1.status = 'sleeping' 
and t1.open_tran = 0 
and t2.is_user_process = 1
and hostname <> 'CRVSQL01'

open kill_proc_preza
fetch next from kill_proc_preza into @killspidpreza

while @@fetch_status = 0
	begin
	   execute (@killspidpreza)
	   fetch next from kill_proc_preza into @killspidpreza
	end
close kill_proc_preza
deallocate kill_proc_preza


------------------------------------------------------------------------------------------------------------------------------
--						Fechando sessões bloqueadas
------------------------------------------------------------------------------------------------------------------------------
-- CREATE
-- PROCEDURE SP_ELIMINA_BLOCK AS

DECLARE @v_spid INT
DECLARE @Sql VARCHAR(100)

Set @v_spid =(SELECT spid 
			  FROM MASTER.DBO.SYSPROCESSES BLOCKING 
			  WHERE BLOCKING.BLOCKED = 0 
			  AND EXISTS (SELECT 1 
						  FROM MASTER.DBO.SYSPROCESSES BLOCKED 
						  WHERE BLOCKED.BLOCKED = BLOCKING.SPID));

Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)
EXEC (@Sql)

SELECT top 1 @v_spid =spid 
FROM MASTER.DBO.SYSPROCESSES BLOCKING 
WHERE BLOCKING.BLOCKED = 0 
AND EXISTS (SELECT 1 
			FROM MASTER.DBO.SYSPROCESSES BLOCKED 
			WHERE BLOCKED.BLOCKED = BLOCKING.SPID);
Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)

EXEC (@Sql)


------------------------------------------------------------------------------------------------------------------------------
--						Fechando sessões bloqueadas usando cursores 
------------------------------------------------------------------------------------------------------------------------------

--CREATE PROCEDURE SP_ELIMINA_BLOCK AS
use GesCooper90
go
DECLARE @v_spid INT
DECLARE @Sql VARCHAR(100)
DECLARE bloq_cursor CURSOR FOR

SELECT spid 
FROM MASTER.DBO.SYSPROCESSES BLOCKING 
WHERE BLOCKING.BLOCKED = 0 
AND EXISTS(SELECT 1 
		   FROM MASTER.DBO.SYSPROCESSES BLOCKED 
		   WHERE BLOCKED.BLOCKED = BLOCKING.SPID); -- captura spid com bloqueio

OPEN bloq_cursor
FETCH NEXT FROM bloq_cursor INTO @v_spid;
WHILE @@FETCH_STATUS = 0
BEGIN
Set @Sql = 'KILL '+cast(@V_SPID AS VARCHAR)
EXEC (@Sql)
print 'killed spid '+str(@v_spid)
FETCH NEXT FROM bloq_cursor INTO @v_spid;
END
CLOSE bloq_cursor;
DEALLOCATE bloq_cursor;