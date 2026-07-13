USE [YOUR_DATABASE]
GO

ALTER TRIGGER [dbo].[tr_Transacionadores_LogUD] 
ON [dbo].[TRANSACIONADORES] 
WITH ENCRYPTION 
FOR UPDATE, DELETE 
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
      SET @Deleted = (SELECT 
						  TraCod
						, TraNom
						, TraSit
						, TraDatEmissao
						, TraFilCod
						, TraNomFantasia
						, TraEnd
						, TraNumEnd
						, TraComplemento
						, TraBairro
						, TraPaiCod
						, TraEstCod
						, TraMunCod
						, TraLogCod
						, TraCep
						, TraCaixaPostal
						, TraFone
						, TraFax
						, TraCelular
						, TraEmail
						, TraNatJuridica
						, TraNatFiscal
						, TraNatComercial
						, TraNatSocial
						, TraCpf
						, TraCnpj
						, TraPlaca
						, TraUsuCod
						, TraFlag3
						, TraFlag4
						, TraFlag5
						, TraFlag6
						, TraFlag7
						, TraRetISS
						, TraRg
						, TraOrgExpedidor
						, TraNumCartProf
						, TraNumSerCartProf
						, TraNumTitulo
						, TraNumCnh
						, TraNumInscProdutor
						, TraSexo
						, TraEndComercial
						, TraProfissao
						, TraFoneComercial
						, TraFiliacao
						, TraTipoMoradia
						, TraGrauInstrucao
						, TraDatNasc
						, TraDatFalecimento
						, TraEstCivil
						, TraRegCasamento
						, TraRegCivil
						, TraLocNasc
						, TraNascional
						, TraProcedencia
						, TraDatProcedencia
						, TraRegCrea
						, TraNumART
						, TraNumMaxArt
						, TraRecImpArt
						, TraUltRec
						, TraFlag2
						, TraMatCod
						, TraInsMun
						, TraInscEstadual
						, TraNumRegJuntaComercial
						, TraEstJuntaComercial
						, TraResponsavel
						, TraCpfResponsavel
						, TraCargoResponsavel
						, TraContato
						, TraVendedor
						, TraPrzTipo
						, TraPercDist
						, TraFlag1
						, TraQualTipo
						, TraNumCidasc
						, TraMatSocio
						, TraAtaAdmissao
						, TraDatAdmissao
						, TraAtaSaida
						, TraDatSaida
						, TraTipoSaida
						, TraAverbTermExcl
						, TraSalInte
						, TraSalSubs
						, TraSalUfir
						, TraSalRest
						, TraSitCredito
						, TraVlrLimiteCred
						, TraIndCod
						, TraVlrCheLim
						, TraIndCheLim
						, TraCnvCod
						, TraFormaRecebimento
						, TraBanCod
						, TraAgeCod
						, TraCodContaBanco
						, TraSitSpc
						, TraSitSci
						, TraSitSerasa
						, TraCodCus
						, TraPerComis
						, TraPlaCod
						, TraIndCtb
						, TraComDif
						, TraCEnd
						, TraCBairro
						, TraCPaiCod
						, TraCEstCod
						, TraCMunCod
						, TraCLogCod
						, TraCCep
						, TraCCaiPos
						, TraCFon
						, TraCFax
						, TraCEma
						, TraCodIdOpOnline
						, TraAtiPrincipal
						, TraAtiFutura
						, TraCerMilho
						, TraCerSoja
						, TraCerFeijao
						, TraCerTrigo
						, TraAreRef
						, TraCitricultura
						, TraCitArea
						, TraSuiMod
						, TraSuiCab
						, TraSuiInt
						, TraLtsMod
						, TraLtsMat
						, TraLtsInt
						, TraAveMod
						, TraAveMet
						, TraAveInt
						, TraLeiNumVac
						, TraLeiDia
						, TraLeiForn
						, TraLeiSil
						, TraLeiVoi
						, TraGado
						, TraGadCab
						, TraGadFor
						, TraRenda
						, TraFilMae
						, TraConjuge
						, TraConjugeCPF
						, TraComLocTra
						, TraComNum
						, TraComCom
						, TraComCxPostal
						, TraComBairro
						, TraComDatAdm
						, TraComCep
						, TraComPaiCod
						, TraComEstCod
						, TraComMunCod
						, TraComEmail
						, TraTemRes
						, TraRamal
						, TraConjugeRenda
						, TraConjugeDatNas
						, TraAreMec
						, TraResLegal
						, TraAverbacao
						, TraRecSerie
						, TermOpcao
						, TraMapa
						, TraNIRF
						, TraRendaAgricula
						, TraRendaAnimal
						, TraAtiSecundaria
						, TraRendaOutros
						, TraPossuiRegMDA_DAP
						, TraProdutorRural
						, TraOutraAtividade
						, TraNumRegMDA_DAP
						, TraTipoProdutor
						, TraFilSindicatoRural
						, TraFilSindicatoTrabRurais
						, TraPossuiLicAmbiental
						, TraPossuiOutorgaAgua
						, TraCapSiloRacao
						, TraPerDesProDest
						, TraPerDesProEmi
						, TraCEndNum
						, TraTipResfriador
						, TraCapResLeite
						, TraSocSobras
						, TraDatLibCrediario
						, ClassCod
						, TraCodIntFolha
						, TraNumINSS
						, TraFlag10
						, TraFlag11
						, TraFlag12
						, TraFlag13
						, TraFlag14
						, TraFlag15
						, TraFlag8
						, TraFlag9
						, TraDatVctDAP
						, TraNumDAP
						, TraCnaeCod
						, TraRotCod
						, TabTribTranTraCod
						, TraBolBanCod
						, TraTecCodRes
						, TraAtaAdmissao2
						, TraAtaSaida2
						, TraWSHost
						, TraWSBaseUrl
						, TraWSPost
						, TraWSSOAPAction
						, TraWSTagFuncEnv
						, TraWSTagFuncEnvAtrib
						, TraWSTagElementEnv1
						, TraWSTagElementEnv2
						, TraWSTagElementEnv3
						, TraWSTagFuncRet
						, TraWSTagFuncRetAtrib
						, TraWSTagElementRet1
						, TraWSTagElementRet2
						, TraWSTagElementRet3
						, TraDatConCom
						, TraVlrDAP
						, TraGerXmlCargas
						, TraVlrMenArm
						, TraOpeCodCTRC
						, TraCodSigaCred
						, TraFlag16
						, TraFlag17
						, TraFlag18
						, TraFlag19
						, TraFlag20
						, TraEstimColheitaMilho
						, TraEstimColheitaSoja
						, TraEstimColheitaTrigo
						, TraEstimColheitaFeijao
						, TraSuiAreaChiqueiro
						, TraSuiIntTraCod
						, TraAveIntTraCod
						, TraLeiNumVacasSecas
						, TraLeiNumNovilhas
						, TraLeiAreaPastagemPemanente
						, TraLeiAreaPastagemAnual
						, TraLeiIntTraCod
						, TraLeiIntTraNom
						, TraAreaSilagem
						, TraAreaGraos
						, TraPrevisaoCultivoMilho
						, TraEstagioLavouraMilho
						, TraCondicaoLavouraMilho
						, TraPrevisaoCultivoSoja
						, TraEstagioLavouraSoja
						, TraCondicaoLavouraSoja
						, TraPrevisaoCultivoTrigo
						, TraEstagioLavouraTrigo
						, TraCondicaoLavouraTrigo
						, TraPrevisaoCultivoFeijao
						, TraEstagioLavouraFeijao
						, TraCondicaoLavouraFeijao
						, TraEntEndereco
						, TraEntNumero
						, TraEntComplemento
						, TraEntBairro
						, TraEntCep
						, TraEntPaiCod
						, TraEntEstCod
						, TraEntMunCod
						, TraEntLogCod
						, TraEntCaiPostal
						, TraEntEmail
						, TraEntFone
						, TraEntFax
						, TraEntCelular
						, TraEntObs
						, TraDiasVectoIONICS
						, TraDapVlrUti
						, TraRodoCartao
						, TraRNTRC
						, TraCartaoConsumidor
						, TraLongitude
						, TraLatitude
						, TraPedVacMatriz
						, TraCodAux
						, TraGerContraNota
						, TraRede
						, TraTipFrete
						, TraGrpCod
						, TraDesLeite
						, TraDocLeite
						, TraRendaDatAlt
						, TraMotDemissao
						, TraEtilei
						, TraDatUltRevisao
						, TraFlag21
						, TraCodCon
						, TraSenCre
						, TraEmHectares
						, TraUsuario
						, TraSenha
						, TraClaProdutor
						, TraTranspCod
						, TraMatIntegracao
						, TraMatAntiga
						, TraDatReadmissao
						, TraReadmitido
						, TraParPeculio
						, TraJoia
						, TraCartaoConsFlag
						, TraEntExec
						, TraSaiExec
						, TraConvVarejo
						, TraObsFinanceira
						, TraTipCobranca
						, TraDescBoleto
						, TraPagFrete
						, TraSitCartorio
						, TraPerMercado
						, TraPerConsumo
						, TraPerPosto
						, TraPagFornecedor
						, TraDatRais
						, TraVincCotrijuc
						, TraNumProcesso
						, TraOriProcesso
						, TraDatFimProcesso
						, TraDatIniProcesso
						, TraExecJudicial
						, TraAdvCod
						, TraConjugeDatAdmissao
						, TraNumPis
						, TraDescContaCapital
						, TraDescFunrural
						, TraDescSenar
						, TraMsgExtrato
						, TraCodCbo
						, TraPisPasep
						, TraCliIndustria
						, TraCEndComp
						, TraCodFiador
						, TraCnaeCod2
						, TraEnquadDAP
						, TraControleFrota
						, TraNucCod
						, NucCod
						, NucLocCod
						, TraDesAtiLeite
						, TraNumSuframa
						, TraFlag22
						, TraDescINSS
						, TraTipoFretePadrao
						, TraANTTValidade
						, TraANTTNum
						, TraValCnh
						, TraRegCnh
						, TraCatCnh
						, TraUFCartProf
						, TraBoleto
						, TraSalCreGeral
						, TraSalCreMensal
						, TraLimCreGeral
						, TraLimCreMensal
						, TraPermiteTroca
						, TraTemCertificado
						, TraFlgExpTrr
						, TraFlag23
						, TraISO9001
						, TraModReceituario
						, TraDatAlteracaoGer
						, TraPlaca3
						, TraPlaca2
						, TraMunCodSefazRS
						, TraSitScpc
						, TraLogSIGACod
						, TraSolicitaNumPedido
						, TraCodInsANPT008
						, TraTrrScancCat
						, TraDPMPAgente
						, TraClaEstSituacao
						, TraClaEstSeq
						, TraMatFolha
						, TraCrmv
					  FROM deleted FOR xml raw, root('Deleted'))       
     
	  -- Coloca a tabela Inserted em uma vari�vel XML 
      SET @Inserted = (SELECT 
						  TraCod
						, TraNom
						, TraSit
						, TraDatEmissao
						, TraFilCod
						, TraNomFantasia
						, TraEnd
						, TraNumEnd
						, TraComplemento
						, TraBairro
						, TraPaiCod
						, TraEstCod
						, TraMunCod
						, TraLogCod
						, TraCep
						, TraCaixaPostal
						, TraFone
						, TraFax
						, TraCelular
						, TraEmail
						, TraNatJuridica
						, TraNatFiscal
						, TraNatComercial
						, TraNatSocial
						, TraCpf
						, TraCnpj
						, TraPlaca
						, TraUsuCod
						, TraFlag3
						, TraFlag4
						, TraFlag5
						, TraFlag6
						, TraFlag7
						, TraRetISS
						, TraRg
						, TraOrgExpedidor
						, TraNumCartProf
						, TraNumSerCartProf
						, TraNumTitulo
						, TraNumCnh
						, TraNumInscProdutor
						, TraSexo
						, TraEndComercial
						, TraProfissao
						, TraFoneComercial
						, TraFiliacao
						, TraTipoMoradia
						, TraGrauInstrucao
						, TraDatNasc
						, TraDatFalecimento
						, TraEstCivil
						, TraRegCasamento
						, TraRegCivil
						, TraLocNasc
						, TraNascional
						, TraProcedencia
						, TraDatProcedencia
						, TraRegCrea
						, TraNumART
						, TraNumMaxArt
						, TraRecImpArt
						, TraUltRec
						, TraFlag2
						, TraMatCod
						, TraInsMun
						, TraInscEstadual
						, TraNumRegJuntaComercial
						, TraEstJuntaComercial
						, TraResponsavel
						, TraCpfResponsavel
						, TraCargoResponsavel
						, TraContato
						, TraVendedor
						, TraPrzTipo
						, TraPercDist
						, TraFlag1
						, TraQualTipo
						, TraNumCidasc
						, TraMatSocio
						, TraAtaAdmissao
						, TraDatAdmissao
						, TraAtaSaida
						, TraDatSaida
						, TraTipoSaida
						, TraAverbTermExcl
						, TraSalInte
						, TraSalSubs
						, TraSalUfir
						, TraSalRest
						, TraSitCredito
						, TraVlrLimiteCred
						, TraIndCod
						, TraVlrCheLim
						, TraIndCheLim
						, TraCnvCod
						, TraFormaRecebimento
						, TraBanCod
						, TraAgeCod
						, TraCodContaBanco
						, TraSitSpc
						, TraSitSci
						, TraSitSerasa
						, TraCodCus
						, TraPerComis
						, TraPlaCod
						, TraIndCtb
						, TraComDif
						, TraCEnd
						, TraCBairro
						, TraCPaiCod
						, TraCEstCod
						, TraCMunCod
						, TraCLogCod
						, TraCCep
						, TraCCaiPos
						, TraCFon
						, TraCFax
						, TraCEma
						, TraCodIdOpOnline
						, TraAtiPrincipal
						, TraAtiFutura
						, TraCerMilho
						, TraCerSoja
						, TraCerFeijao
						, TraCerTrigo
						, TraAreRef
						, TraCitricultura
						, TraCitArea
						, TraSuiMod
						, TraSuiCab
						, TraSuiInt
						, TraLtsMod
						, TraLtsMat
						, TraLtsInt
						, TraAveMod
						, TraAveMet
						, TraAveInt
						, TraLeiNumVac
						, TraLeiDia
						, TraLeiForn
						, TraLeiSil
						, TraLeiVoi
						, TraGado
						, TraGadCab
						, TraGadFor
						, TraRenda
						, TraFilMae
						, TraConjuge
						, TraConjugeCPF
						, TraComLocTra
						, TraComNum
						, TraComCom
						, TraComCxPostal
						, TraComBairro
						, TraComDatAdm
						, TraComCep
						, TraComPaiCod
						, TraComEstCod
						, TraComMunCod
						, TraComEmail
						, TraTemRes
						, TraRamal
						, TraConjugeRenda
						, TraConjugeDatNas
						, TraAreMec
						, TraResLegal
						, TraAverbacao
						, TraRecSerie
						, TermOpcao
						, TraMapa
						, TraNIRF
						, TraRendaAgricula
						, TraRendaAnimal
						, TraAtiSecundaria
						, TraRendaOutros
						, TraPossuiRegMDA_DAP
						, TraProdutorRural
						, TraOutraAtividade
						, TraNumRegMDA_DAP
						, TraTipoProdutor
						, TraFilSindicatoRural
						, TraFilSindicatoTrabRurais
						, TraPossuiLicAmbiental
						, TraPossuiOutorgaAgua
						, TraCapSiloRacao
						, TraPerDesProDest
						, TraPerDesProEmi
						, TraCEndNum
						, TraTipResfriador
						, TraCapResLeite
						, TraSocSobras
						, TraDatLibCrediario
						, ClassCod
						, TraCodIntFolha
						, TraNumINSS
						, TraFlag10
						, TraFlag11
						, TraFlag12
						, TraFlag13
						, TraFlag14
						, TraFlag15
						, TraFlag8
						, TraFlag9
						, TraDatVctDAP
						, TraNumDAP
						, TraCnaeCod
						, TraRotCod
						, TabTribTranTraCod
						, TraBolBanCod
						, TraTecCodRes
						, TraAtaAdmissao2
						, TraAtaSaida2
						, TraWSHost
						, TraWSBaseUrl
						, TraWSPost
						, TraWSSOAPAction
						, TraWSTagFuncEnv
						, TraWSTagFuncEnvAtrib
						, TraWSTagElementEnv1
						, TraWSTagElementEnv2
						, TraWSTagElementEnv3
						, TraWSTagFuncRet
						, TraWSTagFuncRetAtrib
						, TraWSTagElementRet1
						, TraWSTagElementRet2
						, TraWSTagElementRet3
						, TraDatConCom
						, TraVlrDAP
						, TraGerXmlCargas
						, TraVlrMenArm
						, TraOpeCodCTRC
						, TraCodSigaCred
						, TraFlag16
						, TraFlag17
						, TraFlag18
						, TraFlag19
						, TraFlag20
						, TraEstimColheitaMilho
						, TraEstimColheitaSoja
						, TraEstimColheitaTrigo
						, TraEstimColheitaFeijao
						, TraSuiAreaChiqueiro
						, TraSuiIntTraCod
						, TraAveIntTraCod
						, TraLeiNumVacasSecas
						, TraLeiNumNovilhas
						, TraLeiAreaPastagemPemanente
						, TraLeiAreaPastagemAnual
						, TraLeiIntTraCod
						, TraLeiIntTraNom
						, TraAreaSilagem
						, TraAreaGraos
						, TraPrevisaoCultivoMilho
						, TraEstagioLavouraMilho
						, TraCondicaoLavouraMilho
						, TraPrevisaoCultivoSoja
						, TraEstagioLavouraSoja
						, TraCondicaoLavouraSoja
						, TraPrevisaoCultivoTrigo
						, TraEstagioLavouraTrigo
						, TraCondicaoLavouraTrigo
						, TraPrevisaoCultivoFeijao
						, TraEstagioLavouraFeijao
						, TraCondicaoLavouraFeijao
						, TraEntEndereco
						, TraEntNumero
						, TraEntComplemento
						, TraEntBairro
						, TraEntCep
						, TraEntPaiCod
						, TraEntEstCod
						, TraEntMunCod
						, TraEntLogCod
						, TraEntCaiPostal
						, TraEntEmail
						, TraEntFone
						, TraEntFax
						, TraEntCelular
						, TraEntObs
						, TraDiasVectoIONICS
						, TraDapVlrUti
						, TraRodoCartao
						, TraRNTRC
						, TraCartaoConsumidor
						, TraLongitude
						, TraLatitude
						, TraPedVacMatriz
						, TraCodAux
						, TraGerContraNota
						, TraRede
						, TraTipFrete
						, TraGrpCod
						, TraDesLeite
						, TraDocLeite
						, TraRendaDatAlt
						, TraMotDemissao
						, TraEtilei
						, TraDatUltRevisao
						, TraFlag21
						, TraCodCon
						, TraSenCre
						, TraEmHectares
						, TraUsuario
						, TraSenha
						, TraClaProdutor
						, TraTranspCod
						, TraMatIntegracao
						, TraMatAntiga
						, TraDatReadmissao
						, TraReadmitido
						, TraParPeculio
						, TraJoia
						, TraCartaoConsFlag
						, TraEntExec
						, TraSaiExec
						, TraConvVarejo
						, TraObsFinanceira
						, TraTipCobranca
						, TraDescBoleto
						, TraPagFrete
						, TraSitCartorio
						, TraPerMercado
						, TraPerConsumo
						, TraPerPosto
						, TraPagFornecedor
						, TraDatRais
						, TraVincCotrijuc
						, TraNumProcesso
						, TraOriProcesso
						, TraDatFimProcesso
						, TraDatIniProcesso
						, TraExecJudicial
						, TraAdvCod
						, TraConjugeDatAdmissao
						, TraNumPis
						, TraDescContaCapital
						, TraDescFunrural
						, TraDescSenar
						, TraMsgExtrato
						, TraCodCbo
						, TraPisPasep
						, TraCliIndustria
						, TraCEndComp
						, TraCodFiador
						, TraCnaeCod2
						, TraEnquadDAP
						, TraControleFrota
						, TraNucCod
						, NucCod
						, NucLocCod
						, TraDesAtiLeite
						, TraNumSuframa
						, TraFlag22
						, TraDescINSS
						, TraTipoFretePadrao
						, TraANTTValidade
						, TraANTTNum
						, TraValCnh
						, TraRegCnh
						, TraCatCnh
						, TraUFCartProf
						, TraBoleto
						, TraSalCreGeral
						, TraSalCreMensal
						, TraLimCreGeral
						, TraLimCreMensal
						, TraPermiteTroca
						, TraTemCertificado
						, TraFlgExpTrr
						, TraFlag23
						, TraISO9001
						, TraModReceituario
						, TraDatAlteracaoGer
						, TraPlaca3
						, TraPlaca2
						, TraMunCodSefazRS
						, TraSitScpc
						, TraLogSIGACod
						, TraSolicitaNumPedido
						, TraCodInsANPT008
						, TraTrrScancCat
						, TraDPMPAgente
						, TraClaEstSituacao
						, TraClaEstSeq
						, TraMatFolha
						, TraCrmv
					   FROM inserted FOR xml raw, root('Inserted')) 

	  IF not exists(select top 1 null FROM inserted) --deleted
		BEGIN
			SELECT @action = 'D' FROM deleted			  
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
														
						INSERT INTO IntegraTICravil.LogErp.TransacionadorLogDML
									(
										DateDML, 
										DatabaseUser, 
										LoginUser, 
										LoginUserSQLTransaction, 											
										ProgramName,
										HostName,
										TableName,
										TypeSQL,
										Tracod,
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
										'TRANSACIONADORES',
										 @Action, 
										 TraCod,	--CAMPO CHAVE
										ISNULL(@NomeCol,''),
										ISNULL((SELECT
										E.e.value('(/Deleted/row[@TraCod = sql:column(INS.TraCod)]/@Col)[1]','varchar(100)') 
										FROM @DeletedTMP.nodes('.') E(e)), '') As ValueOld
								
									FROM deleted As Ins											
					END -- WHILE		  

		END -- condi��o delete		
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

                              INSERT INTO IntegraTICravil.LogErp.TransacionadorLogDML 
                                        (DateDML, 
										 DatabaseUser, 
										 LoginUser, 
										 LoginUserSQLTransaction,                         
										 ProgramName, 
										 HostName, 
										 TableName,
										 TypeSQL, 
										 Tracod,	
										 ColumnUpdate, 
										 ValueOld, 
										 ValueNew)
							   SELECT X.DateDML, X.DatabaseUser, X.LoginUser, X.LoginUserSQLTransaction,
							   X.ProgramName, X.HostName, X.TableName, X.TypeSQL, X.TraCod, --CAMPO CHAVE
							   X.ColumnUpdate, X.ValueOld, X.ValueNew
                               FROM(SELECT Getdate()						as DateDML, 
                                     User_name()							as DatabaseUser, 
                                     Suser_name()							as LoginUser, 
                                     Original_login()						as LoginUserSQLTransaction,                                      
                                     Program_name()							as ProgramName, 
                                     Host_name()							as HostName, 
                                     'TRANSACIONADORES'						as TableName,
									 @Action								as TypeSQL, 
                                     TraCod									as TraCod, 
                                     Isnull(@NomeCol, '')					as ColumnUpdate, 
                                     Isnull((SELECT 
									E.e.value('(/Deleted/row[@TraCod = sql:column(INS.TraCod)]/@Col)[1]', 'varchar(100)') 
									FROM @DeletedTMP.nodes('.') E(e)), '')  as ValueOld, 
									 Isnull((SELECT 
									E.e.value('(/Inserted/row[@TraCod = sql:column(INS.TraCod)]/@Col)[1]', 'varchar(100)') 
									FROM @InsertedTMP.nodes('.') E(e)), '') as ValueNew 
								   FROM inserted AS Ins 
								   ) as X
								   WHERE X.ValueNew <> X.ValueOld -- isso deixar trazer somente os campos alterados
							END 
					END --fim do while					
END 

GO


------------------------------------------------------------------------------------------------------------------------------
-- Tabela dos logs de altera��o ou exclus�o da tabela transacionadores
------------------------------------------------------------------------------------------------------------------------------

--USE IntegraTICravil
--GO

--CREATE TABLE LogErp.TransacionadorLogDML
--(
--	[LogId] [int] identity(1,1) NOT NULL primary key,
--	[DateDML] [datetime]  DEFAULT (getdate()),
--	[DatabaseUser] [varchar](100)  DEFAULT (user_name()),
--	[LoginUser] [varchar](100)  DEFAULT (suser_name()),
--	[LoginUserSQLTransaction] [varchar](100)  DEFAULT (original_login()),
--	[ProgramName] [varchar](100)  DEFAULT (program_name()),
--	[HostName] [varchar](100)  DEFAULT (host_name()),
--	[TableName] [varchar](30)  DEFAULT ('TRANSACIONADORES'),
--	[TypeSQL] [char](1) ,
--	[Tracod] [int] NOT NULL,
--	[ColumnUpdate] [sysname] NOT NULL,
--	[ValueOld] [varchar](100)  DEFAULT (''),
--	[ValueNew] [varchar](100)  DEFAULT (''),

--	CONSTRAINT [CK_TableName_Transacionador] CHECK  (([TableName] like 'TRANSACIONADORES')),
--	CONSTRAINT [CK_TypeSQL_Transacionador] CHECK  (([TypeSQL]='U' OR [TypeSQL]='I' OR [TypeSQL]='D'))
--)





