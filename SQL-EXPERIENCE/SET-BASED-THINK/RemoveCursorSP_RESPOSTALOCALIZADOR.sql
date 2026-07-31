/*
 *
	OBJETIVO: Refatoração da procedure SP_RESPOSTALOCALIZADOR, comparando a 
			  implementação original baseada em cursor com a versão otimizada 
			  SET BASED para redução de leituras lógicas e eliminação de RBAR.
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Procedure original baseada em cursor (RBAR)
-- ============================================================
USE H_YOUR_DATABASE
GO

CREATE OR ALTER PROCEDURE [dbo].[SP_RESPOSTALOCALIZADOR]
    @CD_QUEST INT
    ,@CODIGO_RESPOSTA VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;

    -- Declaração de variáveis de controle e montagem de string dinâmica
    DECLARE @SQL VARCHAR(8000) = '';
    DECLARE @COL_PRIMARY VARCHAR(8000) = '';
    DECLARE @COL_SHOW VARCHAR(8000) = '';
    DECLARE @CD_LCZDR VARCHAR(256);
    DECLARE @VL_TABLE VARCHAR(256);
    DECLARE @VL_FILTRO VARCHAR(256);
    DECLARE @CD_FLDLC VARCHAR(256);
    DECLARE @VL_FIELD VARCHAR(256);
    DECLARE @VL_TYPE VARCHAR(256);
    DECLARE @VL_HIDDEN VARCHAR(256);
    DECLARE @VL_PRIMARY VARCHAR(256);
    DECLARE @IDX INT = 1;

    -- Declaração do cursor para iteração linha a linha
    DECLARE AUX CURSOR READ_ONLY LOCAL FOR
    SELECT 
        LCZDR.CD_LCZDR
        ,LCZDR.VL_TABLE
        ,LCZDR.VL_FILTRO
        ,FLDLC.CD_FLDLC
        ,FLDLC.VL_FIELD
        ,FLDLC.VL_TYPE
        ,FLDLC.VL_HIDDEN
        ,FLDLC.VL_PRIMARY
    FROM LCZDR
    INNER JOIN FLDLC 
        ON FLDLC.CD_LCZDR = LCZDR.CD_LCZDR
    INNER JOIN QSTLC 
        ON QSTLC.CD_LCZDR = LCZDR.CD_LCZDR
    INNER JOIN QUEST 
        ON QUEST.CD_QUEST = QSTLC.CD_QUEST
    WHERE QUEST.CD_QUEST = @CD_QUEST
    ORDER BY 
        FLDLC.VL_PRIMARY DESC
        ,FLDLC.VL_HIDDEN
        ,FLDLC.CD_FLDLC;

    OPEN AUX;

    FETCH NEXT FROM AUX 
    INTO @CD_LCZDR, @VL_TABLE, @VL_FILTRO, @CD_FLDLC, @VL_FIELD, @VL_TYPE, @VL_HIDDEN, @VL_PRIMARY;

    -- Inicialização da query dinâmica caso haja registros
    IF @@FETCH_STATUS = 0
    BEGIN
        SET @SQL = 'SELECT ''' + CONVERT(VARCHAR, @CD_QUEST) + ''' AS CD_QUEST, ''' + @CODIGO_RESPOSTA + ''' AS VL_RESPC_TEXTO, @COLUNA@ AS RESPOSTA FROM ' + @VL_TABLE + ' WHERE ' + CASE WHEN LEN(@VL_FILTRO) > 0 THEN @VL_FILTRO + ' AND ' ELSE '' END + ' @PRIMARY@ ';
    END

    -- Iteração sobre os registros do cursor para montagem das cláusulas
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Montagem da cláusula PRIMARY
        IF @VL_PRIMARY = 1
        BEGIN
            SELECT 
                @COL_PRIMARY = @COL_PRIMARY + CASE WHEN LEN(@COL_PRIMARY) > 0 THEN ' AND ' ELSE '' END + @VL_FIELD + ' = ' + (
                    SELECT ELEMENT 
                    FROM DBO.FUNC_SPLIT(@CODIGO_RESPOSTA, ';') 
                    WHERE ELEMENTID = @IDX
                );
            SET @IDX = @IDX + 1;
        END

        -- Montagem da cláusula SHOW para campos não ocultos
        IF @VL_HIDDEN = 0
        BEGIN
            SELECT 
                @COL_SHOW = @COL_SHOW + CASE WHEN LEN(@COL_SHOW) > 0 THEN ' + '' / '' + ' ELSE '' END + 'CONVERT(VARCHAR(8000),' + @VL_FIELD + ')';
        END

        FETCH NEXT FROM AUX 
        INTO @CD_LCZDR, @VL_TABLE, @VL_FILTRO, @CD_FLDLC, @VL_FIELD, @VL_TYPE, @VL_HIDDEN, @VL_PRIMARY;
    END

    -- Execução da query dinâmica montada
    IF LEN(@SQL) > 0
    BEGIN
        SET @SQL = REPLACE(@SQL, '@COLUNA@', @COL_SHOW);
        SET @SQL = REPLACE(@SQL, '@PRIMARY@', @COL_PRIMARY);
        EXEC(@SQL);
    END

    -- Encerramento e liberação do cursor
    CLOSE AUX;
    DEALLOCATE AUX;
END
GO

-- ============================================================
-- AJUSTES SET BASED: Remoção do cursor e otimização de leituras
-- ============================================================
/*
-------------------------------------------------------------------------
-- MÉDIA DAS MEDIÇÕES - QUERY * O T I M I Z A D A * --
-------------------------------------------------------------------------
Table        Scan Count  Logical Reads   % Logical Reads of Total Reads
#B1A342B6    1           1                6.667
#DataSource  3           3               20.000
#SplitValues 1           1                6.667
FLDLC        1           2               13.333
LCZDR        0           2               13.333
MDCMT        0           2               13.333
QSTLC        1           2               13.333
QUEST        0           2               13.333
Worktable    0           0                0.000
-------------------------------------------------------------------------
Total        7           15
-------------------------------------------------------------------------
*/

