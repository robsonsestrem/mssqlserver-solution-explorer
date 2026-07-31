/*
 *
	OBJETIVO: Procedure de relatório automatizado de NF-e não autorizadas pelo SEFAZ,
			  coletando notas fiscais com status pendente do dia anterior, montando
			  corpo HTML tabular e enviando via Database Mail (sp_send_dbmail) para
			  os setores responsáveis, com opção de exibição local em navegador.
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/relational-databases/database-mail/sp-send-dbmail-transact-sql
 */
-- ============================================================
-- Procedure de Relatório de NF-e Não Autorizadas
-- ============================================================
USE YOUR_DATABASE
GO

-- Teste de execução: parâmetro 1 exibe apenas HTML no navegador sem envio de e-mail
EXEC Erp.sp_ReportNFeNotAuthorized 1
GO

-- ============================================================
-- Criação/Alteração da Procedure
-- ============================================================
CREATE OR ALTER PROCEDURE Erp.[sp_ReportNFeNotAuthorized]
    @ExibirApenasHtml BIT = 0
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION

        -- Criação da tabela temporária para armazenamento das NF-e não autorizadas
        IF OBJECT_ID('tempdb..#naoAutorizadas') IS NOT NULL
        BEGIN
            DROP TABLE #naoAutorizadas;
        END

        CREATE TABLE #naoAutorizadas
        (
            Id INT IDENTITY(1, 1)
            ,Filial SMALLINT
            ,DataHora VARCHAR(30)
            ,NFe INT
            ,NumeroNfe INT
            ,Operacao SMALLINT
            ,Situcao VARCHAR(30)
            ,Chave CHAR(44)
            ,Status SMALLINT
            ,Tipo CHAR(3)
        )

        -- *** SETANDO SEMPRE O DIA ANTERIOR AO DA JOB ***
        DECLARE @inicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
        DECLARE @fim DATETIME = DATEADD(MILLISECOND, +997, DATEADD(SECOND, +59, DATEADD(MINUTE, +59, DATEADD(HOUR, +23, DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))))))
        DECLARE @vSubject NVARCHAR(255) = 'RELATÓRIO DE NF-e NÃO AUTORIZADAS PELO SEFAZ'
        DECLARE @vBody AS NVARCHAR(MAX) = '';
        DECLARE @contaInsert INT = 0
            ,@Loop INT = 1;

        -- ============================================================
        -- População da tabela temporária com NF-e não autorizadas
        -- ============================================================
        INSERT INTO #naoAutorizadas
        SELECT
            m.NfFilCod AS Filial
            ,CONVERT(VARCHAR, m.NfDatEmis, 105) + ' - ' + m.NfHorEntSaid AS DataHora
            ,m.NfNumDoc AS NFe
            ,m.NfNumero AS Número
            ,m.NfOpeEstCod AS OP
            ,CASE m.NfSituacao
                WHEN 1 THEN 'Digitada'
                WHEN 2 THEN 'Atualizado'
                WHEN 3 THEN 'NFListada'
                WHEN 4 THEN 'Cancelado'
                WHEN 5 THEN 'O.C.Listada'
                WHEN 6 THEN 'Ordem Atendida'
                WHEN 7 THEN 'Ordem Atualizada'
                WHEN 8 THEN 'NF-e à Cancelar'
                WHEN 9 THEN 'Ag. Conferência'
                WHEN 10 THEN 'Aguardando Armazenagem'
                WHEN 11 THEN 'Aguardando Autorização'
                WHEN 12 THEN 'Aguardando Liberação'
                WHEN 13 THEN 'Aguardando Processamento'
                ELSE 'Indefinida'
            END AS Situação
            ,CASE
                WHEN m.NfeChNfe = '' THEN 'Não Gerada'
                ELSE ISNULL(m.NfeChNfe, 'Não Gerada')
            END AS Chave
            ,ISNULL(CAST(m.NfeCStat AS VARCHAR(10)), 'Sem Status') AS Status
            ,m.NfTipDoc AS Tipo
        FROM YOUR_DATABASE.dbo.MOVESTOQUE AS m WITH (NOLOCK)
        INNER JOIN YOUR_DATABASE.dbo.OPERACAO AS p
            ON p.OpeEstCod = m.NfOpeEstCod
        WHERE m.NfDatEmis BETWEEN @inicio AND @fim
            -- Nega as canceladas / inutilizadas, uso denegado ou autorizadas
            AND m.NfeCStat NOT IN (100, 101, 102, 302)
            -- Traz só aquelas que contém nº de NFE conforme a situação
            AND
            (
                (m.NfTipDoc = 'nfe' AND m.NfSituacao NOT IN (10, 11, 12, 13))
                OR (m.NfTipDoc = 'nfce' AND m.NfSituacao NOT IN (10, 11, 12, 13))
            )

        -- ============================================================
        -- Montagem do corpo HTML tabular via loop
        -- ============================================================
        -- Cabeçalho da tabela HTML
        SET @vBody = '
            <table border="1" cellpadding="5" cellspacing="0" style="border-collapse:collapse;">
            <tr style="background-color:#4472C4;color:white;">
            <th>Filial</th><th>NF-e</th><th>Numero</th><th>OP</th><th>Situação</th><th>Chave</th><th>Status</th><th>Tipo</th>
            </tr>';

        -- Loop para inserção de dados a partir da 2ª linha (HTML)
        WHILE (@Loop <= (SELECT COUNT(*) FROM #naoAutorizadas))
        BEGIN
            SELECT @vBody = @vBody + '
                <tr>
                <td>' + CONVERT(VARCHAR(3), n.Filial) + '</td>
                <td>' + n.DataHora + '</td>
                <td>' + CONVERT(VARCHAR(10), n.NFe) + '</td>
                <td>' + CONVERT(VARCHAR(10), n.NumeroNfe) + '</td>
                <td>' + CONVERT(VARCHAR(3), n.Operacao) + '</td>
                <td>' + n.Situcao + '</td>
                <td>' + n.Chave + '</td>
                <td>' + CONVERT(VARCHAR(3), Status) + '</td>
                <td>' + n.Tipo + '</td>
                </tr>'
            FROM #naoAutorizadas AS n
            WHERE n.Id = @Loop;

            SET @Loop = @Loop + 1;
        END

        -- Fechamento da tabela HTML
        SET @vBody = @vBody + '</table>';

        -- ============================================================
        -- Envio por e-mail ou exibição local em HTML
        -- ============================================================
        IF @ExibirApenasHtml = 0
        BEGIN
            -- Envio via Database Mail para os setores responsáveis
            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'CRAVIL'
                ,@recipients = 'setorcontabil@cravil.com.br;suporte@cravil.com.br'
                ,@subject = @vSubject
                ,@body = @vBody
                ,@body_format = 'HTML'
                --,@file_attachments = 'C:\DBACravil\DatabaseMail\robson.png';
        END
        ELSE
        BEGIN
            -- *** Exibe como HTML ao invés de enviar por e-mail
            SELECT @vBody;
        END

        -- Limpeza dos dados temporários
        IF OBJECT_ID('tempdb..#naoAutorizadas') IS NOT NULL
        BEGIN
            DROP TABLE #naoAutorizadas;
        END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- ============================================================
        -- Tratamento de erro: envio de e-mail com detalhes da falha
        -- ============================================================
        DECLARE @corpoFalha VARCHAR(MAX)
            ,@subject VARCHAR(100)       -- assunto
            ,@recipients VARCHAR(100);   -- destinatário

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME;
        SET @recipients = 'suporte@cravil.com.br';
        SET @corpoFalha = '
            <h3>Falha na procedure [sp_ReportNFeNotAuthorized]:</h3>
            <p>
            [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
            <br>[LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
            <br>[MESSAGE] - ' + ERROR_MESSAGE() + '
            </p>';

        -- Envio do e-mail de notificação de falha
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name = 'CRAVIL'
            ,@recipients = @recipients
            ,@subject = @subject
            ,@body = @corpoFalha
            ,@body_format = 'HTML';
    END CATCH
END
GO
