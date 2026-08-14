/*
 *
    OBJETIVO: Procedure para geração e exportação de dados de colaboradores
              para o layout SESCOOP (Sistema de Cooperativas),
              com envio por e-mail em anexo CSV.
    PROJETO: mssqlserver-solution-explorer
 *  
 */
USE DBA_PerformanceHub
GO

CREATE OR ALTER PROCEDURE Erp.sp_ReportLayoutSecoop
(
    @ExibirApenasHtml BIT = 0
)
AS
BEGIN
    -- ============================================================
    -- Declaração de variáveis
    -- ============================================================
    DECLARE @vSubject NVARCHAR(255) = 'Relação de dados RH CRAVIL'
    DECLARE @vBody AS NVARCHAR(MAX) = ''
    DECLARE @Query NVARCHAR(MAX)
    DECLARE @tab CHAR(1) = CHAR(9)

    -- ============================================================
    -- Criação da tabela temporária para armazenar os dados
    -- ============================================================
    IF OBJECT_ID('tempdb..##dadosRHsescoop') IS NOT NULL
        DROP TABLE ##dadosRHsescoop

    CREATE TABLE ##dadosRHsescoop
    (
          cpf            BIGINT
        , nome           VARCHAR(MAX)
        , cracha         VARCHAR(MAX)
        , email          VARCHAR(MAX)
        , sexo           VARCHAR(3)
        , datanasc       VARCHAR(MAX)
        , estadoCivil    VARCHAR(3)
        , nacionalidade  VARCHAR(MAX)
        , naturalidade   VARCHAR(MAX)
        , rg             VARCHAR(MAX)
        , orgao          VARCHAR(20)
        , grauInstru     VARCHAR(3)
        , deficiencia    VARCHAR(MAX)
        , cor            VARCHAR(10)
        , renda          VARCHAR(10)
        , situacao       VARCHAR(10)
        , fone           VARCHAR(MAX)
        , uf             VARCHAR(4)
        , ibge           INT
        , endereco       VARCHAR(MAX)
        , numero         VARCHAR(MAX)
        , bairro         VARCHAR(MAX)
        , cep            INT
    )

    -- ============================================================
    -- Inserção dos dados na tabela temporária
    -- ============================================================
    INSERT INTO ##dadosRHsescoop
    SELECT
          FicBasica.numcpf AS cpf
        , FicBasica.nomfun AS nome
        , LEFT(FicBasica.nomfun, CHARINDEX(' ', FicBasica.nomfun)) AS cracha
        , CASE
              WHEN FicComplementar.emapar IS NULL
                   OR REPLACE(COALESCE(FicComplementar.emapar, ''), ' ', '') = ''
                  THEN 'rh@cravil.com.br'
              ELSE COALESCE(FicComplementar.emapar, '')
          END AS email
        , CASE
              WHEN FicBasica.tipsex = 'M' THEN '1'
              WHEN FicBasica.tipsex = 'F' THEN '2'
          END AS sexo
        , CONVERT(VARCHAR(20), FicBasica.datnas, 103) AS datanasc
        , COALESCE(
              CASE
                  WHEN FicBasica.estciv IN (1, 9) THEN '4'
                  WHEN FicBasica.estciv = 2 THEN '1'
                  WHEN FicBasica.estciv = 3 THEN '3'
                  WHEN FicBasica.estciv = 4 THEN '6'
                  WHEN FicBasica.estciv = 6 THEN '2'
                  WHEN FicBasica.estciv IN (7, 5) THEN '5'
              END, ''
          ) AS estadoCivil
        , CASE
              WHEN FicBasica.codnac = 10 THEN 'Brasileira'
              ELSE 'Outros'
          END AS nacionalidade
        , cidades.NomCid AS naturalidade
        , COALESCE(FicComplementar.numcid, '') AS rg
        , CASE
              WHEN FicComplementar.emicid IS NULL
                   OR FicComplementar.emicid IN ('', ' ')
                  THEN 'SSP'
              ELSE FicComplementar.emicid
          END AS orgao
        , CASE
              WHEN GraInstr.GraIns = 1 THEN '1'
              WHEN GraInstr.GraIns IN (2, 3, 4) THEN '2'
              WHEN GraInstr.GraIns = 5 THEN '3'
              WHEN GraInstr.GraIns = 6 THEN '4'
              WHEN GraInstr.GraIns = 7 THEN '5'
              WHEN GraInstr.GraIns = 8 THEN '6'
              WHEN GraInstr.GraIns = 9 THEN '7'
              WHEN GraInstr.GraIns IN (10, 11, 12, 13) THEN '8'
          END AS grauInstru
        , CASE
              WHEN FicBasica.coddef = 1 THEN '2'
              WHEN FicBasica.coddef = 2 THEN '1'
              WHEN FicBasica.coddef = 3 THEN '6'
              WHEN FicBasica.coddef = 4 THEN '3'
              WHEN FicBasica.coddef = 5 THEN '4'
              WHEN FicBasica.coddef = 0 THEN '5'
          END AS deficiencia
        , CASE
              WHEN FicBasica.raccor IN (0, 6, 7, 8) THEN '4'
              WHEN FicBasica.raccor = 1 THEN '2'
              WHEN FicBasica.raccor = 2 THEN '6'
              WHEN FicBasica.raccor = 3 THEN '1'
              WHEN FicBasica.raccor = 4 THEN '5'
              WHEN FicBasica.raccor = 5 THEN '3'
          END AS cor
        , CASE
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) = 0.00 THEN '7'
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) <= 0.5 THEN '1'
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) > 0.5
                  AND CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) <= 1.00 THEN '2'
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) > 1.00
                  AND CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) <= 3.00 THEN '3'
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) > 3.00
                  AND CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) <= 5.00 THEN '4'
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) > 5.00
                  AND CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) <= 10.00 THEN '5'
              WHEN CAST((FicBasica.valsal + FicBasica.cplsal) / 954.00 AS DECIMAL(9, 2)) > 10.00 THEN '6'
          END AS renda
        , CASE
              WHEN FicBasica.sitafa = 1 THEN '1'
              WHEN FicBasica.sitafa = 22 THEN '2'
              ELSE '1'
          END AS situacao
        , CASE
              WHEN REPLACE(COALESCE(FicComplementar.numtel, ''), ' ', '') = ''
                   OR FicComplementar.numtel IS NULL
                  THEN '35313000'
              ELSE REPLACE(COALESCE(FicComplementar.numtel, ''), ' ', '')
          END AS fone
        , COALESCE(FicComplementar.codest, '') AS uf
        , COALESCE(FicComplementar.codcid, '') AS ibge
        , COALESCE(FicComplementar.endrua, '') AS endereco
        , COALESCE(FicComplementar.endnum, '') AS numero
        , COALESCE(bairros.NomBai, '') AS bairro
        , COALESCE(FicComplementar.endcep, '') AS cep
    FROM YOUR_DATABASE.YOUR_DATABASE.r034fun AS FicBasica
        LEFT JOIN YOUR_DATABASE.YOUR_DATABASE.r034cpl AS FicComplementar
            ON FicComplementar.numemp = FicBasica.numemp
            AND FicComplementar.tipcol = FicBasica.tipcol
            AND FicComplementar.numcad = FicBasica.numcad
        LEFT JOIN YOUR_DATABASE.YOUR_DATABASE.R022GRA AS GraInstr
            ON FicBasica.grains = GraInstr.GraIns
        LEFT JOIN YOUR_DATABASE.YOUR_DATABASE.R022def AS deficiencia
            ON FicBasica.coddef = deficiencia.CodDef
        INNER JOIN YOUR_DATABASE.YOUR_DATABASE.R074BAI AS bairros
            ON FicComplementar.codcid = bairros.CodCid
            AND FicComplementar.codbai = bairros.CodBai
        INNER JOIN YOUR_DATABASE.YOUR_DATABASE.R010SIT AS situac
            ON FicBasica.sitafa = situac.CodSit
        INNER JOIN YOUR_DATABASE.YOUR_DATABASE.R074CID AS cidades
            ON cidades.CodCid = FicComplementar.codcid
    WHERE FicBasica.sitafa <> 7
        AND FicBasica.datnas <> '1900-12-31'
        AND FicBasica.numcpf <> 0
        AND FicComplementar.numcid IS NOT NULL
        AND FicComplementar.numcid NOT IN (' ', '')
        AND FicBasica.tipcol = 1

    -- ============================================================
    -- Montagem do corpo do e-mail
    -- ============================================================
    SET @vBody = '
    <table border=0 cellpadding=0 cellspacing=0 width=402 style=border-collapse: collapse;table-layout:fixed;width:1000pt;font-family:Arial;font-size:12px>
        <tr height=20 style=color:black;>
            <td width=300 style=height:20.0pt>Anexo dados para exportação do cadastro de participantes SESCOOP.
                <br>Data de Extração: ' + CONVERT(VARCHAR(12), GETDATE(), 103) + '
            </td>
        </tr>
    </table>
    <br><br>'

    -- ============================================================
    -- Montagem da query para anexo CSV
    -- ============================================================
    SET @Query = '
    SET NOCOUNT ON;

    SELECT
          t1.cpf
        , t1.nome
        , t1.cracha
        , t1.email
        , t1.sexo
        , t1.datanasc
        , t1.estadoCivil
        , t1.nacionalidade
        , t1.naturalidade
        , t1.rg
        , t1.orgao
        , t1.grauInstru
        , t1.deficiencia
        , t1.cor
        , t1.renda
        , t1.situacao
        , t1.fone
        , t1.uf
        , t1.ibge
        , t1.endereco
        , t1.numero
        , t1.bairro
        , t1.cep
    FROM ##dadosRHsescoop AS t1'

    -- ============================================================
    -- Envio do e-mail com anexo
    -- ============================================================
    IF @ExibirApenasHtml = 0
    BEGIN
        EXEC msdb.dbo.sp_send_dbmail
            @profile_name                   = 'CRAVIL'
          , @recipients                     = 'suporte@cravil.com.br'
          , @subject                        = @vSubject
          , @body                           = @vBody
          , @body_format                    = 'HTML'
          , @query                          = @Query
          , @attach_query_result_as_file    = 1
          , @query_attachment_filename      = 'ColaboradoresCravil.csv'
          , @query_result_header            = 0
          , @query_result_separator         = @tab
          , @query_result_no_padding        = 1
          , @query_result_width             = 32767
    END
    ELSE
    BEGIN
        SELECT @vBody
    END
END
GO
