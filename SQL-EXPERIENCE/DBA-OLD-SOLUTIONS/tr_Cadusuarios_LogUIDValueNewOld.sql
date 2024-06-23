use GesCooper90
GO

CREATE TRIGGER tr_cadusuarios_LogUID 
ON CADUSUARIOS 
FOR UPDATE, DELETE, INSERT 
AS 
  BEGIN 
      SET NOCOUNT ON 

      DECLARE @CampoChave     CHAR(25), 
              @action         CHAR(1), 
              @Col            INT, 
              @qCols          INT, 
              @NomeCol        VARCHAR(100), 
              @bitVerificador INT, 
              @Pot            INT 

      SET @Col = 0 
      -- Conta quantas colunas existem na tabela contemplada pela Trigger 
      SET @qCols = (SELECT Count(*) 
                    FROM   sys.columns 
                    WHERE  object_id = (SELECT parent_id 
                                        FROM   sys.triggers 
                                        WHERE  object_id = @@procid)) 

      -- Coloca a tabela Deleted em uma variável XML 
      DECLARE @Deleted    XML, 
              @DeletedTMP XML 

      SET @Deleted = (SELECT * FROM deleted FOR xml raw, root('Deleted')) 

      -- Coloca a tabela Inserted em uma variável XML 
      DECLARE @Inserted    XML, 
              @InsertedTMP XML 

      SET @Inserted = (SELECT * FROM inserted FOR xml raw, root('Inserted')) 

      IF Columns_updated() > 0				  -- insert or update 
        BEGIN 
            IF EXISTS (SELECT * FROM deleted) -- update 
              SET @action = 'U' 
            ELSE 
              SET @action = 'I' 
        END 
      ELSE									  -- delete 
        SET @action = 'D' 
--------------------------------------------------------------------------------------------------------------------------
      IF @Action = 'D' 
        BEGIN 
            INSERT INTO CadusuariosLogDML
                        (DateDML, 
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
                         ValueNew) 
            SELECT Getdate(), 
                   User_name(), 
                   Suser_name(), 
                   Original_login(),                   
                   Program_name(), 
                   Host_name(), 
                   'CADUSUARIOS', 
				   @Action, 
                   Usucod, 
                   'SystemUpdate', 
                   'Removido', 
                   '' 
            FROM   deleted       
        END -- @action D 
      ELSE 
        BEGIN 
            IF ( @Action = 'I' OR @Action = 'U' ) -- condição para quando houver inserção ou alteração 
              BEGIN          
                  WHILE ( @Col < @qCols ) 
                    BEGIN 
                        SET @Col = @Col + 1 
                        SET @Pot = ( @Col - 1 ) % 8 + 1 
                        SET @Pot = Power(2, @Pot - 1) 
                        SET @bitVerificador = ( ( @Col - 1 ) / 8 ) + 1 

                        IF ( Substring(Columns_updated(), @bitVerificador, 1) & @Pot > 0 ) 
                          BEGIN 
                              SET @NomeCol = (SELECT NAME 
                                              FROM   sys.columns 
                                              WHERE  object_id = 
                                                     (SELECT parent_id 
                                                      FROM   sys.triggers 
                                                      WHERE 
                                                     object_id = @@procid) 
                                              AND column_id = @Col) 
                              -- Substitui a TAG no XML da DELETED e faz a extração dos dados
                              SET @DeletedTMP = Replace(Cast(@Deleted AS VARCHAR (max)),@NomeCol + '=','Col=') 

                              -- Substitui a TAG no XML da INSERTED e faz a extração dos dados 
                              SET @InsertedTMP = Replace(Cast(@Inserted AS VARCHAR(max)),@NomeCol + '=','Col=') 

                              INSERT INTO CadusuariosLogDML 
                                        (DateDML, 
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
										 ValueNew)
                              SELECT Getdate(), 
                                     User_name(), 
                                     Suser_name(), 
                                     Original_login(),                                      
                                     Program_name(), 
                                     Host_name(), 
                                     'CADUSUARIOS',
									 @Action, 
                                     UsuCod, 
                                     Isnull(@NomeCol, ''), 
                                     Isnull((SELECT 
									E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)') 
									FROM @DeletedTMP.nodes('.') E(e)), '')  AS ValueOld, 
									 Isnull((SELECT 
									E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)') 
									FROM @InsertedTMP.nodes('.') E(e)), '') AS ValueNew 
							   FROM inserted AS Ins 
							END 
					END --fim do while
			END --condicional I e U 
		END --fim do else
 END 

GO


---------------------------------------------------------------------------------------------------------------------------------
-- TABELA DE LOGS
---------------------------------------------------------------------------------------------------------------------------------

--use GesCooper90
--GO
--create table CadusuariosLogDML (
--	LogId int not null identity (1,1),
--	DateDML DateTime Default GetDate(),
--	DatabaseUser VarChar(100) Default User_Name(),
--	LoginUser Varchar(100) Default Suser_Name(),
--	LoginUserSQLTransaction Varchar(100) Default Original_Login(),	
--	ProgramName varchar(100) default program_name(),
--	HostName varchar(100) default host_name(),
--	TableName varchar(30) default 'CADUSUARIOS',
--	TypeSQL char(1) ,
--	UsuCod char(25) not null default '',
--	ColumnUpdate sysname,  -- tipos de dados corresponde ao varchar(128) e já seta not null também
--	ValueOld varchar(100) default '',
--	ValueNew varchar(100) default '',

--	constraint PK_LogId primary key (LogId),	
--	constraint CK_TableName check (TableName like 'CADUSUARIOS'),
--	constraint CK_TypeSQL check (TypeSQL in ('D','I','U'))	
--);

