----------------------------------------------------------------------------------------------------------------------
-- Trigger utilizada na tabela DDLTransaction que no caso colocaria mesmo tanto de colunas 
-- existentes da tabela onde se quer fazer Logs, ou seja, replicaria campo de uma tabela para outra.
----------------------------------------------------------------------------------------------------------------------


create trigger tr_AddCampoLog
on DDlTransaction
FOR insert
AS
BEGIN
	declare @tsql nvarchar(max)
	declare @ddlLog nvarchar(max);
	declare @tipoEvento nvarchar(200);
	declare @objeto nvarchar (200); 

	set @tipoEvento = (select TipoEvento from inserted)
	set @objeto = (select Objeto from inserted)	

	IF (@tipoEvento = 'ALTER_TABLE')
		BEGIN
			IF (@objeto = 'piloto')
				BEGIN
					set @tsql = (select Comando_TSQL from inserted)			  
					set @ddlLog = (select REPLACE(@tsql, 'piloto', 'Log')) -- substitui determinada string
					EXECUTE (@ddlLog)									   -- executa variável com valor de comando T-SQL.
				END  
		END		
END