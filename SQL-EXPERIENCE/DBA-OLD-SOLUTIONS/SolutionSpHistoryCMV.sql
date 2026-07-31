/*
 *
    OBJETIVO: Funções e procedures para cálculo de faturamento, CMV (Custo de Mercadoria Vendida),
              cupons não integrados e transferências, com envio de e-mails de monitoramento.
    PROJETO: mssqlserver-solution-explorer

    TIPOS DE CÁLCULO:
    - Tipo 1: Faturamento (receita)
    - Tipo 2: CMV do faturamento
    - Tipo 3: Cupons não integrados
    - Tipo 4: Transferências
    - Tipo 5: CMV das transferências

    OBJETOS CRIADOS:
    - Bi.fn_TotaisEmailBi (Function)
    - Bi.sp_HistoryCMV (Procedure)
    - Bi.sp_HistoryCMVSecondShot (Procedure)
    - Bi.sp_HistoryCMVTransferencia (Procedure)
 *
 */
-- ================================================================================================================================
-- FUNÇÃO: fn_TotaisEmailBi
-- Calcula totais para diferentes tipos de operação (faturamento, CMV, cupons, transferências)
-- ================================================================================================================================
USE IntegraTICravil
GO

CREATE OR ALTER FUNCTION Bi.fn_TotaisEmailBi
(
    @datainicio DATETIME,
    @datafinal DATETIME,
    @tipoCalc SMALLINT
)
RETURNS MONEY
WITH ENCRYPTION
AS
BEGIN
    DECLARE @totalCalc MONEY

    -- Tipo 1: Total de faturamento (receita)
    IF (@tipoCalc = 1)
    BEGIN
        DECLARE @ultimaFilial INT = (
            SELECT
                MAX(f.FilCod)
            FROM
                YOUR_DATABASE.dbo.FILIAIS AS f WITH (NOLOCK)
            WHERE
                f.FilFlag2 = 0
        )
        DECLARE @incrementa INT = 1
        DECLARE @valor MONEY = 0

        WHILE (@incrementa <= @ultimaFilial)
        BEGIN
            SET @valor = (
                (
                    SELECT
                        ISNULL(SUM((m2.ItemTotInf - m2.ItemVlrDesc + m2.ItemVlrAcres)), 0)
                    FROM
                        YOUR_DATABASE.dbo.MOVESTOQUE AS m WITH (NOLOCK)
                        INNER JOIN YOUR_DATABASE.dbo.MOVESTOQUELEVEL1 AS m2 WITH (NOLOCK)
                            ON m2.NfFilCod = m.NfFilCod
                            AND m2.NfDatEmis = m.NfDatEmis
                            AND m2.NfNumero = m.NfNumero
                    WHERE
                        m.NfDatEmis BETWEEN @datainicio AND @datafinal
                        AND m.NfeCStat NOT IN (101, 102)
                        AND m.NfSituacao NOT IN (1, 4)
                        AND m.NfOpeEstCod IN (18, 44, 48, 54, 60, 77, 80, 81, 85, 138, 151, 172, 202, 204, 5, 236)
                        AND m.NfFilCod = @incrementa
                ) + @valor
            )
            SET @incrementa = @incrementa + 1
        END
        SET @totalCalc = @valor
    END

    -- Tipo 2: Total de custo de mercadoria vendida
    ELSE IF (@tipoCalc = 2)
    BEGIN
        SET @totalCalc = (
            SELECT
                SUM(x.TotalCusto)
            FROM
                (
                    SELECT
                        (CAST(c.CustoMercadoriaVendida AS MONEY) * SUM(c.Quantidade)) AS TotalCusto
                    FROM
                        Bi.HistoricoCMV AS c
                    WHERE
                        DataEmissao BETWEEN @datainicio AND @datafinal
                    GROUP BY
                        c.Quantidade,
                        c.CustoMercadoriaVendida
                ) AS x
        )
    END

    -- Tipo 3: Total de cupons não integrados
    ELSE IF (@tipoCalc = 3)
    BEGIN
        SET @totalCalc = (
            SELECT
                SUM(totLiq.totliquido) - SUM(totLiq.troco) AS Total_OP5
            FROM
                (
                    SELECT
                        CASE
                            WHEN liquido.tipo_cupom = 'fiscal' AND liquido.tipo_pagamento <> 'troco'
                            THEN SUM(liquido.totais)
                        END AS TotLiquido,
                        CASE
                            WHEN liquido.tipo_cupom = 'fiscal' AND liquido.tipo_pagamento = 'troco'
                            THEN SUM(liquido.totais)
                        END AS troco
                    FROM
                        (
                            SELECT
                                cupons.tipo_cupom,
                                cupons.tipo_pagamento,
                                SUM(cupons.valor) AS totais
                            FROM
                                (
                                    SELECT
                                        CASE
                                            WHEN ISNULL(cupgnf, 0) = 0
                                            THEN 'Fiscal'
                                            ELSE 'Não Fiscal'
                                        END AS tipo_cupom,
                                        CASE cuptottiprec
                                            WHEN 1  THEN 'Dinheiro'
                                            WHEN 2  THEN 'Cheque'
                                            WHEN 3  THEN 'Crediário'
                                            WHEN 4  THEN 'Vasilhame'
                                            WHEN 5  THEN 'Desconto'
                                            WHEN 6  THEN 'Ticket'
                                            WHEN 7  THEN 'Milho'
                                            WHEN 8  THEN 'Leite'
                                            WHEN 9  THEN 'Arroz'
                                            WHEN 10 THEN 'Cartão Crédito'
                                            WHEN 11 THEN 'Cartão Débito'
                                            WHEN 12 THEN 'Troco'
                                        END AS tipo_pagamento,
                                        SUM(cuptotvlr) AS valor
                                    FROM
                                        YOUR_DATABASE.dbo.vendasecflevel2 v2 WITH (NOLOCK)
                                        INNER JOIN YOUR_DATABASE.dbo.vendasecf v WITH (NOLOCK)
                                            ON v.filcod = v2.filcod
                                            AND v.caicod = v2.caicod
                                            AND v.caiopecod = v2.caiopecod
                                            AND v.cupcodigo = v2.cupcodigo
                                            AND v.cupdatmov = v2.cupdatmov
                                    WHERE
                                        v2.cupdatmov BETWEEN @dataInicio AND @datafinal
                                        AND (v.CupGNF IS NULL OR v.CupGNF = 0)   -- Trazer apenas tipo fiscal, não fiscal sempre traz um valor válido
                                        AND v.CupSitIntegracao = 0               -- Trazer os não integrados
                                        AND v.cupsituac = 1                      -- Trazer os não cancelados
                                    GROUP BY
                                        cuptottiprec,
                                        cupgnf
                                ) AS cupons
                            GROUP BY
                                tipo_cupom,
                                tipo_pagamento
                        ) AS liquido
                    GROUP BY
                        liquido.tipo_cupom,
                        liquido.tipo_pagamento
                ) AS totLiq
        )
    END

    -- Tipo 4: Total de faturamento (receita) - Transferências
    ELSE IF (@tipoCalc = 4)
    BEGIN
        DECLARE @ultimaFilialTransf INT = (
            SELECT
                MAX(f.FilCod)
            FROM
                YOUR_DATABASE.dbo.FILIAIS AS f WITH (NOLOCK)
            WHERE
                f.FilFlag2 = 0
        )
        DECLARE @incrementaTransf INT = 1
        DECLARE @valorTransf MONEY = 0

        WHILE (@incrementaTransf <= @ultimaFilialTransf)
        BEGIN
            SET @valorTransf = (
                (
                    SELECT
                        ISNULL(SUM((m2.ItemTotInf - m2.ItemVlrDesc + m2.ItemVlrAcres)), 0)
                    FROM
                        YOUR_DATABASE.dbo.MOVESTOQUE AS m WITH (NOLOCK)
                        INNER JOIN YOUR_DATABASE.dbo.MOVESTOQUELEVEL1 AS m2 WITH (NOLOCK)
                            ON m2.NfFilCod = m.NfFilCod
                            AND m2.NfDatEmis = m.NfDatEmis
                            AND m2.NfNumero = m.NfNumero
                    WHERE
                        m.NfDatEmis BETWEEN @datainicio AND @datafinal
                        AND m.NfeCStat NOT IN (101, 102)
                        AND m.NfSituacao NOT IN (1, 4)
                        AND m.NfOpeEstCod IN (2, 46)
                        AND m.NfFilCod = @incrementaTransf
                ) + @valorTransf
            )
            SET @incrementaTransf = @incrementaTransf + 1
        END
        SET @totalCalc = @valorTransf
    END

    -- Tipo 5: Total de custo de mercadoria vendida nas transferências
    ELSE IF (@tipoCalc = 5)
    BEGIN
        SET @totalCalc = (
            SELECT
                SUM(x.TotalCusto)
            FROM
                (
                    SELECT
                        (CAST(c.CustoMercadoriaVendida AS MONEY) * SUM(c.Quantidade)) AS TotalCusto
                    FROM
                        Bi.HistoricoCMVTransf AS c
                    WHERE
                        DataEmissao BETWEEN @datainicio AND @datafinal
                    GROUP BY
                        c.Quantidade,
                        c.CustoMercadoriaVendida
                ) AS x
        )
    END

    RETURN @totalCalc
