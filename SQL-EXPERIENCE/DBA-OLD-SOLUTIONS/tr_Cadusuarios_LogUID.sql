USE [YOUR_DATABASE]
GO

ALTER TRIGGER [dbo].[tr_Cadusuarios_LogUID] 
ON [dbo].[CADUSUARIOS] 
WITH ENCRYPTION
FOR UPDATE, DELETE, INSERT 
AS 
  BEGIN 
      SET NOCOUNT ON 

      DECLARE @contador		  INT,			
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
      SET @qCols = (SELECT Count(*) 
                    FROM   sys.columns 
                    WHERE  object_id = (SELECT parent_id 
                                        FROM   sys.triggers 
                                        WHERE  object_id = @@procid)) 

      -- Coloca a tabela Deleted em uma vari�vel XML 
	  -- Otimizado para n�o trazer a coluna 'UsuUltEntrada' (27-07-2016)      
      SET @Deleted = (SELECT 
							UsuCod
							,EmpCod
							,UsuFilCod
							,UsuTraCod
							,UsuSenha							
							,UsuFlag1
							,UsuFlag2
							,UsuFlag3
							,UsuFlag4
							,UsuFlag5
							,UsuFlag6
							,UsuFlag7
							,UsuFlag8
							,UsuFlag9
							,UsuFlag0
							,UsuFlag10
							,UsuFlag11
							,UsuFlag12
							,UsuFlag13
							,UsuFlag14
							,UsuFlag15
							,UsuEmail
							,UsuConCod
							,UsuHisPreCod
							,UsuSenLiberacaoLimite
							--,UsuWorkstation  12/06/2017
							,UsuInativo
							,UsuFlag20
							,UsuFlag19
							,UsuFlag18
							,UsuFlag17
							,UsuFlag16
							,UsuFlag40
							,UsuFlag39
							,UsuFlag38
							,UsuFlag37
							,UsuFlag36
							,UsuFlag35
							,UsuFlag34
							,UsuFlag33
							,UsuFlag32
							,UsuFlag31
							,UsuFlag30
							,UsuFlag29
							,UsuFlag28
							,UsuFlag27
							,UsuFlag26
							,UsuFlag25
							,UsuFlag24
							,UsuFlag23
							,UsuFlag22
							,UsuFlag21
							,UsuFlag41
							,UsuFlag42
							,UsuLimLibTit
							,UsuTitAcessoRestrito
							,UsuFlagPesagem
							,UsuVerCodigo
							,UsuTipPesagem
							,UsuLimTraCredito
							,UsuSetCod
							,UsuSecCod
							,UsuCenCod
							,UsuLocBalRod
							,UsuFlag43
							,UsuDirTmp
							,UsuFlag44
							,UsuEtiZebraA
							,UsuEtiZebraB
							,UsuFlag45
							,UsuFlag46
							,UsuFlag47
							,UsuFlag48
							,UsuFlag50
							,UsuFlag49
							,UsuFlag51
							,UsuDescLim
							,UsuFlag52
							,UsuDashboard
							,UsuTipoAcesso
							,UsuAcreCredito
							,UsuFlag54
							,UsuDescValorNom
							,UsuFlag53
							,UsuFlag55
							,UsuFlag56
							,UsuFlag57
							,UsuFlag58
							,UsuFlag60
							,UsuFlag59
							,UsuFlag61
							,UsuFlag70
							,UsuFlag69
							,UsuFlag68
							,UsuFlag67
							,UsuFlag66
							,UsuFlag65
							,UsuFlag64
							,UsuFlag63
							,UsuFlag62
					  FROM deleted FOR xml raw, root('Deleted'))       
     
	  -- Coloca a tabela Inserted em uma vari�vel XML 
	  -- Otimizado para n�o trazer a coluna 'UsuUltEntrada' (27-07-2016)  
      SET @Inserted = (SELECT 
							UsuCod
							,EmpCod
							,UsuFilCod
							,UsuTraCod
							,UsuSenha							
							,UsuFlag1
							,UsuFlag2
							,UsuFlag3
							,UsuFlag4
							,UsuFlag5
							,UsuFlag6
							,UsuFlag7
							,UsuFlag8
							,UsuFlag9
							,UsuFlag0
							,UsuFlag10
							,UsuFlag11
							,UsuFlag12
							,UsuFlag13
							,UsuFlag14
							,UsuFlag15
							,UsuEmail
							,UsuConCod
							,UsuHisPreCod
							,UsuSenLiberacaoLimite
							--,UsuWorkstation 12/06/2017
							,UsuInativo
							,UsuFlag20
							,UsuFlag19
							,UsuFlag18
							,UsuFlag17
							,UsuFlag16
							,UsuFlag40
							,UsuFlag39
							,UsuFlag38
							,UsuFlag37
							,UsuFlag36
							,UsuFlag35
							,UsuFlag34
							,UsuFlag33
							,UsuFlag32
							,UsuFlag31
							,UsuFlag30
							,UsuFlag29
							,UsuFlag28
							,UsuFlag27
							,UsuFlag26
							,UsuFlag25
							,UsuFlag24
							,UsuFlag23
							,UsuFlag22
							,UsuFlag21
							,UsuFlag41
							,UsuFlag42
							,UsuLimLibTit
							,UsuTitAcessoRestrito
							,UsuFlagPesagem
							,UsuVerCodigo
							,UsuTipPesagem
							,UsuLimTraCredito
							,UsuSetCod
							,UsuSecCod
							,UsuCenCod
							,UsuLocBalRod
							,UsuFlag43
							,UsuDirTmp
							,UsuFlag44
							,UsuEtiZebraA
							,UsuEtiZebraB
							,UsuFlag45
							,UsuFlag46
							,UsuFlag47
							,UsuFlag48
							,UsuFlag50
							,UsuFlag49
							,UsuFlag51
							,UsuDescLim
							,UsuFlag52
							,UsuDashboard
							,UsuTipoAcesso
							,UsuAcreCredito
							,UsuFlag54
							,UsuDescValorNom
							,UsuFlag53
							,UsuFlag55
							,UsuFlag56
							,UsuFlag57
							,UsuFlag58
							,UsuFlag60
							,UsuFlag59
							,UsuFlag61
							,UsuFlag70
							,UsuFlag69
							,UsuFlag68
							,UsuFlag67
							,UsuFlag66
							,UsuFlag65
							,UsuFlag64
							,UsuFlag63
							,UsuFlag62
					   FROM inserted FOR xml raw, root('Inserted')) 

	  IF not exists(select top 1 null FROM inserted) --deleted
		BEGIN
			SELECT @action = 'D'FROM deleted			  
          		WHILE (@Col < @qCols)
					BEGIN
						SET @Col = @Col + 1
						SET @Pot = (@Col - 1) % 8 + 1
						SET @Pot = POWER(2,@Pot - 1)
						SET @bitVerificador = ((@Col - 1) / 8) + 1						
						SET @NomeCol = (SELECT Name 
										FROM sys.columns
										WHERE object_id = (SELECT Parent_ID 
														   FROM sys.triggers
														   WHERE object_id = @@procid) 
														   AND column_id = @Col)

						-- Substitui a TAG no XML da DELETED e faz a extra��o dos dados
						SET @DeletedTMP = REPLACE(CAST(@Deleted As VARCHAR(MAX)),@NomeCol + '=','Col=')
														
						INSERT INTO IntegraTICravil.LogErp.CadusuariosLogDML 
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
										ISNULL((SELECT
										E.e.value('(/Deleted/row[@UsuCod = sql:column(INS.UsuCod)]/@Col)[1]','varchar(100)') 
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
				 		 			     	                        
                  WHILE ( @Col < @qCols ) 
                    BEGIN 
                        SET @Col = @Col + 1 
                        SET @Pot = ( @Col - 1 ) % 8 + 1 
                        SET @Pot = Power(2, @Pot - 1) 
                        SET @bitVerificador = ( ( @Col - 1 ) / 8 ) + 1 

                        IF (Substring(Columns_updated(), @bitVerificador, 1) & @Pot > 0)
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
                              SET @DeletedTMP = Replace(Cast(@Deleted AS VARCHAR (max)),@NomeCol + '=','Col=') 

                              -- Substitui a TAG no XML da INSERTED e faz a extra��o dos dados 
                              SET @InsertedTMP = Replace(Cast(@Inserted AS VARCHAR(max)),@NomeCol + '=','Col=') 

                              INSERT INTO IntegraTICravil.LogErp.CadusuariosLogDML 
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
							   SELECT X.DateDML, X.DatabaseUser, X.LoginUser, X.LoginUserSQLTransaction,
							   X.ProgramName, X.HostName, X.TableName, X.TypeSQL, X.UsuCod,
							   X.ColumnUpdate, X.ValueOld, X.ValueNew
                               FROM(SELECT Getdate()						as DateDML, 
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
								   WHERE X.ValueNew <> X.ValueOld -- isso deixar trazer somente os campos alterados
							END 
					END --fim do while					
END 

GO

---------------------------------------------------------------------------------------------------------------------------------
-- TABELA DE LOGS � Local onde a trigger acima registra os dados DML da tabela CADUSUARIOS
---------------------------------------------------------------------------------------------------------------------------------

--Use IntegraTICravil
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
--	ColumnUpdate sysname,  -- tipos de dados corresponde ao varchar(128) e j� seta not null tamb�m
--	ValueOld varchar(100) default '',
--	ValueNew varchar(100) default '',

--	constraint PK_LogId primary key (LogId),	
--	constraint CK_TableName check (TableName like 'CADUSUARIOS'),
--	constraint CK_TypeSQL check (TypeSQL in ('D','I','U'))	
--);

