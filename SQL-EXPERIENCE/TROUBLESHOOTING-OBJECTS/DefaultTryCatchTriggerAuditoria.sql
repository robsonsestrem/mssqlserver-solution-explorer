/*
 *
	OBJETIVO: Trigger de auditoria para captura de operações DML (INSERT, UPDATE, DELETE)
			  na tabela QUEST, gravando o histórico detalhado na tabela QUEST_audit.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Trigger de Auditoria para Registro de Histórico e auditoria
-- ============================================================

CREATE OR ALTER TRIGGER TG_AUDIT_QUEST
ON dbo.QUEST
FOR INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Declaração de variável para identificação do tipo de operação
    DECLARE @Operacao CHAR(1);

    -- Determinação do tipo de operação DML (I = Insert, U = Update, D = Delete)
    IF EXISTS (SELECT 1 FROM Inserted)
    BEGIN
        SET @Operacao = 'I';
    END

    IF EXISTS (SELECT 1 FROM Deleted)
    BEGIN
        IF (@Operacao IS NULL)
        BEGIN
            SET @Operacao = 'D';
        END
        ELSE
        BEGIN
            SET @Operacao = 'U';
        END
    END

    -- Processamento da auditoria para operação de Inclusão (INSERT)
    IF @Operacao = 'I'
    BEGIN
        BEGIN TRY
            INSERT INTO QUEST_audit
            (
                CD_QUEST
              , NM_QUEST
              , TP_QUEST
              , ST_QUEST
              , DS_QUEST_MSCRA
              , NO_QUEST_ITINI
              , NO_QUEST_ITFIM
              , NM_QUEST_IMG
              , ID_QUEST_EXAME_FISIC_PEP
              , ID_QUEST_RESUL_EXAME_PEP
              , ID_QUEST_OBRG
              , CD_QUEST_EXTRN
              , PERM_QUEST_CLENT
              , PERM_QUEST_GSTOR
              , PERM_QUEST_PROSD
              , PERM_QUEST_ATESC
              , USR_REG
              , ID_QUEST_OBJETIVA_SOAP
              , ID_QUEST_FAVRT
              , CD_TERMO
              , NO_QUEST_ITINI_IDEAL
              , NO_QUEST_ITFIM_IDEAL
              , Operacao
            )
            SELECT
                I.CD_QUEST
              , I.NM_QUEST
              , I.TP_QUEST
              , I.ST_QUEST
              , I.DS_QUEST_MSCRA
              , I.NO_QUEST_ITINI
              , I.NO_QUEST_ITFIM
              , I.NM_QUEST_IMG
              , I.ID_QUEST_EXAME_FISIC_PEP
              , I.ID_QUEST_RESUL_EXAME_PEP
              , I.ID_QUEST_OBRG
              , I.CD_QUEST_EXTRN
              , I.PERM_QUEST_CLENT
              , I.PERM_QUEST_GSTOR
              , I.PERM_QUEST_PROSD
              , I.PERM_QUEST_ATESC
              , I.USR_REG
              , I.ID_QUEST_OBJETIVA_SOAP
              , I.ID_QUEST_FAVRT
              , I.CD_TERMO
              , I.NO_QUEST_ITINI_IDEAL
              , I.NO_QUEST_ITFIM_IDEAL
              , @Operacao AS Operacao
            FROM Inserted AS I;
        END TRY
        BEGIN CATCH
            -- Captura e lançamento de erro para a operação de inclusão
            DECLARE @ErrorMessageAdd NVARCHAR(4000);
            DECLARE @ErrorSeverityAdd INT;

            SELECT
                @ErrorMessageAdd = 'Trigger: TG_AUDIT_QUEST; Operação: ' + @Operacao + '; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE()
              , @ErrorSeverityAdd = ERROR_SEVERITY();

            RAISERROR(@ErrorMessageAdd, @ErrorSeverityAdd, 1);
        END CATCH
    END
    -- Processamento da auditoria para operação de Alteração (UPDATE)
    ELSE IF @Operacao = 'U'
    BEGIN
        BEGIN TRY
            INSERT INTO QUEST_audit
            (
                CD_QUEST
              , NM_QUEST
              , TP_QUEST
              , ST_QUEST
              , DS_QUEST_MSCRA
              , NO_QUEST_ITINI
              , NO_QUEST_ITFIM
              , NM_QUEST_IMG
              , ID_QUEST_EXAME_FISIC_PEP
              , ID_QUEST_RESUL_EXAME_PEP
              , ID_QUEST_OBRG
              , CD_QUEST_EXTRN
              , PERM_QUEST_CLENT
              , PERM_QUEST_GSTOR
              , PERM_QUEST_PROSD
              , PERM_QUEST_ATESC
              , USR_REG
              , ID_QUEST_OBJETIVA_SOAP
              , ID_QUEST_FAVRT
              , CD_TERMO
              , NO_QUEST_ITINI_IDEAL
              , NO_QUEST_ITFIM_IDEAL
              , Operacao
            )
            SELECT
                I.CD_QUEST
              , I.NM_QUEST
              , I.TP_QUEST
              , I.ST_QUEST
              , I.DS_QUEST_MSCRA
              , I.NO_QUEST_ITINI
              , I.NO_QUEST_ITFIM
              , I.NM_QUEST_IMG
              , I.ID_QUEST_EXAME_FISIC_PEP
              , I.ID_QUEST_RESUL_EXAME_PEP
              , I.ID_QUEST_OBRG
              , I.CD_QUEST_EXTRN
              , I.PERM_QUEST_CLENT
              , I.PERM_QUEST_GSTOR
              , I.PERM_QUEST_PROSD
              , I.PERM_QUEST_ATESC
              , I.USR_REG
              , I.ID_QUEST_OBJETIVA_SOAP
              , I.ID_QUEST_FAVRT
              , I.CD_TERMO
              , I.NO_QUEST_ITINI_IDEAL
              , I.NO_QUEST_ITFIM_IDEAL
              , @Operacao AS Operacao
            FROM Inserted AS I;
        END TRY
        BEGIN CATCH
            -- Captura e lançamento de erro para a operação de alteração
            DECLARE @ErrorMessageUpd NVARCHAR(4000);
            DECLARE @ErrorSeverityUpd INT;

            SELECT
                @ErrorMessageUpd = 'Trigger: TG_AUDIT_QUEST; Operação: ' + @Operacao + '; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE()
              , @ErrorSeverityUpd = ERROR_SEVERITY();

            RAISERROR(@ErrorMessageUpd, @ErrorSeverityUpd, 1);
        END CATCH
    END
    -- Processamento da auditoria para operação de Exclusão (DELETE)
    ELSE IF @Operacao = 'D'
    BEGIN
        BEGIN TRY
            INSERT INTO QUEST_audit
            (
                CD_QUEST
              , NM_QUEST
              , TP_QUEST
              , ST_QUEST
              , DS_QUEST_MSCRA
              , NO_QUEST_ITINI
              , NO_QUEST_ITFIM
              , NM_QUEST_IMG
              , ID_QUEST_EXAME_FISIC_PEP
              , ID_QUEST_RESUL_EXAME_PEP
              , ID_QUEST_OBRG
              , CD_QUEST_EXTRN
              , PERM_QUEST_CLENT
              , PERM_QUEST_GSTOR
              , PERM_QUEST_PROSD
              , PERM_QUEST_ATESC
              , USR_REG
              , ID_QUEST_OBJETIVA_SOAP
              , ID_QUEST_FAVRT
              , CD_TERMO
              , NO_QUEST_ITINI_IDEAL
              , NO_QUEST_ITFIM_IDEAL
              , Operacao
            )
            SELECT
                D.CD_QUEST
              , D.NM_QUEST
              , D.TP_QUEST
              , D.ST_QUEST
              , D.DS_QUEST_MSCRA
              , D.NO_QUEST_ITINI
              , D.NO_QUEST_ITFIM
              , D.NM_QUEST_IMG
              , D.ID_QUEST_EXAME_FISIC_PEP
              , D.ID_QUEST_RESUL_EXAME_PEP
              , D.ID_QUEST_OBRG
              , D.CD_QUEST_EXTRN
              , D.PERM_QUEST_CLENT
              , D.PERM_QUEST_GSTOR
              , D.PERM_QUEST_PROSD
              , D.PERM_QUEST_ATESC
              , D.USR_REG
              , D.ID_QUEST_OBJETIVA_SOAP
              , D.ID_QUEST_FAVRT
              , D.CD_TERMO
              , D.NO_QUEST_ITINI_IDEAL
              , D.NO_QUEST_ITFIM_IDEAL
              , @Operacao AS Operacao
            FROM Deleted AS D;
        END TRY
        BEGIN CATCH
            -- Captura e lançamento de erro para a operação de exclusão
            DECLARE @ErrorMessageDel NVARCHAR(4000);
            DECLARE @ErrorSeverityDel INT;

            SELECT
                @ErrorMessageDel = 'Trigger: TG_AUDIT_QUEST; Operação: ' + @Operacao + '; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE()
              , @ErrorSeverityDel = ERROR_SEVERITY();

            RAISERROR(@ErrorMessageDel, @ErrorSeverityDel, 1);
        END CATCH
    END
END
GO
