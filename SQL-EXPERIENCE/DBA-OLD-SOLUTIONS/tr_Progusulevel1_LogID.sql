USE YOUR_DATABASE
GO

ALTER TRIGGER [dbo].[tr_ProgUsulevel1_LogID]
ON [dbo].[PROGUSULEVEL1]
WITH ENCRYPTION 
FOR DELETE , INSERT
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @Tp_Alteracao CHAR(1)

	if not exists(select top 1 null from inserted) --deleted
		begin

			set @Tp_Alteracao = 'D'
			
			INSERT INTO IntegraTICravil.LogErp.ProgUsuLevel1LogDML
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
				PrgCod1		
			)
			SELECT 
				GETDATE(), 
				User_Name(), 
				Suser_Name(), 
				Original_Login(),
				@Tp_Alteracao, 
				program_name(),
				host_name(),
				'PROGUSULEVEL1',
				UsuCod,
				PrgCod1		
			from deleted							
								
		end
	else if not exists(select top 1 null from deleted) --inserted
		begin

			set @Tp_Alteracao = 'I'
			
			INSERT INTO IntegraTICravil.LogErp.ProgUsuLevel1LogDML
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
				PrgCod1		
			)
			SELECT 
				GETDATE(), 
				User_Name(), 
				Suser_Name(), 
				Original_Login(),
				@Tp_Alteracao, 
				program_name(),
				host_name(),
				'PROGUSULEVEL1',
				UsuCod,
				PrgCod1		
			from inserted

		end			
END
GO

-------------------------------------------------------------------------------------------------
-- TABELA DE LOGS
-- Obs.: o que defini se tem acesso acesso ou n�o � o TypeSQL (I, D)
-------------------------------------------------------------------------------------------------

--USE IntegraTICravil
--GO
--create table LogErp.ProgUsuLevel1LogDML (
--	LogId int not null identity(1,1),
--	DateDML DateTime Default GetDate(),
--	DatabaseUser VarChar(100) Default User_Name(),
--	LoginUser Varchar(100) Default Suser_Name(),
--	LoginUserSQLTransaction Varchar(100) Default Original_Login(),
--	TypeSQL char(1) ,
--	ProgramName varchar(100) default program_name(),
--	HostName varchar(100) default host_name(),
--	TableName varchar(30) default 'PROGUSULEVEL1',
--	UsuCod char(25) not null default '',
--	PrgCod1 varchar(100) default '',
--	constraint PK_LogIdProgUsu primary key (LogId),	
--	constraint CK_TableNameProgusu check (TableName like 'PROGUSULEVEL1'),
--	constraint CK_TypeSQLProgUsu check (TypeSQL in ('D','I'))	
--);


--select * from PROGUSULEVEL1
