USE YOUR_DATABASE
GO

ALTER TRIGGER tr_Produtos_LogUID 
ON PRODUTOS
WITH ENCRYPTION
FOR DELETE, INSERT, UPDATE
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
	  	 
      -- Coloca a tabela Deleted em uma vari�vel XML, conforme campos otimizados
	   SET @Deleted = (SELECT [ProCod], [ProNom], [ProFamCod], [ProGrpCod], [ProSubCod], [ProSituacao], [ProTip], [ProTipPrc], [ProCodArea], [ProNomRed], [ProNomEmbCompra], [ProQtdEmbEstoque], 
	   [ProNomEmbEstoque], [ProEmbConv], [ProVlrPeso], [ProVlrPLiq], [ProNomMarFab], [ProVlrIpi], [ProTipIcms], [ProVlrISS], [ProVlrMargen], [ProVasCod], [ProOpeCod], [ProTipFrt], [ProTipFun], 
	   [ProTipDev], [ProTipDepFrt], [ProDiaVct], [ProTipOrigem], [ProTipTrb], [ProDatInc], [ProPerPis], [ProPerCofins], [ProTipNota], [ProClaTox], [ProDesPriAtivo], [ProBasPisCofins], 
	   [ProAtvFim], [ProFlag1], [ProFlag2], [ProFlag3], [ProFlag4], [ProFlag5], [ProFlag6], [ProFlag7], [ProFlag8], [ProFlag9], [ProFlag0], [ProFlag10], [ProFlag11], [ProFlag12], [ProFlag13], 
	   [ProFlag14], [ProFlag15], [ProTipDem], [ProTraCod], [ProNomCie], [ProAgrCod], [ProVlrDes], [ProNbmCod], [ProMapa], [ProCodFormu], [ProConcen], [ProSitTrbIpi], [ProSitTrbPis], 
	   [ProMarVlrAgr], [ProNumOnu], [ProNumRis], [ProFlag16], [ProFlag17], [ProFlag18], [ProFlag19], [ProFlag20], [ProCtaCod], [ProCenCusCod], [ProCodServ], [GenCod], [ProLocal], 
	   [ProPerFundesa], [ProFlag21], [ProFlag22], [ProFlag23], [ProFlag24], [ProFlag25], [ProFlag26], [ProFlag27], [ProFlag28], [ProFlag29], [ProFlag30], [ProUsuCod], [ProIndCod], [ProGruStCod], 
	   [ProStTipPreco], [ProMovFilCod], [ProTipPvd], [ProFlag31], [ProFlag32], [ProFlag33], [ProFlag34], [ProFlag35], [ProCodEAN], [ProCodTipi], [TabTribCod], [ProQtdEmbPCP], [ProUndReferencial], 
	   [ProFatConversao], [ProQtdMinima], [ProQtdMaxima], [ProDatConCom], [ProClaRecCod], [ProFlag36], [ProFlag37], [ProFlag38], [ProFlag39], [ProFlag40], [ProFlag41], [ProFlag42], [ProFlag43], 
	   [ProFlag44], [ProFlag45], [ProFlag46], [ProFlag47], [ProFlag48], [ProFlag49], [ProFlag50], [ProQtdEmbVenda], [ProCalibre], [ProNbmExCod], [ProBarDis], [ProBarDisplay], [ProConvDisplay], 
	   [TabNutCod], [ProNomEmbTributavel], [ProANPCod], [ProPerBonDAP], [ProCodAuxInt], [ProTriAlqNac], [ProTriAlqImp], [TabConfPisCofCod], [ProCodTroca], [ProQtdLiberada], [ProCompImp], 
	   [ProPercMarVenInd], [ProLogConferido], [ProNorPalTipo], [ProNorPalLastro], [ProNorPalCamada], [ProDadEmbAltura], [ProDadEmbLargura], [ProDadEmbComprimento], [ProTipIncLeite], [ProCodVas], 
	   [ClaSerCod], [RecCod], [ProTabComCod], [ProTabComposicao], [ProRecomendacao], [ProUmiMax], [ProImpDesc], [ProClasComercial], [ProTipCalcImpureza], [ProDAP], [ProLimVlrFix], [ProFlag51], 
	   [ProFlgIntacta], [SimilarId], [ProRefCod], [CodVinculado], [ProFlag52], [ProFlag60], [ProFlag59], [ProFlag58], [ProFlag57], [ProFlag56], [ProFlag55], [ProFlag54], [ProFlag53], [ProFlag61], 
	   [ProCodUnificado], [ProFlag62], [ProFlag63], [ProConLeite], [ProCest], [ProFlag64]
					   FROM deleted FOR xml raw, root('Deleted'))       
     
	  -- Coloca a tabela Inserted em uma vari�vel XML, conforme campos otimizados
         SET @Inserted = (SELECT [ProCod], [ProNom], [ProFamCod], [ProGrpCod], [ProSubCod], [ProSituacao], [ProTip], [ProTipPrc], [ProCodArea], [ProNomRed], [ProNomEmbCompra], [ProQtdEmbEstoque], 
	   [ProNomEmbEstoque], [ProEmbConv], [ProVlrPeso], [ProVlrPLiq], [ProNomMarFab], [ProVlrIpi], [ProTipIcms], [ProVlrISS], [ProVlrMargen], [ProVasCod], [ProOpeCod], [ProTipFrt], [ProTipFun], 
	   [ProTipDev], [ProTipDepFrt], [ProDiaVct], [ProTipOrigem], [ProTipTrb], [ProDatInc], [ProPerPis], [ProPerCofins], [ProTipNota], [ProClaTox], [ProDesPriAtivo], [ProBasPisCofins], 
	   [ProAtvFim], [ProFlag1], [ProFlag2], [ProFlag3], [ProFlag4], [ProFlag5], [ProFlag6], [ProFlag7], [ProFlag8], [ProFlag9], [ProFlag0], [ProFlag10], [ProFlag11], [ProFlag12], [ProFlag13], 
	   [ProFlag14], [ProFlag15], [ProTipDem], [ProTraCod], [ProNomCie], [ProAgrCod], [ProVlrDes], [ProNbmCod], [ProMapa], [ProCodFormu], [ProConcen], [ProSitTrbIpi], [ProSitTrbPis], 
	   [ProMarVlrAgr], [ProNumOnu], [ProNumRis], [ProFlag16], [ProFlag17], [ProFlag18], [ProFlag19], [ProFlag20], [ProCtaCod], [ProCenCusCod], [ProCodServ], [GenCod], [ProLocal], 
	   [ProPerFundesa], [ProFlag21], [ProFlag22], [ProFlag23], [ProFlag24], [ProFlag25], [ProFlag26], [ProFlag27], [ProFlag28], [ProFlag29], [ProFlag30], [ProUsuCod], [ProIndCod], [ProGruStCod], 
	   [ProStTipPreco], [ProMovFilCod], [ProTipPvd], [ProFlag31], [ProFlag32], [ProFlag33], [ProFlag34], [ProFlag35], [ProCodEAN], [ProCodTipi], [TabTribCod], [ProQtdEmbPCP], [ProUndReferencial], 
	   [ProFatConversao], [ProQtdMinima], [ProQtdMaxima], [ProDatConCom], [ProClaRecCod], [ProFlag36], [ProFlag37], [ProFlag38], [ProFlag39], [ProFlag40], [ProFlag41], [ProFlag42], [ProFlag43], 
	   [ProFlag44], [ProFlag45], [ProFlag46], [ProFlag47], [ProFlag48], [ProFlag49], [ProFlag50], [ProQtdEmbVenda], [ProCalibre], [ProNbmExCod], [ProBarDis], [ProBarDisplay], [ProConvDisplay], 
	   [TabNutCod], [ProNomEmbTributavel], [ProANPCod], [ProPerBonDAP], [ProCodAuxInt], [ProTriAlqNac], [ProTriAlqImp], [TabConfPisCofCod], [ProCodTroca], [ProQtdLiberada], [ProCompImp], 
	   [ProPercMarVenInd], [ProLogConferido], [ProNorPalTipo], [ProNorPalLastro], [ProNorPalCamada], [ProDadEmbAltura], [ProDadEmbLargura], [ProDadEmbComprimento], [ProTipIncLeite], [ProCodVas], 
	   [ClaSerCod], [RecCod], [ProTabComCod], [ProTabComposicao], [ProRecomendacao], [ProUmiMax], [ProImpDesc], [ProClasComercial], [ProTipCalcImpureza], [ProDAP], [ProLimVlrFix], [ProFlag51], 
	   [ProFlgIntacta], [SimilarId], [ProRefCod], [CodVinculado], [ProFlag52], [ProFlag60], [ProFlag59], [ProFlag58], [ProFlag57], [ProFlag56], [ProFlag55], [ProFlag54], [ProFlag53], [ProFlag61], 
	   [ProCodUnificado], [ProFlag62], [ProFlag63], [ProConLeite], [ProCest], [ProFlag64]
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
														
						INSERT INTO IntegraTICravil.LogErp.ProdutosLogDML 
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
										'PRODUTOS',
										 @Action, 
										 ProCod,
										ISNULL(@NomeCol,''),
										ISNULL((SELECT
										E.e.value('(/Deleted/row[@ProCod = sql:column(INS.Procod)]/@Col)[1]','varchar(100)') 
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

                              INSERT INTO IntegraTICravil.LogErp.ProdutosLogDML 
                                        (DateDML, 
										 DatabaseUser, 
										 LoginUser, 
										 LoginUserSQLTransaction,                         
										 ProgramName, 
										 HostName, 
										 TableName,
										 TypeSQL, 
										 Procod, 
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
                                     'PRODUTOS'								as TableName,
									 @Action								as TypeSQL, 
                                     ProCod									as UsuCod, 
                                     Isnull(@NomeCol, '')					as ColumnUpdate, 
                                     Isnull((SELECT 
									E.e.value('(/Deleted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)') 
									FROM @DeletedTMP.nodes('.') E(e)), '')  as ValueOld, 
									 Isnull((SELECT 
									E.e.value('(/Inserted/row[@ProCod = sql:column(INS.ProCod)]/@Col)[1]', 'varchar(100)') 
									FROM @InsertedTMP.nodes('.') E(e)), '') as ValueNew 
								   FROM inserted AS Ins 
								   ) as X
								   WHERE X.ValueNew <> X.ValueOld -- isso deixar trazer somente os campos alterados
							END 
					END --fim do while				
END

GO


---------------------------------------------------------------------------------------------------------------------------------
----TABELA DE LOGS � Local onde a trigger acima registra os dados DML da tabela PRODUTOS
---------------------------------------------------------------------------------------------------------------------------------

--Use IntegraTICravil
--GO
--create table LogErp.ProdutosLogDML (
--	LogId int not null identity (1,1),
--	DateDML DateTime Default GetDate(),
--	DatabaseUser VarChar(100) Default User_Name(),
--	LoginUser Varchar(100) Default Suser_Name(),
--	LoginUserSQLTransaction Varchar(100) Default Original_Login(),	
--	ProgramName varchar(100) default program_name(),
--	HostName varchar(100) default host_name(),
--	TableName varchar(10) default 'PRODUTOS',
--	TypeSQL char(1) ,
--	Procod int not null,
--	ColumnUpdate sysname,  -- tipos de dados corresponde ao varchar(128) e j� seta not null tamb�m
--	ValueOld varchar(100) default '',
--	ValueNew varchar(100) default '',

--	constraint PK_ProdutosId primary key (LogId),	
--	constraint CK_TableNameProdutos check (TableName like 'PRODUTOS'),
--	constraint CK_TypeSQLProdutos check (TypeSQL in ('D','I','U'))	
--);





