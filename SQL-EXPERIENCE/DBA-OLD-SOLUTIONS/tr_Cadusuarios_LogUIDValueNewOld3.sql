--------------------------------------------------------------------------------------------------------------
-- Tratado só para trazer campos com alteração no UPDATE E INSERT.
--------------------------------------------------------------------------------------------------------------

USE [GesCooper90]
GO

/****** Object:  Trigger [dbo].[TR_cadusuarios_LogUID]    Script Date: 04/04/2016 17:03:12 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE TRIGGER [dbo].[tr_cadusuarios_LogUID] 
ON [dbo].[CADUSUARIOS] 
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
						Select X.DateDML, X.DatabaseUser, X.LoginUser, X.LoginUserSQLTransaction,
							   X.ProgramName, X.HostName, X.TableName, X.TypeSQL, X.UsuCod,
							   X.ColumnUpdate, X.ValueOld, X.ValueNew
                              from(SELECT Getdate()							as DateDML, 
                                     User_name()							as DatabaseUser, 
                                     Suser_name()							as LoginUser, 
                                     Original_login()						as LoginUserSQLTransaction,                                      
                                     Program_name()							as ProgramName, 
                                     Host_name()							as HostName, 
                                     'CADUSUARIOS'							as TableName,
									 @Action								as TypeSQL, 
                                     UsuCod									as UsuCod, 
                                     Isnull(@NomeCol, '')					as ColumnUpdate, 
                                     Isnull((SELECT 
									E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)') 
									FROM @DeletedTMP.nodes('.') E(e)), '')  as ValueOld, 
									 Isnull((SELECT 
									E.e.value('(/Inserted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]', 'varchar(100)') 
									FROM @InsertedTMP.nodes('.') E(e)), '') as ValueNew 
							   FROM inserted AS Ins 
							   ) as X
							   WHERE X.ValueNew <> X.ValueOld -- Traz somente os campos com valores alterados
							END 
					END --fim do while
			END --condicional I e U 
		END --fim do else
END 

GO
