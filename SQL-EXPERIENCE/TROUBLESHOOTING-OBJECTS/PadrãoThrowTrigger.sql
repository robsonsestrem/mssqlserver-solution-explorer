/*
 *
	OBJETIVO: Scripts de criação e refatoração de Triggers para validação
			  e integridade de dados das tabelas CNSUL e RESPC.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	
 */
-- ============================================================
-- Triggers de Validação e Integridade Negocial
-- ============================================================

-- ============================================================
-- Trigger: TG_PROFREF_CNSUL
-- Caso simples: Vincula profissional 
-- de referência na inclusão de consulta
-- ============================================================
CREATE OR ALTER TRIGGER [dbo].[TG_PROFREF_CNSUL]
ON [dbo].[CNSUL]
FOR INSERT
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON;

    BEGIN TRY
        -- Inserção condicional do profissional na tabela MEDIC caso o parâmetro esteja ativo
        INSERT INTO MEDIC
        (
            CD_PSSOA_MEDIC
          , CD_PSSOA_CLENT
          , USR_REG
          , ID_ORIGEM
        )
        SELECT
            I.CD_PSSOA_PROF
          , I.CD_PSSOA_CLENT
          , I.USR_REG
          , 'M' AS ID_ORIGEM
        FROM Inserted AS I
        WHERE 'S' = (
            SELECT TOP 1
                P.VALOR_RADIO
            FROM PRMST AS P
            WHERE P.CD_PRMST = 'profissional_referencia'
        )
        AND NOT EXISTS (
            SELECT TOP 1 1
            FROM MEDIC AS M
            WHERE M.CD_PSSOA_MEDIC = (
                SELECT
                    I2.CD_PSSOA_PROF
                FROM Inserted AS I2
            )
            AND M.CD_PSSOA_CLENT = (
                SELECT
                    I3.CD_PSSOA_CLENT
                FROM Inserted AS I3
            )
        );
    END TRY
    BEGIN CATCH
        -- Tratamento e propagação do erro ocorrido na execução da trigger
        DECLARE @ErrorMessage NVARCHAR(2048) = 'TRIGGER: TG_PROFREF_CNSUL; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
        DECLARE @ErrorNumber INT = 50000 + ERROR_NUMBER();
        DECLARE @ErrorState INT = ERROR_STATE();

        ;THROW @ErrorNumber, @ErrorMessage, @ErrorState;
    END CATCH
END
GO