SET STATISTICS IO, TIME ON;

-- Declaração de variáveis para teste da versão otimizada
DECLARE @CD_QUEST INT = 3444;
DECLARE @CODIGO_RESPOSTA VARCHAR(256) = '59416';
-- 59416 -> LOGICAL READS: 15
-- 63435 -> LOGICAL READS: 15
-- 59741 -> LOGICAL READS: 15
-- 66689 -> LOGICAL READS: 15
-- 60688 -> LOGICAL READS: 15
-- 51022 -> LOGICAL READS: 15

DECLARE @SQL_OPT VARCHAR(8000) = '';
DECLARE @COL_PRIMARY_OPT VARCHAR(8000) = '';
DECLARE @COL_SHOW_OPT VARCHAR(8000) = '';
DECLARE @VL_TABLE_OPT VARCHAR(256);
DECLARE @VL_FILTRO_OPT VARCHAR(8000) = '';

-- Passo 1: Armazenar os valores divididos de @CODIGO_RESPOSTA em tabela temporária
IF OBJECT_ID('tempdb..#SplitValues') IS NOT NULL 
BEGIN
    DROP TABLE #SplitValues;
END

SELECT 
    ELEMENTID
    ,ELEMENT
INTO #SplitValues
FROM DBO.FUNC_SPLIT(@CODIGO_RESPOSTA, ';');

-- Passo 2: Obter os campos necessários com ordenação correta e RowNum
IF OBJECT_ID('tempdb..#DataSource') IS NOT NULL 
BEGIN
    DROP TABLE #DataSource;
END

SELECT 
    LCZDR.CD_LCZDR
    ,LCZDR.VL_TABLE
    ,LCZDR.VL_FILTRO
    ,FLDLC.CD_FLDLC
    ,FLDLC.VL_FIELD
    ,FLDLC.VL_TYPE
    ,FLDLC.VL_HIDDEN
    ,FLDLC.VL_PRIMARY
    ,ROW_NUMBER() OVER (
        ORDER BY 
            FLDLC.VL_PRIMARY DESC
            ,FLDLC.VL_HIDDEN
            ,FLDLC.CD_FLDLC
    ) AS RowNum
INTO #DataSource
FROM LCZDR
INNER JOIN FLDLC 
    ON FLDLC.CD_LCZDR = LCZDR.CD_LCZDR
INNER JOIN QSTLC 
    ON QSTLC.CD_LCZDR = LCZDR.CD_LCZDR
INNER JOIN QUEST 
    ON QUEST.CD_QUEST = QSTLC.CD_QUEST
WHERE QUEST.CD_QUEST = @CD_QUEST;

-- Passo 3: Extrair a tabela base e filtro
SELECT TOP 1 
    @VL_TABLE_OPT = VL_TABLE
    ,@VL_FILTRO_OPT = VL_FILTRO
FROM #DataSource;

-- Passo 4: Montar @COL_PRIMARY com base nos campos marcados como PRIMARY
SELECT 
    @COL_PRIMARY_OPT = STRING_AGG(VL_FIELD + ' = ' + s.ELEMENT, ' AND ')
FROM #DataSource AS d
INNER JOIN #SplitValues AS s 
    ON d.RowNum = s.ELEMENTID
WHERE d.VL_PRIMARY = 1;

-- Passo 5: Montar @COL_SHOW com base nos campos NÃO ocultos
SELECT 
    @COL_SHOW_OPT = STRING_AGG('CONVERT(VARCHAR(8000), ' + VL_FIELD + ')', ' + '' / '' + ')
FROM #DataSource
WHERE VL_HIDDEN = 0;

-- Passo 6: Construir a query final
SET @SQL_OPT = 'SELECT ''' + CONVERT(VARCHAR, @CD_QUEST) + ''' AS CD_QUEST, ''' + @CODIGO_RESPOSTA + ''' AS VL_RESPC_TEXTO, ' +
    ISNULL(@COL_SHOW_OPT, 'NULL') + ' AS RESPOSTA FROM ' + @VL_TABLE_OPT + ' WHERE ' +
    CASE WHEN LEN(@VL_FILTRO_OPT) > 0 THEN @VL_FILTRO_OPT + ' AND ' ELSE '' END +
    ISNULL(@COL_PRIMARY_OPT, '1=1');

-- Exibir e executar a query dinâmica otimizada
PRINT '===================================';
PRINT @SQL_OPT;
PRINT '===================================';

EXEC (@SQL_OPT);

-- Exemplo de SQL gerado:
-- SELECT '3444' AS CD_QUEST, '59416' AS VL_RESPC_TEXTO, CONVERT(VARCHAR(8000), DS_MDCMT_PRINC_ATIVO) + ' / ' + CONVERT(VARCHAR(8000), DS_MDCMT_PRODT) + ' / ' + CONVERT(VARCHAR(8000), DS_MDCMT_APRES) + ' / ' + CONVERT(VARCHAR(8000), DS_MDCMT_CLASS_TRPTC) AS RESPOSTA FROM MDCMT WHERE CD_MDCMT = 59416

-- Consultas de validação das tabelas temporárias
SELECT * 
FROM #DataSource AS DS;

SELECT * 
FROM #SplitValues AS SV;

SET STATISTICS IO, TIME OFF;