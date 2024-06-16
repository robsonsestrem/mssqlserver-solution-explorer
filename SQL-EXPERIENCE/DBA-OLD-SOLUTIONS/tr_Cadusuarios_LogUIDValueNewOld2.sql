---------------------------------------------------------------------------------------------------------------------------------
-- Tratamento melhorado para DML -> delete.
---------------------------------------------------------------------------------------------------------------------------------


CREATE TRIGGER [dbo].[tr_Cadusuarios_LogUID]
ON CADUSUARIOS
FOR UPDATE, DELETE , INSERT
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @CampoChave char(25), 
			@action CHAR(1),
		    @Col INT, 
			@qCols INT, 
			@NomeCol NVARCHAR(MAX),
			@bitVerificador INT, 
			@Pot INT
SET @Col = 0

-- Conta quantas colunas existem na tabela contemplada pela Trigger
SET @qCols = (SELECT COUNT(*) FROM sys.columns WHERE object_id =
    (SELECT Parent_ID FROM sys.triggers WHERE object_id = @@procid))

-- Coloca a tabela Deleted em uma variável XML
DECLARE @Deleted XML, 
		@DeletedTMP XML
SET @Deleted = (SELECT * FROM Deleted FOR XML RAW, ROOT('Deleted'))

-- Coloca a tabela Inserted em uma variável XML
DECLARE @Inserted XML, 
		@InsertedTMP XML
SET @Inserted = (SELECT * FROM Inserted FOR XML RAW, ROOT('Inserted'))


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
          		WHILE (@Col < @qCols)
					BEGIN
						SET @Col = @Col + 1
						SET @Pot = (@Col - 1) % 8 + 1
						SET @Pot = POWER(2,@Pot - 1)
						SET @bitVerificador = ((@Col - 1) / 8) + 1						
										SET @NomeCol = (
											SELECT Name FROM sys.columns WHERE object_id =
												(SELECT Parent_ID FROM sys.triggers
												WHERE object_id = @@procid) AND column_id = @Col)

									-- Substitui a TAG no XML da DELETED e faz a extração dos dados
									SET @DeletedTMP = REPLACE(CAST(@Deleted As VARCHAR(MAX)),@NomeCol + '=','Col=')
														
										INSERT INTO CadusuariosLogDML 
										(
											DateDML, 
											DatabaseUser, 
											LoginUser, 
											LoginUserSQLTransaction, 											
											ProgramName,
											HostName,
											TableName,
											TypeSQL,
											UsuCod,
											ColumnUpdate,
											ValueOld								
										)
										SELECT 
										 Getdate(), 
										 User_Name(), 
										 Suser_Name(), 
										 Original_Login(),										 
										 program_name(),
										 host_name(),
										'CADUSUARIOS',
										 @Action, 
										 UsuCod,
										ISNULL(@NomeCol,''),
			ISNULL((SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]','varchar(100)') FROM @DeletedTMP.nodes('.') E(e)), '') As ValueOld
								
										FROM deleted As Ins
							
					END -- WHILE
		  END -- @action D
   ELSE 
      BEGIN 
          IF (@Action = 'I' or @Action = 'U')   --condição para quando houver inserção 
            BEGIN								--ou alteração					
					WHILE (@Col < @qCols)
						BEGIN
							SET @Col = @Col + 1
							SET @Pot = (@Col - 1) % 8 + 1
							SET @Pot = POWER(2,@Pot - 1)
							SET @bitVerificador = ((@Col - 1) / 8) + 1
							IF (SUBSTRING(COLUMNS_UPDATED(),@bitVerificador, 1) & @Pot > 0)
							BEGIN
								SET @NomeCol = (
									SELECT Name FROM sys.columns WHERE object_id =
										(SELECT Parent_ID FROM sys.triggers
										WHERE object_id = @@procid) AND column_id = @Col)

								-- Substitui a TAG no XML da DELETED e faz a extração dos dados
								SET @DeletedTMP = REPLACE(CAST(@Deleted As VARCHAR(MAX)),@NomeCol + '=','Col=')

								-- Substitui a TAG no XML da INSERTED e faz a extração dos dados
								SET @InsertedTMP = REPLACE(CAST(@Inserted As VARCHAR(MAX)),@NomeCol + '=','Col=')

								INSERT INTO CadusuariosLogDML
								(
									DateDML, 
									DatabaseUser, 
									LoginUser, 
									LoginUserSQLTransaction, 								
									ProgramName,
									HostName,
									TableName,
									TypeSQL,
									UsuCod,
									ColumnUpdate,
									ValueOld,
									ValueNew
								)
								SELECT 
								 Getdate(), 
								 User_Name(), 
								 Suser_Name(), 
								 Original_Login(),								
								 program_name(),
								 host_name(),
								'CADUSUARIOS',
								 @Action, 
								 UsuCod,
								 ISNULL(@NomeCol,''),
ISNULL((SELECT E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]','varchar(100)') FROM @DeletedTMP.nodes('.') E(e)),'') As ValueOld,
ISNULL((SELECT E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]','varchar(100)') FROM @InsertedTMP.nodes('.') E(e)),'') As ValueNew
								FROM Inserted As Ins
							END
						END
                	
            END 
	 END

 END
	
GO


---------------------------------------------------------------------------------------------------------------------------------
-- TABELA DE LOGS
---------------------------------------------------------------------------------------------------------------------------------

use GesCooper90
GO
create table CadusuariosLogDML (
	LogId int not null identity (1,1),
	DateDML DateTime Default GetDate(),
	DatabaseUser VarChar(100) Default User_Name(),
	LoginUser Varchar(100) Default Suser_Name(),
	LoginUserSQLTransaction Varchar(100) Default Original_Login(),	
	ProgramName varchar(100) default program_name(),
	HostName varchar(100) default host_name(),
	TableName varchar(30) default 'CADUSUARIOS',
	TypeSQL char(1) ,
	UsuCod char(25) not null default '',
	ColumnUpdate sysname,  -- tipos de dados corresponde ao varchar(128) e já seta not null também
	ValueOld varchar(100) default '',
	ValueNew varchar(100) default '',

	constraint PK_LogId primary key (LogId),	
	constraint CK_TableName check (TableName like 'CADUSUARIOS'),
	constraint CK_TypeSQL check (TypeSQL in ('D','I','U'))	
);

