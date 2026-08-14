/*
 *
    OBJETIVO: Trigger de auditoria para operações de UPDATE e DELETE na tabela TRANSACIONADORES,
              registrando todas as alterações e exclusões em uma tabela de log com
              valores antigos e novos por coluna alterada.
    PROJETO: mssqlserver-solution-explorer
 *  
 */
USE [YOUR_DATABASE]
GO

CREATE OR ALTER TRIGGER [dbo].[tr_Transacionadores_LogUD]
ON [dbo].[TRANSACIONADORES]
WITH ENCRYPTION
FOR UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @contador         INT
          , @action           CHAR(15)
          , @Col              INT
          , @qCols            INT
          , @NomeCol          VARCHAR(100)
          , @bitVerificador   INT
          , @Pot              INT

    DECLARE @Inserted        XML
          , @InsertedTMP     XML

    DECLARE @Deleted         XML
          , @DeletedTMP      XML

    -- ============================================================
    -- Conta quantas colunas existem na tabela contemplada pela Trigger
    -- ============================================================
    SET @Col = 0
    SET @qCols =
    (
        SELECT COUNT(*)
        FROM sys.columns
        WHERE object_id =
        (
            SELECT parent_id
            FROM sys.triggers
            WHERE object_id = @@procid
        )
    )

    -- ============================================================
    -- Coloca a tabela Deleted em uma variável XML
    -- ============================================================
    SET @Deleted =
    (
        SELECT
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
        FROM deleted
        FOR XML RAW, ROOT('Deleted')
    )

    -- ============================================================
    -- Coloca a tabela Inserted em uma variável XML
    -- ============================================================
    SET @Inserted =
    (
        SELECT
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
        FROM inserted
        FOR XML RAW, ROOT('Inserted')
    )

    -- ============================================================
    -- Processamento para operação de DELETE
    -- ============================================================
    IF NOT EXISTS (SELECT TOP 1 NULL FROM inserted)
    BEGIN
        SELECT @action = 'D' FROM deleted

        WHILE (@Col < @qCols)
        BEGIN
            SET @Col = @Col + 1
            SET @Pot = (@Col - 1) % 8 + 1
            SET @Pot = POWER(2, @Pot - 1)
            SET @bitVerificador = ((@Col - 1) / 8) + 1
            SET @NomeCol =
            (
                SELECT Name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT Parent_ID
                    FROM sys.triggers
                    WHERE object_id = @@procid
                )
                AND column_id = @Col
            )

            -- ============================================================
            -- Substitui a TAG no XML da DELETED e faz a extração dos dados
            -- ============================================================
            SET @DeletedTMP = REPLACE(CAST(@Deleted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            INSERT INTO DBA_PerformanceHub.LogErp.TransacionadorLogDML
            (
                  DateDML
                , DatabaseUser
                , LoginUser
                , LoginUserSQLTransaction
                , ProgramName
                , HostName
                , TableName
                , TypeSQL
                , Tracod
                , ColumnUpdate
                , ValueOld
            )
            SELECT
                  GETDATE()
                , USER_NAME()
                , SUSER_NAME()
                , ORIGINAL_LOGIN()
                , PROGRAM_NAME()
                , HOST_NAME()
                , 'TRANSACIONADORES'
                , @Action
                , TraCod
                , ISNULL(@NomeCol, '')
                , ISNULL(
                  (
                      SELECT E.e.value('(/Deleted/row[@TraCod = sql:column(INS.TraCod)]/@Col)[1]', 'varchar(100)')
                      FROM @DeletedTMP.nodes('.') AS E(e)
                  ), '') AS ValueOld
            FROM deleted AS Ins
        END
    END
    ELSE
    BEGIN
        SELECT @action = 'U' FROM deleted
    END

    -- ============================================================
    -- Processamento para operação de UPDATE
    -- ============================================================
    WHILE (@Col < @qCols)
    BEGIN
        SET @Col = @Col + 1
        SET @Pot = (@Col - 1) % 8 + 1
        SET @Pot = POWER(2, @Pot - 1)
        SET @bitVerificador = ((@Col - 1) / 8) + 1

        IF (SUBSTRING(Columns_updated(), @bitVerificador, 1) & @Pot > 0)
        BEGIN
            SET @NomeCol =
            (
                SELECT Name
                FROM sys.columns
                WHERE object_id =
                (
                    SELECT parent_id
                    FROM sys.triggers
                    WHERE object_id = @@procid
                )
                AND column_id = @Col
            )

            -- ============================================================
            -- Substitui a TAG no XML da DELETED e faz a extração dos dados
            -- ============================================================
            SET @DeletedTMP = REPLACE(CAST(@Deleted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            -- ============================================================
            -- Substitui a TAG no XML da INSERTED e faz a extração dos dados
            -- ============================================================
            SET @InsertedTMP = REPLACE(CAST(@Inserted AS VARCHAR(MAX)), @NomeCol + '=', 'Col=')

            INSERT INTO DBA_PerformanceHub.LogErp.TransacionadorLogDML
            (
                  DateDML
                , DatabaseUser
                , LoginUser
                , LoginUserSQLTransaction
                , ProgramName
                , HostName
                , TableName
                , TypeSQL
                , Tracod
                , ColumnUpdate
                , ValueOld
                , ValueNew
            )
            SELECT
                  X.DateDML
                , X.DatabaseUser
                , X.LoginUser
                , X.LoginUserSQLTransaction
                , X.ProgramName
                , X.HostName
                , X.TableName
                , X.TypeSQL
                , X.TraCod
                , X.ColumnUpdate
                , X.ValueOld
                , X.ValueNew
            FROM
            (
                SELECT
                      GETDATE() AS DateDML
                    , USER_NAME() AS DatabaseUser
                    , SUSER_NAME() AS LoginUser
                    , ORIGINAL_LOGIN() AS LoginUserSQLTransaction
                    , PROGRAM_NAME() AS ProgramName
                    , HOST_NAME() AS HostName
                    , 'TRANSACIONADORES' AS TableName
                    , @Action AS TypeSQL
                    , TraCod AS TraCod
                    , ISNULL(@NomeCol, '') AS ColumnUpdate
                    , ISNULL(
                      (
                          SELECT E.e.value('(/Deleted/row[@TraCod = sql:column(INS.TraCod)]/@Col)[1]', 'varchar(100)')
                          FROM @DeletedTMP.nodes('.') AS E(e)
                      ), '') AS ValueOld
                    , ISNULL(
                      (
                          SELECT E.e.value('(/Inserted/row[@TraCod = sql:column(INS.TraCod)]/@Col)[1]', 'varchar(100)')
                          FROM @InsertedTMP.nodes('.') AS E(e)
                      ), '') AS ValueNew
                FROM inserted AS Ins
            ) AS X
            WHERE X.ValueNew <> X.ValueOld
        END
    END
END
GO

-- ============================================================
-- Tabela dos logs de alteração ou exclusão da tabela transacionadores
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE TABLE LogErp.TransacionadorLogDML
(
      [LogId]                    [int] IDENTITY(1, 1) NOT NULL
    , [DateDML]                  [datetime] DEFAULT (GETDATE())
    , [DatabaseUser]             [varchar](100) DEFAULT (USER_NAME())
    , [LoginUser]                [varchar](100) DEFAULT (SUSER_NAME())
    , [LoginUserSQLTransaction]  [varchar](100) DEFAULT (ORIGINAL_LOGIN())
    , [ProgramName]              [varchar](100) DEFAULT (PROGRAM_NAME())
    , [HostName]                 [varchar](100) DEFAULT (HOST_NAME())
    , [TableName]                [varchar](30) DEFAULT ('TRANSACIONADORES')
    , [TypeSQL]                  [char](1)
    , [Tracod]                   [int] NOT NULL
    , [ColumnUpdate]             [sysname] NOT NULL
    , [ValueOld]                 [varchar](100) DEFAULT ('')
    , [ValueNew]                 [varchar](100) DEFAULT ('')
    , CONSTRAINT [PK_TransacionadorLogDML] PRIMARY KEY CLUSTERED ([LogId] ASC)
    , CONSTRAINT [CK_TableName_Transacionador] CHECK ([TableName] LIKE 'TRANSACIONADORES')
    , CONSTRAINT [CK_TypeSQL_Transacionador] CHECK ([TypeSQL] = 'U' OR [TypeSQL] = 'I' OR [TypeSQL] = 'D')
)
GO

-- ============================================================
-- Procedure de retenção de dados - TransacionadorLogDML
-- ============================================================
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE LogErp.sp_DeleteLogTransacionadores
(
    @qtdadeManterDias INT = 365 -- Quantidade de dias para manter
)
WITH ENCRYPTION
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    BEGIN TRY

        BEGIN TRANSACTION

        -- ============================================================
        -- Bloco 01: Busca quantidade de dias distintos registrados
        -- ============================================================
        DECLARE @qtdadeDias INT
              , @dataMin    DATE

        SET @qtdadeDias =
        (
            SELECT COUNT(x.Registros)
            FROM
            (
                SELECT COUNT(*) AS [Registros]
                FROM DBA_PerformanceHub.LogErp.TransacionadorLogDML AS t1
                GROUP BY CAST(t1.DateDML AS DATE)
            ) AS x
        )

        -- ============================================================
        -- Bloco 02: Loop para tratamento e exclusão dos dias excedentes
        -- ============================================================
        WHILE (@qtdadeDias > @qtdadeManterDias)
        BEGIN
            SET @dataMin =
            (
                SELECT CAST(DATEADD(DAY, 1, ((SELECT MIN(t1.DateDML) FROM DBA_PerformanceHub.LogErp.TransacionadorLogDML AS t1))) AS DATE)
            )

            DELETE FROM DBA_PerformanceHub.LogErp.TransacionadorLogDML
            WHERE DateDML < @dataMin

            SET @qtdadeDias = @qtdadeDias - 1
        END

        COMMIT TRANSACTION

    END TRY

    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Bloco 03: Captura de exceção e montagem do e-mail de falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject    VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content=text/html; charset=windows-1252>
            </head>
            <body>
            <div align=left>'

        SELECT @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left><b>Falha na procedure [sp_DeleteLogTransacionadores]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style=height:20.0pt>
                  <td height=20 colspan=7 style=height:20.0pt;text-align:left>
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        -- ============================================================
        -- Bloco 04: Envio do e-mail de falha
        -- ============================================================
        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients   = @recipients
          , @subject      = @subject
          , @profile_name = 'CRAVIL'
          , @body         = @corpoFalha
          , @body_format  = 'HTML'

    END CATCH

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED

END
GO