END
GO


-- ================================================================================================================================
-- PROCEDURE: sp_HistoryCMV
-- Realiza a carga do histórico de CMV para receitas
-- ================================================================================================================================
USE [IntegraTICravil]
GO

CREATE OR ALTER PROCEDURE Bi.[sp_HistoryCMV]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET LANGUAGE 'portuguese' -- Feito para formatação da data

    -- Define período de coleta (último dia completo)
    DECLARE @datainicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
    DECLARE @datafinal DATETIME = DATEADD(
        MILLISECOND, +997,
        DATEADD(
            SECOND, +59,
            DATEADD(
                MINUTE, +59,
                DATEADD(
                    HOUR, +23,
                    DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
                )
            )
        )
    )

    DECLARE @resultSet INT
          , @totalVendas VARCHAR(20)
          , @totalCusto VARCHAR(20)
          , @totalCupons VARCHAR(20)
          , @assuntoEmail NVARCHAR(50)
          , @CorpoEmail NVARCHAR(MAX)
          , @incrementoHtml INT = 1

    BEGIN TRY
        BEGIN TRANSACTION

            -- Verifica quantidade de cupons não integrados
            SET @resultSet = (
                SELECT
                    COUNT(v.CupCodigo)
                FROM
                    YOUR_DATABASE.dbo.VENDASECF AS v
                WHERE
                    v.CupDatMov BETWEEN @datainicio AND @datafinal
                    AND v.CupSituac = 1                         -- Trazer os não cancelados
                    AND v.CupSitIntegracao = 0                  -- Trazer os não integrados
                    AND (v.CupGNF IS NULL OR v.CupGNF = 0)      -- Trazer apenas tipo fiscal
            )

            SET @totalVendas = (
                SELECT
                    CAST(
                        ISNULL(
                            IntegraTICravil.Management.fn_FormatIntToMoney(
                                IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 1)
                            ),
                            0
                        ) AS VARCHAR(20)
                    )
            )

            -- ----------------------------------------------------------------
            -- Caso existam cupons não integrados: envia e-mail de alerta
            -- ----------------------------------------------------------------
            IF (@resultSet > 0)
            BEGIN
                SET @totalCupons = (
                    SELECT
                        CAST(
                            ISNULL(
                                IntegraTICravil.Management.fn_FormatIntToMoney(
                                    IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 3)
                                ),
                                0
                            ) AS VARCHAR(20)
                        )
                )

                SET @CorpoEmail = '
                    <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px">
                    <tr height=20 style="color:black;">
                        <td width=300 style="height:20.0pt">Não foi possível realizar carga no histórico de custo para Receitas.
                            <br>Data de movimento: ' + CONVERT(VARCHAR(12), @datainicio, 105) + '
                            <br>Motivo: Vendas não integradas para o comercial
                            <br>Valor total não integrado: R$' + @totalCupons + '
                            <br>Segue abaixo lista destes documentos:
                        </td>
                    </tr>
                    </table>
                    <br><br>

                    <TABLE border=0 cellpadding=2 cellspacing=0 style="border-collapse: collapse;table-layout:fixed;width:900pt;font-family:Arial;font-size:14px">
                    <tr height=20 style="height:20.0pt" align=center>
                        <td bgcolor=#0B0B61 width=200> <font color=white>Filial </td>
                        <td bgcolor=#0B0B61 width=200> <font color=white>Cupom  </td>
                        <td bgcolor=#0B0B61 width=200> <font color=white>Data   </td>
                        <td bgcolor=#0B0B61 width=200> <font color=white>Caixa  </td>
                        <td bgcolor=#0B0B61 width=200> <font color=white>Cliente</td>
                    </tr>
                '

                SELECT
                    @CorpoEmail = @CorpoEmail +
                    CASE
                        WHEN CAST(ROW_NUMBER() OVER (ORDER BY v.CupCodigo ASC) % 2 AS BIT) = 1
                        THEN '<tr height=20 style="height:15.0pt" align=center>'
                        ELSE '<tr height=20 style="height:15.0pt; background: #E4E4E4;" align=center>'
                    END +
                    '<td height=20 style="height:15.0pt">' + CAST(v.FilCod AS CHAR(2)) + '</td>' +
                    '<td height=20 style="height:15.0pt">' + CAST(v.CupCodigo AS VARCHAR(50)) + '</td>' +
                    '<td height=20 style="height:15.0pt">' + CONVERT(VARCHAR(12), v.CupDatMov, 105) + '</td>' +
                    '<td height=20 style="height:15.0pt">' + CAST(v.CaiCod AS CHAR(2)) + '</td>' +
                    '<td height=20 style="height:15.0pt">' + CAST(v.CupCliCod AS VARCHAR(20)) + '</td>' +
                    '</tr>'
                FROM
                    YOUR_DATABASE.dbo.VENDASECF AS v
                WHERE
                    v.CupDatMov BETWEEN @datainicio AND @datafinal
                    AND v.CupSituac = 1
                    AND v.CupSitIntegracao = 0
                    AND (v.CupGNF IS NULL OR v.CupGNF = 0)
                ORDER BY
                    v.CupCodigo

                SELECT
                    @CorpoEmail = @CorpoEmail + '</table><br><br>'
            END

            -- ----------------------------------------------------------------
            -- Caso não existam cupons não integrados: realiza a carga
            -- ----------------------------------------------------------------
            IF (@resultSet = 0)
            BEGIN
                INSERT INTO IntegraTICravil.Bi.HistoricoCMV
                (
                    DataIntegracao,
                    CodigoFilial,
                    DataEmissao,
                    NumeroControle,
                    NumeroNFe,
                    Operacao,
                    CodigoProduto,
                    SequenciaItemNota,
                    Codigofamilia,
                    CodigoGrupo,
                    CodigoSubgrupo,
                    CustoMercadoriaVendida,
                    Setor,
                    Secao,
                    CentroCusto,
                    Quantidade,
                    Margem,
                    Peso,
                    Estoque,
                    CustoTotal
                )
                SELECT
                    GETDATE(),
                    x.Filial,
                    x.Emissao,
                    x.NumControle,
                    x.NF,
                    x.Op,
                    x.Item,
                    x.SequenciaItem,
                    x.CodFamilia,
                    x.CodGrupo,
                    x.CodSubgrupo,
                    cmv.CustoMedioUnitario,
                    x.Setor,
                    x.Secao,
                    x.CentroCusto,
                    x.Qtdade,
                    x.Margem,
                    x.Peso,
                    cmv.Estoque,
                    cmv.CustoTotal
                FROM
                    YOUR_DATABASE.dbo.vw_MovimentacaoReceita AS x WITH (NOLOCK)
                    CROSS APPLY YOUR_DATABASE.dbo.GetCustoMercadoria(x.Filial, x.Item, x.Emissao) AS cmv
                WHERE
                    x.Emissao BETWEEN @datainicio AND @datafinal

                SET @totalCusto = (
                    SELECT
                        CAST(
                            ISNULL(
                                IntegraTICravil.Management.fn_FormatIntToMoney(
                                    IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 2)
                                ),
                                0
                            ) AS VARCHAR(20)
                        )
                )

                SET @CorpoEmail = '
                    <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px">
                    <tr height=20 style="color:black;">
                        <td width=300 style="height:20.0pt">Integração de hoje das Receitas com CMV realizada com sucesso.
                            <br>
                            <br>Data de movimento: ' + CONVERT(VARCHAR(12), @datainicio, 105) + '
                            <br>
                            <br>Total das vendas: R$ ' + @totalVendas + '
                            <br>
                            <br>Total de CMV: R$ ' + @totalCusto + '
                        </td>
                    </tr>
                    </table>
                    <br><br>
                '
            END

            -- ----------------------------------------------------------------
            -- Envia e-mail de notificação
            -- ----------------------------------------------------------------
            SET @assuntoEmail = 'Carga para Guru Sistemas - Histórico de CMV'

            EXEC msdb.dbo.sp_send_dbmail
                @profile_name = 'CRAVIL',
                @recipients = 'suporte@cravil.com.br;marcon@cravil.com.br;adriana@cravil.com.br',
                @subject = @assuntoEmail,
                @body = @CorpoEmail,
                @body_format = 'HTML',
                @file_attachments = 'C:\DBACravil\DatabaseMail\robson.png'

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content="text/html; charset=windows-1252">
            </head>
            <body>
            <div align=left>'

        SELECT
            @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px">
                 <tr height=20 style="height:20.0pt">
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left"><b>Falha na procedure [sp_HistoryCMV]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style="height:20.0pt">
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left">
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT
            @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML'
    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO


