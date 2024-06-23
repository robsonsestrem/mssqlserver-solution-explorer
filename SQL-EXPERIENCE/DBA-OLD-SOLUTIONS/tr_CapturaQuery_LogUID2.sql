
CREATE TRIGGER tr_CapturaQuery_LogUID2
ON CADUSUARIOS
FOR UPDATE, DELETE , INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @CampoChave char(25), 
			@Tp_Alteracao CHAR(1)

	CREATE TABLE #log(eventtype VARCHAR(MAX),parameters int,text VARCHAR(MAX))
	INSERT INTO #log
	EXEC('DBCC INPUTBUFFER(@@spid)')

	if not exists(select top 1 null from inserted) --deleted
		begin
			select @Tp_Alteracao = 'D', @CampoChave = UsuCod
			from deleted
		end
	else if not exists(select top 1 null from deleted) --inserted
		begin
			select @Tp_Alteracao ='I', @CampoChave = UsuCod
			from inserted
		end
		else
			begin 
				select @Tp_Alteracao ='U', @CampoChave = UsuCod	--update
				from deleted
			end

	INSERT INTO CadusuariosLogDML
	(
		DateDML, 
		DatabaseUser, 
		LoginUser, 
		LoginUserSQLTransaction, 
		TypeSQL,
		ProgramName,
		HostName,
		TableName,
		UsuCod,
		Query
	)
	SELECT 
		B.start_time, 
		User_Name(), 
		Suser_Name(), 
		Original_Login(),
		@Tp_Alteracao, 
		program_name(),
		host_name(),
		'CADUSUARIOS',
		@CampoChave,
		(SELECT text FROM #log)
	from sys.dm_exec_sessions A
	JOIN sys.dm_exec_requests B on A.session_id = B.session_id
	JOIN sys.dm_exec_connections C on B.session_id = C.session_id
	where A.session_id = @@spid

END


-------------------------------------------------------------------------------------------------
-- TABELA DE LOGS
-------------------------------------------------------------------------------------------------

--use GesCooper90
--GO
--create table CadusuariosLogDML (
--	LogId int not null identity (1,1),
--	DateDML DateTime Default GetDate(),
--	DatabaseUser VarChar(100) Default User_Name(),
--	LoginUser Varchar(100) Default Suser_Name(),
--	LoginUserSQLTransaction Varchar(100) Default Original_Login(),
--	TypeSQL char(1) ,
--	ProgramName varchar(100) default program_name(),
--	HostName varchar(100) default host_name(),
--	TableName varchar(30) default 'CADUSUARIOS',
--	UsuCod char(25) not null default '',
--	Query nvarchar(max) default '',
--	constraint PK_LogId primary key (LogId),	
--	constraint CK_TableName check (TableName like 'CADUSUARIOS'),
--	constraint CK_TypeSQL check (TypeSQL in ('D','I','U'))	
--);