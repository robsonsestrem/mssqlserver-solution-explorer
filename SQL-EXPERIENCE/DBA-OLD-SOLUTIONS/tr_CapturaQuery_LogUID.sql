USE [GesCooper90]
GO


CREATE TRIGGER [dbo].[tr_CapturaQuery_LogUID]
ON [dbo].[CADUSUARIOS] 
FOR INSERT, UPDATE, DELETE 
AS
BEGIN
SET NOCOUNT ON
   
DECLARE @action char(1)

CREATE TABLE #log(
	eventtype VARCHAR(MAX),
	parameters int,
	text VARCHAR(MAX))
INSERT INTO #log
EXEC('DBCC INPUTBUFFER(@@spid)')


IF COLUMNS_UPDATED() > 0 -- insert or update
BEGIN
    IF EXISTS (SELECT * FROM DELETED) -- update
        SET @action = 'U'
    ELSE
        SET @action = 'I'
END
	ELSE -- delete
		SET @action = 'D'


    IF @Action = 'D' 
      BEGIN 
          INSERT INTO dbo.CadusuariosLogDML
                      (DateDML, 
                       DatabaseUser, 
                       LoginUser, 
                       LoginUserSQLTransaction, 
                       TypeSQL,
					   ProgramName,
					   HostName,
					   TableName,
					   UsuCod,
					   Query) 
          SELECT Getdate(), 
                 User_Name(), 
                 Suser_Name(), 
				 Original_Login(),
                 @Action, 
				 program_name(),
				 host_name(),
				 'CADUSUARIOS',
                 UsuCod,
				 (SELECT text FROM #log)
          FROM   deleted 
      END 

    ELSE 
      BEGIN 
          IF (@Action = 'I' or @Action = 'U')   --condição para quando houver inserção 
            BEGIN								--ou alteração
                INSERT INTO dbo.CadusuariosLogDML
                      (DateDML, 
                       DatabaseUser, 
                       LoginUser, 
                       LoginUserSQLTransaction, 
                       TypeSQL,
					   ProgramName,
					   HostName,
					   TableName,
					   UsuCod,
					   Query) 
          SELECT Getdate(), 
                 User_Name(), 
                 Suser_Name(), 
				 Original_Login(),
                 @Action, 
				 program_name(),
				 host_name(),
				 'CADUSUARIOS',
                 UsuCod,
				 (SELECT text FROM #log)
          FROM   inserted
            END 
	 END

END

GO

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