-- ================================================================================================================================
-- PROCEDURE: sp_HistoryCMVSecondShot
-- Segunda tentativa de carga do histórico de CMV (execução em horário alternativo)
-- ================================================================================================================================
USE IntegraTICravil
GO

CREATE OR ALTER PROCEDURE Bi.sp_HistoryCMVSecondShot
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET LANGUAGE 'portuguese' -- Feito para formatação da data

    -- Define período de coleta (último dia completo)
    DECLARE @datainicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
    DECLARE @datafinal DATETIME = DATEADD(
        MILLISECOND, +997,
        DATEADD(
            SECOND, +59,
            DATEADD(
                MINUTE, +59,
                DATEADD(
                    HOUR, +23,
                    DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
                )
            )
        )
    )

    DECLARE @resultSet INT
          , @resultSetHistory INT
          , @totalVendas VARCHAR(20)
          , @totalCusto VARCHAR(20)
          , @totalCupons VARCHAR(20)
          , @assuntoEmail NVARCHAR(50)
          , @CorpoEmail NVARCHAR(MAX)
          , @incrementoHtml INT = 1

    BEGIN TRY
        BEGIN TRANSACTION

            -- Verifica se a carga já foi realizada
            SET @resultSetHistory = (
                SELECT
                    COUNT(*)
                FROM
                    IntegraTICravil.Bi.HistoricoCMV AS t1
                WHERE
                    t1.DataEmissao >= @datainicio
            )

            -- Se a carga já foi realizada, apenas informa e sai
            IF (@resultSetHistory > 0)
            BEGIN
                PRINT 'INTEGRAÇÃO JÁ FOI REALIZADA COM SUCESSO!'
            END

            -- Se a carga não foi realizada, tenta novamente
            IF (@resultSetHistory = 0)
            BEGIN
                -- Verifica quantidade de cupons não integrados
                SET @resultSet = (
                    SELECT
                        COUNT(v.CupCodigo)
                    FROM
                        YOUR_DATABASE.dbo.VENDASECF AS v
                    WHERE
                        v.CupDatMov BETWEEN @datainicio AND @datafinal
                        AND v.CupSituac = 1
                        AND v.CupSitIntegracao = 0
                        AND (v.CupGNF IS NULL OR v.CupGNF = 0)
                )

                SET @totalVendas = (
                    SELECT
                        CAST(
                            ISNULL(
                                IntegraTICravil.Erp.fn_FormatIntToMoney(
                                    IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 1)
                                ),
                                0
                            ) AS VARCHAR(20)
                        )
                )

                -- ----------------------------------------------------------------
                -- Caso existam cupons não integrados e seja antes das 10h: envia alerta
                -- ----------------------------------------------------------------
                IF (@resultSet > 0 AND DATEPART(HOUR, GETDATE()) < 10)
                BEGIN
                    SET @totalCupons = (
                        SELECT
                            CAST(
                                ISNULL(
                                    IntegraTICravil.Erp.fn_FormatIntToMoney(
                                        IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 3)
                                    ),
                                    0
                                ) AS VARCHAR(20)
                            )
                    )

                    SET @CorpoEmail = '
                        <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px">
                        <tr height=20 style="color:black;">
                            <td width=300 style="height:20.0pt">Não foi possível realizar carga no histórico de custo para Receitas.
                                <br>Data de movimento: ' + CONVERT(VARCHAR(12), @datainicio, 105) + '
                                <br>Motivo: Vendas não integradas para o comercial
                                <br>Valor total não integrado: R$' + @totalCupons + '
                                <br>Segue abaixo lista destes documentos:
                            </td>
                        </tr>
                        </table>
                        <br><br>

                        <TABLE border=0 cellpadding=2 cellspacing=0 style="border-collapse: collapse;table-layout:fixed;width:900pt;font-family:Arial;font-size:14px">
                        <tr height=20 style="height:20.0pt" align=center>
                            <td bgcolor=#0B0B61 width=200> <font color=white>Filial </td>
                            <td bgcolor=#0B0B61 width=200> <font color=white>Cupom  </td>
                            <td bgcolor=#0B0B61 width=200> <font color=white>Data   </td>
                            <td bgcolor=#0B0B61 width=200> <font color=white>Caixa  </td>
                            <td bgcolor=#0B0B61 width=200> <font color=white>Cliente</td>
                        </tr>
                    '

                    SELECT
                        @CorpoEmail = @CorpoEmail +
                        CASE
                            WHEN CAST(ROW_NUMBER() OVER (ORDER BY v.CupCodigo ASC) % 2 AS BIT) = 1
                            THEN '<tr height=20 style="height:15.0pt" align=center>'
                            ELSE '<tr height=20 style="height:15.0pt; background: #E4E4E4;" align=center>'
                        END +
                        '<td height=20 style="height:15.0pt">' + CAST(v.FilCod AS CHAR(2)) + '</td>' +
                        '<td height=20 style="height:15.0pt">' + CAST(v.CupCodigo AS VARCHAR(50)) + '</td>' +
                        '<td height=20 style="height:15.0pt">' + CONVERT(VARCHAR(12), v.CupDatMov, 105) + '</td>' +
                        '<td height=20 style="height:15.0pt">' + CAST(v.CaiCod AS CHAR(2)) + '</td>' +
                        '<td height=20 style="height:15.0pt">' + CAST(v.CupCliCod AS VARCHAR(20)) + '</td>' +
                        '</tr>'
                    FROM
                        YOUR_DATABASE.dbo.VENDASECF AS v
                    WHERE
                        v.CupDatMov BETWEEN @datainicio AND @datafinal
                        AND v.CupSituac = 1
                        AND v.CupSitIntegracao = 0
                        AND (v.CupGNF IS NULL OR v.CupGNF = 0)
                    ORDER BY
                        v.CupCodigo

                    SELECT
                        @CorpoEmail = @CorpoEmail + '</table><br><br>'
                END

                -- ----------------------------------------------------------------
                -- Caso não existam cupons não integrados OU seja após as 10h: realiza a carga
                -- ----------------------------------------------------------------
                IF (@resultSet = 0 OR (@resultSet > 0 AND DATEPART(HOUR, GETDATE()) >= 10))
                BEGIN
                    DECLARE @texto VARCHAR(100)

                    IF (@resultSet > 0)
                    BEGIN
                        SET @texto = 'Integração de hoje das Receitas com CMV foram realizadas parcialmente, pois ainda existem cupons não integrados.'
                    END

                    IF (@resultSet = 0)
                    BEGIN
                        SET @texto = 'Integração de hoje das Receitas com CMV realizada com sucesso.'
                    END

                    INSERT INTO IntegraTICravil.Bi.HistoricoCMV
                    (
                        DataIntegracao,
                        CodigoFilial,
                        DataEmissao,
                        NumeroControle,
                        NumeroNFe,
                        Operacao,
                        CodigoProduto,
                        SequenciaItemNota,
                        Codigofamilia,
                        CodigoGrupo,
                        CodigoSubgrupo,
                        CustoMercadoriaVendida,
                        Setor,
                        Secao,
                        CentroCusto,
                        Quantidade,
                        Margem,
                        Peso,
                        Estoque,
                        CustoTotal
                    )
                    SELECT
                        GETDATE(),
                        x.Filial,
                        x.Emissao,
                        x.NumControle,
                        x.NF,
                        x.Op,
                        x.Item,
                        x.SequenciaItem,
                        x.CodFamilia,
                        x.CodGrupo,
                        x.CodSubgrupo,
                        cmv.CustoMedioUnitario,
                        x.Setor,
                        x.Secao,
                        x.CentroCusto,
                        x.Qtdade,
                        x.Margem,
                        x.Peso,
                        cmv.Estoque,
                        cmv.CustoTotal
                    FROM
                        YOUR_DATABASE.dbo.vw_MovimentacaoReceita AS x WITH (NOLOCK)
                        CROSS APPLY YOUR_DATABASE.dbo.GetCustoMercadoria(x.Filial, x.Item, x.Emissao) AS cmv
                    WHERE
                        x.Emissao BETWEEN @datainicio AND @datafinal

                    SET @totalCusto = (
                        SELECT
                            CAST(
                                ISNULL(
                                    IntegraTICravil.Erp.fn_FormatIntToMoney(
                                        IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 2)
                                    ),
                                    0
                                ) AS VARCHAR(20)
                            )
                    )

                    SET @CorpoEmail = '
                        <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px">
                        <tr height=20 style="color:black;">
                            <td width=300 style="height:20.0pt">' + @texto + '
                                <br>
                                <br>Data de movimento: ' + CONVERT(VARCHAR(12), @datainicio, 105) + '
                                <br>
                                <br>Total das vendas: R$ ' + @totalVendas + '
                                <br>
                                <br>Total de CMV: R$ ' + @totalCusto + '
                            </td>
                        </tr>
                        </table>
                        <br><br>
                    '
                END

                -- ----------------------------------------------------------------
                -- Envia e-mail de notificação
                -- ----------------------------------------------------------------
                SET @assuntoEmail = 'Carga para Guru Sistemas - Histórico de CMV'

                EXEC msdb.dbo.sp_send_dbmail
                    @profile_name = 'CRAVIL',
                    @recipients = 'agenteti@cravil.com.br;adami@cravil.com.br;janaina@cravil.com.br',
                    @subject = @assuntoEmail,
                    @body = @CorpoEmail,
                    @body_format = 'HTML'
            END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'agenteti@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content="text/html; charset=windows-1252">
            </head>
            <body>
            <div align=left>'

        SELECT
            @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px">
                 <tr height=20 style="height:20.0pt">
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left"><b>Falha na procedure [sp_HistoryCMVSecondShot]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style="height:20.0pt">
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left">
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT
            @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML'
    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO


