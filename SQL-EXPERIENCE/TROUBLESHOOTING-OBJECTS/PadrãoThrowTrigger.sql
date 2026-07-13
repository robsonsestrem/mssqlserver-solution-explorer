------------------------------------------------------------------------------
-- Caso simples
------------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [dbo].[TG_PROFREF_CNSUL]
ON [dbo].[CNSUL]
FOR INSERT
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON;
    BEGIN TRY
        INSERT INTO MEDIC (CD_PSSOA_MEDIC, CD_PSSOA_CLENT, USR_REG, ID_ORIGEM)
            SELECT  CD_PSSOA_PROF
                   ,CD_PSSOA_CLENT
                   ,USR_REG
                   ,'M'
            FROM Inserted
            WHERE 'S' = (SELECT TOP 1
                         PRMST.VALOR_RADIO
                         FROM PRMST
                         WHERE PRMST.CD_PRMST = 'profissional_referencia'
                        )
            AND NOT EXISTS (SELECT TOP 1 1
                            FROM MEDIC
                            WHERE MEDIC.CD_PSSOA_MEDIC = (SELECT CD_PSSOA_PROF
                                                          FROM Inserted
                                                         )
                            AND MEDIC.CD_PSSOA_CLENT = (SELECT CD_PSSOA_CLENT
                                                        FROM Inserted
                                                       )
                           );
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(2048) = 'TRIGGER: TG_PROFREF_CNSUL; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE()
        DECLARE @ErrorNumber INT = 50000 + ERROR_NUMBER()
        DECLARE @ErrorState INT = ERROR_STATE()
        ;THROW @ErrorNumber, @ErrorMessage, @ErrorState;
    END CATCH
END
GO

------------------------------------------------------------------------------
-- Caso com mais mensagem de "Throw"
------------------------------------------------------------------------------
CREATE OR ALTER TRIGGER [dbo].[TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA]
ON [dbo].[RESPC]
FOR INSERT
AS
  BEGIN
    SET XACT_ABORT, NOCOUNT ON;
	IF (1 = (SELECT TOP 1 1 FROM PRMST WHERE CD_PRMST = 'tg_respc_avals_apos_concluida' AND VALOR_RADIO = 'S'))
    BEGIN TRY
        DECLARE @CD_AVALS NUMERIC, @CD_PSSOA_CLENT NUMERIC, @CD_PSSOA_REG NUMERIC, @DATA_REGISTRO DATETIME;
        DECLARE @QTD_PROFS_POR_AVALS_IN_RESPC INT = 0, @QTD_PROFS_POR_AVALS_IN_QTNAV INT = 0;
                                              
        SET @CD_AVALS       = ISNULL((SELECT TOP 1 CD_AVALS FROM INSERTED), 0)
        SET @CD_PSSOA_CLENT = ISNULL((SELECT TOP 1 CD_PSSOA_CLENT FROM INSERTED), 0)
        SET @CD_PSSOA_REG   = ISNULL((SELECT TOP 1 CD_PSSOA_REG FROM INSERTED), 0)         
        SET @DATA_REGISTRO  = ISNULL((SELECT TOP 1 DATA_REGISTRO FROM INSERTED), dbo.GETLOCALEDATE())
        
        IF (@CD_AVALS > 0)
        BEGIN
            DECLARE @MSG_USER NVARCHAR(2048) = N' - Restrição acionada para impedir inconstências nas respostas de avaliações.' 
            + N' - CD_AVALS: ' + CAST(@CD_AVALS AS VARCHAR(20)) 
            + N' - CD_PSSOA_CLENT: ' + CAST(@CD_PSSOA_CLENT AS VARCHAR(20)) 
            + N' - CD_PSSOA_REG: ' + CAST(@CD_PSSOA_REG AS VARCHAR(20)) 
            + N' - DATA_REGISTRO: ' + CONVERT(VARCHAR(30), @DATA_REGISTRO, 113);
    
            SET @QTD_PROFS_POR_AVALS_IN_RESPC =
            IIF(EXISTS(SELECT 1 FROM RESPC AS R WHERE R.CD_AVALS = @CD_AVALS AND R.CD_PSSOA_CLENT = @CD_PSSOA_CLENT)
            , (SELECT COUNT(DISTINCT I.CD_PSSOA_REG) AS total_profs
               FROM RESPC AS R 
               INNER JOIN INSERTED AS I ON R.CD_AVALS = I.CD_AVALS AND R.CD_PSSOA_CLENT = I.CD_PSSOA_CLENT
               WHERE R.CD_AVALS = @CD_AVALS AND R.CD_PSSOA_CLENT = @CD_PSSOA_CLENT
              )
            , 1);
             
            SET @QTD_PROFS_POR_AVALS_IN_QTNAV =
            (SELECT COUNT(DISTINCT Q.USR_REG) AS total_profs
             FROM QTNAV Q
             WHERE Q.CD_AVALS = @CD_AVALS
            );               
                                   
            -- Não pode inserir respostas após uma avaliação concluída
            IF EXISTS (
                       SELECT 1
                       FROM RESPC AS R
                       INNER JOIN AVALS_Audit AS A ON R.CD_AVALS = A.CD_AVALS
                       WHERE A.CD_AVALS = @CD_AVALS
                       AND A.ST_AVALS = 'C'
                       AND A.DataAudit <= @DATA_REGISTRO
                      )
               OR
               -- Pelo menos 1 profissional (ou o próprio paciente em alguns casos) da RESPC deve existir na QTNAV
               (NOT EXISTS (
                            SELECT 1
                            FROM QTNAV AS QAV
                            WHERE QAV.CD_AVALS = @CD_AVALS
                            AND QAV.USR_REG IN (
                                                SELECT DISTINCT R.CD_PSSOA_REG FROM RESPC AS R
                                                WHERE R.CD_AVALS = QAV.CD_AVALS AND R.CD_PSSOA_CLENT = @CD_PSSOA_CLENT
                                                UNION
                                                SELECT DISTINCT I.USR_REG FROM INSERTED AS I
                                                WHERE I.CD_AVALS = QAV.CD_AVALS
                                               )
                           )
               )
               OR
               -- A quantidade de profissionais por avaliação na QTNAV não pode ser maior que na RESPC
               (@QTD_PROFS_POR_AVALS_IN_QTNAV > @QTD_PROFS_POR_AVALS_IN_RESPC)
            BEGIN
                ;THROW 50000, @MSG_USER, 1;
            END
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(2048) = 'TRIGGER: TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE()
        DECLARE @ErrorNumber INT = 50000 + ERROR_NUMBER()
        DECLARE @ErrorState INT = ERROR_STATE()
        ;THROW @ErrorNumber, @ErrorMessage, @ErrorState;
    END CATCH
  END
GO