-- ============================================================
-- Trigger: TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA
-- Caso complexo: Impede inserções de respostas 
-- após a conclusão da avaliação
-- ============================================================
CREATE OR ALTER TRIGGER [dbo].[TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA]
ON [dbo].[RESPC]
FOR INSERT
AS
BEGIN
    SET XACT_ABORT, NOCOUNT ON;

    -- Validação da flag de ativação da regra de negócio no cadastro de parâmetros
    IF (1 = (SELECT TOP 1 1 FROM PRMST WHERE CD_PRMST = 'tg_respc_avals_apos_concluida' AND VALOR_RADIO = 'S'))
    BEGIN
        BEGIN TRY
            -- Declaração das variáveis locais
            DECLARE @CD_AVALS NUMERIC;
            DECLARE @CD_PSSOA_CLENT NUMERIC;
            DECLARE @CD_PSSOA_REG NUMERIC;
            DECLARE @DATA_REGISTRO DATETIME;
            DECLARE @QTD_PROFS_POR_AVALS_IN_RESPC INT = 0;
            DECLARE @QTD_PROFS_POR_AVALS_IN_QTNAV INT = 0;

            -- Leitura dos dados do registro que está sendo inserido
            SET @CD_AVALS       = ISNULL((SELECT TOP 1 CD_AVALS FROM Inserted), 0);
            SET @CD_PSSOA_CLENT = ISNULL((SELECT TOP 1 CD_PSSOA_CLENT FROM Inserted), 0);
            SET @CD_PSSOA_REG   = ISNULL((SELECT TOP 1 CD_PSSOA_REG FROM Inserted), 0);
            SET @DATA_REGISTRO  = ISNULL((SELECT TOP 1 DATA_REGISTRO FROM Inserted), dbo.GETLOCALEDATE());

            IF (@CD_AVALS > 0)
            BEGIN
                -- Construção da mensagem detalhada de exceção para o usuário
                DECLARE @MSG_USER NVARCHAR(2048) = N' - Restrição acionada para impedir inconstências nas respostas de avaliações.' 
                    + N' - CD_AVALS: ' + CAST(@CD_AVALS AS VARCHAR(20)) 
                    + N' - CD_PSSOA_CLENT: ' + CAST(@CD_PSSOA_CLENT AS VARCHAR(20)) 
                    + N' - CD_PSSOA_REG: ' + CAST(@CD_PSSOA_REG AS VARCHAR(20)) 
                    + N' - DATA_REGISTRO: ' + CONVERT(VARCHAR(30), @DATA_REGISTRO, 113);

                -- Apuração da quantidade total de profissionais associados na RESPC
                SET @QTD_PROFS_POR_AVALS_IN_RESPC =
                    IIF(
                        EXISTS (
                            SELECT 1
                            FROM RESPC AS R
                            WHERE R.CD_AVALS = @CD_AVALS
                            AND R.CD_PSSOA_CLENT = @CD_PSSOA_CLENT
                        )
                      , (
                            SELECT
                                COUNT(DISTINCT I.CD_PSSOA_REG) AS total_profs
                            FROM RESPC AS R
                            INNER JOIN Inserted AS I
                                ON R.CD_AVALS = I.CD_AVALS
                                AND R.CD_PSSOA_CLENT = I.CD_PSSOA_CLENT
                            WHERE R.CD_AVALS = @CD_AVALS
                            AND R.CD_PSSOA_CLENT = @CD_PSSOA_CLENT
                        )
                      , 1
                    );

                -- Apuração da quantidade total de profissionais associados na QTNAV
                SET @QTD_PROFS_POR_AVALS_IN_QTNAV =
                    (
                        SELECT
                            COUNT(DISTINCT Q.USR_REG) AS total_profs
                        FROM QTNAV AS Q
                        WHERE Q.CD_AVALS = @CD_AVALS
                    );

                -- Validação do bloqueio: avaliação concluída ou inconsistência na contagem de profissionais
                IF EXISTS (
                    SELECT 1
                    FROM RESPC AS R
                    INNER JOIN AVALS_Audit AS A
                        ON R.CD_AVALS = A.CD_AVALS
                    WHERE A.CD_AVALS = @CD_AVALS
                    AND A.ST_AVALS = 'C'
                    AND A.DataAudit <= @DATA_REGISTRO
                )
                OR
                -- Pelo menos 1 profissional (ou o próprio paciente em alguns casos) da RESPC deve existir na QTNAV
                (
                    NOT EXISTS (
                        SELECT 1
                        FROM QTNAV AS QAV
                        WHERE QAV.CD_AVALS = @CD_AVALS
                        AND QAV.USR_REG IN (
                            SELECT DISTINCT
                                R.CD_PSSOA_REG
                            FROM RESPC AS R
                            WHERE R.CD_AVALS = QAV.CD_AVALS
                            AND R.CD_PSSOA_CLENT = @CD_PSSOA_CLENT

                            UNION

                            SELECT DISTINCT
                                I.USR_REG
                            FROM Inserted AS I
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
            -- Tratamento e propagação do erro ocorrido na execução da trigger
            DECLARE @ErrorMessage NVARCHAR(2048) = 'TRIGGER: TG_NAO_INSERIR_RESPC_AVALS_APOS_CONCLUIDA; - Erro na linha ' + CAST(ERROR_LINE() AS VARCHAR(10)) + ' - ' + ERROR_MESSAGE();
            DECLARE @ErrorNumber INT = 50000 + ERROR_NUMBER();
            DECLARE @ErrorState INT = ERROR_STATE();

            ;THROW @ErrorNumber, @ErrorMessage, @ErrorState;
        END CATCH
    END
END
GO