-- ================================================================================================================================
-- PROCEDURE: sp_HistoryCMVTransferencia
-- Realiza a carga do histórico de CMV para transferências
-- ================================================================================================================================
USE [IntegraTICravil]
GO

CREATE OR ALTER PROCEDURE Bi.[sp_HistoryCMVTransferencia]
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET LANGUAGE 'portuguese' -- Feito para formatação da data

    -- Define período de coleta (último dia completo)
    DECLARE @datainicio DATETIME = DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
    DECLARE @datafinal DATETIME = DATEADD(
        MILLISECOND, +997,
        DATEADD(
            SECOND, +59,
            DATEADD(
                MINUTE, +59,
                DATEADD(
                    HOUR, +23,
                    DATEADD(DAY, -1, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME))
                )
            )
        )
    )

    DECLARE @totalOperacoes VARCHAR(20)
          , @totalCusto VARCHAR(20)
          , @resultSetHistory INT
          , @assuntoEmail NVARCHAR(50)
          , @CorpoEmail NVARCHAR(MAX)
          , @incrementoHtml INT = 1

    BEGIN TRY
        BEGIN TRANSACTION

            -- Verifica se a carga já foi realizada
            SET @resultSetHistory = (
                SELECT
                    COUNT(*)
                FROM
                    IntegraTICravil.Bi.HistoricoCMVTransf AS t1
                WHERE
                    t1.DataEmissao >= @datainicio
            )

            -- Se a carga já foi realizada, apenas informa e sai
            IF (@resultSetHistory > 0)
            BEGIN
                PRINT 'INTEGRAÇÃO JÁ FOI REALIZADA COM SUCESSO!'
            END
            ELSE
            BEGIN
                SET @totalOperacoes = (
                    SELECT
                        CAST(
                            ISNULL(
                                IntegraTICravil.Erp.fn_FormatIntToMoney(
                                    IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 4)
                                ),
                                0
                            ) AS VARCHAR(20)
                        )
                )

                -- Realiza a carga dos dados
                INSERT INTO IntegraTICravil.Bi.HistoricoCMVTransf
                (
                    DataIntegracao,
                    CodigoFilial,
                    DataEmissao,
                    NumeroControle,
                    NumeroNFe,
                    Operacao,
                    CodigoProduto,
                    SequenciaItemNota,
                    Codigofamilia,
                    CodigoGrupo,
                    CodigoSubgrupo,
                    CustoMercadoriaVendida,
                    Setor,
                    Secao,
                    CentroCusto,
                    Quantidade,
                    Margem,
                    Peso,
                    Estoque,
                    CustoTotal
                )
                SELECT
                    GETDATE(),
                    x.Filial,
                    x.Emissao,
                    x.NumControle,
                    x.NF,
                    x.Op,
                    x.Item,
                    x.SequenciaItem,
                    x.CodFamilia,
                    x.CodGrupo,
                    x.CodSubgrupo,
                    cmv.CustoMedioUnitario,
                    x.Setor,
                    x.Secao,
                    x.CentroCusto,
                    x.Qtdade,
                    x.Margem,
                    x.Peso,
                    cmv.Estoque,
                    cmv.CustoTotal
                FROM
                    YOUR_DATABASE.dbo.vw_MovimentacaoTransferencia AS x WITH (NOLOCK)
                    CROSS APPLY YOUR_DATABASE.dbo.GetCustoMercadoria(x.Filial, x.Item, x.Emissao) AS cmv
                WHERE
                    x.Emissao BETWEEN @datainicio AND @datafinal

                SET @totalCusto = (
                    SELECT
                        CAST(
                            ISNULL(
                                IntegraTICravil.Erp.fn_FormatIntToMoney(
                                    IntegraTICravil.Bi.fn_TotaisEmailBi(@datainicio, @datafinal, 5)
                                ),
                                0
                            ) AS VARCHAR(20)
                        )
                )

                SET @CorpoEmail = '
                    <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px">
                    <tr height=20 style="color:black;">
                        <td width=300 style="height:20.0pt">Integração de hoje para Histórico das Transferências com CMV realizada com sucesso.
                            <br>
                            <br>Data de Movimento: ' + CONVERT(VARCHAR(12), @datainicio, 105) + '
                            <br>
                            <br>Total das Operações: R$ ' + @totalOperacoes + '
                            <br>
                            <br>Total de CMV: R$ ' + @totalCusto + '
                        </td>
                    </tr>
                    </table>
                    <br><br>
                '

                -- ----------------------------------------------------------------
                -- Envia e-mail de notificação
                -- ----------------------------------------------------------------
                SET @assuntoEmail = 'Carga para Guru Sistemas - Histórico de CMV'

                EXEC msdb.dbo.sp_send_dbmail
                    @profile_name = 'CRAVIL',
                    @recipients = 'suporte@cravil.com.br;andrey@cravil.com.br',
                    @subject = @assuntoEmail,
                    @body = @CorpoEmail,
                    @body_format = 'HTML'
            END

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'suporte@cravil.com.br;andrey@cravil.com.br'

        SET @corpoFalha = '
            <html>
            <head>
            <meta http-equiv=Content-Type content="text/html; charset=windows-1252">
            </head>
            <body>
            <div align=left>'

        SELECT
            @corpoFalha = @corpoFalha + '
            <table border=0 cellpadding=0 cellspacing=0 width=402 style="border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:14px">
                 <tr height=20 style="height:20.0pt">
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left"><b>Falha na procedure [sp_CMVTransferencia]:<b> <br>
                  </td>
                 </tr>
                 <tr height=20 style="height:20.0pt">
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left">
                      <br> [ERROR NUMBER] - ' + CAST(ERROR_NUMBER() AS VARCHAR(10)) + '
                      <br>
                      <br> [LINE] - ' + CAST(ERROR_LINE() AS VARCHAR(10)) + '
                      <br>
                      <br> [MESSAGE] - ' + ERROR_MESSAGE() + '
                   </td>
                  </tr>
            </table>'

        SELECT
            @corpoFalha = @corpoFalha + '
            </div>
            </body>
            </html>'

        EXEC [msdb].[dbo].[sp_send_dbmail]
            @recipients = @recipients,
            @subject = @subject,
            @profile_name = 'CRAVIL',
            @body = @corpoFalha,
            @body_format = 'HTML'
    END CATCH

    SET NOCOUNT OFF
    SET TRANSACTION ISOLATION LEVEL READ COMMITTED
END
GO
