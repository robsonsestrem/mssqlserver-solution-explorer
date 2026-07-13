USE [YOUR_DATABASE]
GO

ALTER TRIGGER [dbo].[tr_Produtoslevel4_LogUID] 
ON [dbo].[PRODUTOSLEVEL4] 
WITH ENCRYPTION 
FOR UPDATE, DELETE, INSERT 
AS 
  BEGIN 
      SET NOCOUNT ON 

      DECLARE @contador       INT,			
              @action         CHAR(15), 
              @Col            INT, 
              @qCols          INT, 
              @NomeCol        VARCHAR(100), 
              @bitVerificador INT, 
              @Pot            INT 

	  DECLARE @Inserted    XML, 
              @InsertedTMP XML 

	  DECLARE @Deleted    XML, 
              @DeletedTMP XML 
--------------------------------------------------------------------------------------------------------------------------	
	  SET @Col = 0 
         -- Conta quantas colunas existem na tabela contemplada pela Trigger 
         SET @qCols = (SELECT Count (*) 
                       FROM   sys.columns 
                       WHERE  object_id = (SELECT parent_id 
                                           FROM   sys.triggers 
                                           WHERE  object_id = @@procid)) 

         -- Coloca a tabela Deleted em uma vari�vel XML, para este caso s� selecionei alguns campos       
         SET @Deleted = (SELECT ProCod, ProCodPreco, ProDatIni, Final, ProDatAlteracao, ProVlrPreco FROM deleted FOR xml raw, root('Deleted'))       
     
		 -- Coloca a tabela Inserted em uma vari�vel XML, para este caso s� selecionei alguns campos
         SET @Inserted = (SELECT ProCod, ProCodPreco, ProDatIni, Final, ProDatAlteracao, ProVlrPreco FROM inserted FOR xml raw, root('Inserted')) 

	  IF not exists (select top 1 null FROM inserted) --deleted
		BEGIN
			SELECT @action = 'D'FROM deleted			  
          		WHILE (@Col < @qCols)
					BEGIN
						SET @Col = @Col + 1
						SET @Pot = (@Col - 1) % 8 + 1
						SET @Pot = POWER (2, @Pot - 1)
						SET @bitVerificador = ((@Col - 1) / 8) + 1						
						
SET @NomeCol = (SELECT Name 
								   FROM sys.columns
								   WHERE object_id = (SELECT Parent_ID 
											  FROM sys.triggers
											  WHERE object_id = @@procid) 
									                AND column_id = @Col)

						-- Substitui a TAG no XML da DELETED e faz a extra��o dos dados
						SET @DeletedTMP = REPLACE (CAST (@Deleted As VARCHAR (MAX)), @NomeCol + '=','Col=')
														
						INSERT INTO IntegraTICravil.LogErp.Produtoslevel4LogDML 
									(
										DateDML, 
										DatabaseUser, 
										LoginUser, 
										LoginUserSQLTransaction, 							
										ProgramName,
										HostName,
										TableName,
										TypeSQL,
										Procod,
										CodigoFilial,
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
										'PRODUTOSLEVEL4',
										 @Action, 
										 ProCod,
										 ProCodPreco,
										ISNULL (@NomeCol,''),
										ISNULL (
(SELECT E.e.value ('(/Deleted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]','varchar(100)') 
										FROM @DeletedTMP.nodes('.') E(e)), '') As ValueOld
								
									FROM deleted As Ins									
					END -- WHILE		  

		END -- condi��o delete
		ELSE IF not exists(select top 1 null from deleted) --inserted
			BEGIN
				SELECT @action ='I'	FROM inserted
			END
			ELSE
				BEGIN 
					SELECT @action ='U' FROM deleted	   --update
				END
				 		 			     	                        
                  WHILE (@Col < @qCols) 
                    BEGIN 
                        SET @Col = @Col + 1 
                        SET @Pot = (@Col - 1) % 8 + 1 
                        SET @Pot = Power (2, @Pot - 1) 
                        SET @bitVerificador = ((@Col - 1) / 8) + 1 

                        IF (Substring (Columns_updated(), @bitVerificador, 1) & @Pot > 0)
                          BEGIN 
                              SET @NomeCol = (SELECT NAME 
                                              FROM   sys.columns 
                                              WHERE  object_id = 
                                                     (SELECT parent_id 
                                                      FROM   sys.triggers 
                                                      WHERE 
                                                     object_id = @@procid) 
                                              AND column_id = @Col) 
                              -- Substitui a TAG no XML da DELETED e faz a extra��o dos dados
                              SET @DeletedTMP = Replace (Cast (@Deleted AS VARCHAR (max)), @NomeCol + '=','Col=') 

                              -- Substitui a TAG no XML da INSERTED e faz a extra��o dos dados 
                              SET @InsertedTMP = Replace (Cast (@Inserted AS VARCHAR (max)), @NomeCol + '=','Col=') 

                              INSERT INTO IntegraTICravil.LogErp.Produtoslevel4LogDML
                                        (
										 DateDML, 
										 DatabaseUser, 
										 LoginUser, 
										 LoginUserSQLTransaction,                         
										 ProgramName, 
										 HostName, 
										 TableName,
										 TypeSQL, 
										 Procod,
										 CodigoFilial, 
										 ColumnUpdate, 
										 ValueOld, 
										 ValueNew
										)
							SELECT X.DateDML, X.DatabaseUser, X.LoginUser, X.LoginUserSQLTransaction,
								X.ProgramName, X.HostName, X.TableName, X.TypeSQL, X.ProCod,X.ProCodPreco,
								X.ColumnUpdate, X.ValueOld, X.ValueNew
                               FROM(
									SELECT 
										Getdate()						as DateDML, 
                                     	User_name()						as DatabaseUser, 
                                     	Suser_name()					as LoginUser, 
                                     	Original_login()				as LoginUserSQLTransaction,                                      
                                     	Program_name()					as ProgramName, 
                                     	Host_name()						as HostName, 
                                     	'PRODUTOSLEVEL4'				as TableName,
					   					@Action			                as TypeSQL, 
                                     	ProCod							as ProCod,
										ProCodPreco						as ProCodPreco,
                                     	Isnull (@NomeCol, '')			as ColumnUpdate, 
                                    	Isnull (
  	(SELECT E.e.value ('(/Deleted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)') 
					   	FROM @DeletedTMP.nodes('.') E (e)), '')         as ValueOld, 
					   	Isnull (
  	(SELECT E.e.value ('(/Inserted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)') 
					   	FROM @InsertedTMP.nodes('.') E(e)), '')         as ValueNew 
				          FROM inserted AS Ins 
					  ) as X
					  WHERE X.ValueNew <> X.ValueOld -- isso deixar trazer somente os campos alterados
				END 
		END --fim do while					
END 

GO

---------------------------------------------------------------------------------------------------------------------------------
-- TABELA DE LOGS � Local onde a trigger acima registra os dados DML da tabela PRODUTOSLEVEL4, onde s�o
-- registradas as mudan�as de pre�os dos produtos
---------------------------------------------------------------------------------------------------------------------------------
--Use IntegraTICravil
--GO
--create table Produtoslevel4LogDML (
--	LogId int not null identity (1,1),
--	DateDML DateTime Default GetDate(),
--	DatabaseUser VarChar(100) Default User_Name(),
--	LoginUser Varchar(100) Default Suser_Name(),
--	LoginUserSQLTransaction Varchar(100) Default Original_Login(),	
--	ProgramName varchar(100) default program_name(),
--	HostName varchar(100) default host_name(),
--	TableName varchar(30) default 'PRODUTOSLEVEL4',
--	TypeSQL char(1) ,
--	Procod int not null,
--	CodigoFilial int not null,
--	ColumnUpdate sysname,  -- tipos de dados corresponde ao varchar(128) e j� seta not null tamb�m
--	ValueOld varchar(100) default '',
--	ValueNew varchar(100) default '',

--	constraint PK_ProLogId primary key (LogId),	
--	constraint CK_TableNamePro check (TableName like 'PRODUTOSLEVEL4'),
--	constraint CK_TypeSQLPro check (TypeSQL in ('D','I','U'))	
--)
