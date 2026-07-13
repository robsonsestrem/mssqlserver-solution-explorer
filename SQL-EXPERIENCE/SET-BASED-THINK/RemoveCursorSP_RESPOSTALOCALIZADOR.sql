USE H_YOUR_DATABASE
GO

-- procedure original
CREATE OR ALTER PROCEDURE [dbo].[SP_RESPOSTALOCALIZADOR](@CD_QUEST INT, @CODIGO_RESPOSTA VARCHAR(256)) AS
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

DECLARE AUX CURSOR READ_ONLY LOCAL FOR

    SELECT
    LCZDR.CD_LCZDR,
    LCZDR.VL_TABLE,
    LCZDR.VL_FILTRO,
    FLDLC.CD_FLDLC,
    FLDLC.VL_FIELD,
    FLDLC.VL_TYPE,
    FLDLC.VL_HIDDEN,
    FLDLC.VL_PRIMARY
    FROM LCZDR
    INNER JOIN FLDLC ON FLDLC.CD_LCZDR = LCZDR.CD_LCZDR
    INNER JOIN QSTLC ON QSTLC.CD_LCZDR = LCZDR.CD_LCZDR
    INNER JOIN QUEST ON QUEST.CD_QUEST = QSTLC.CD_QUEST
    WHERE QUEST.CD_QUEST = @CD_QUEST
    ORDER BY FLDLC.VL_PRIMARY DESC, FLDLC.VL_HIDDEN, FLDLC.CD_FLDLC;

OPEN AUX;

FETCH NEXT FROM AUX INTO @CD_LCZDR, @VL_TABLE, @VL_FILTRO, @CD_FLDLC, @VL_FIELD, @VL_TYPE, @VL_HIDDEN, @VL_PRIMARY;

IF @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'SELECT ''' + CONVERT(VARCHAR,@CD_QUEST) + ''' CD_QUEST, ''' + @CODIGO_RESPOSTA + ''' VL_RESPC_TEXTO, @COLUNA@ RESPOSTA FROM ' + @VL_TABLE + ' WHERE ' + CASE WHEN LEN(@VL_FILTRO) > 0 THEN @VL_FILTRO + ' AND ' ELSE '' END + ' @PRIMARY@ ';
END

WHILE @@FETCH_STATUS = 0
BEGIN
    IF @VL_PRIMARY = 1
    BEGIN
        SELECT @COL_PRIMARY = @COL_PRIMARY + CASE WHEN LEN(@COL_PRIMARY) > 0 THEN ' AND ' ELSE '' END + @VL_FIELD + ' = ' + (SELECT ELEMENT FROM DBO.FUNC_SPLIT(@CODIGO_RESPOSTA, ';') WHERE ELEMENTID = @IDX);
        SET @IDX = @IDX + 1;
    END

    IF @VL_HIDDEN = 0
    BEGIN
        SELECT @COL_SHOW = @COL_SHOW + CASE WHEN LEN(@COL_SHOW) > 0 THEN ' + '' / '' + ' ELSE '' END + 'CONVERT(VARCHAR(8000),' + @VL_FIELD + ')';
    END

    FETCH NEXT FROM AUX INTO @CD_LCZDR, @VL_TABLE, @VL_FILTRO, @CD_FLDLC, @VL_FIELD, @VL_TYPE, @VL_HIDDEN, @VL_PRIMARY;
END

IF LEN(@SQL) > 0
BEGIN
    SET @SQL = REPLACE(@SQL,'@COLUNA@',@COL_SHOW);
    SET @SQL = REPLACE(@SQL,'@PRIMARY@',@COL_PRIMARY);

    EXEC(@SQL);
END

CLOSE AUX;
DEALLOCATE AUX;

GO


/************************************************************************************************************************************************************************************/
/*
    AJUSTES SET BASED
    1. Remoção do cursor    
    
*/
/*
 *
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
 *
 *
 */
SET STATISTICS IO, TIME ON;

DECLARE @CD_QUEST INT = 3444
DECLARE @CODIGO_RESPOSTA VARCHAR(256) = '59416'
--59416 -> LOGICAL READS: 15
--63435 -> LOGICAL READS: 15
--59741 -> LOGICAL READS: 15
--66689 -> LOGICAL READS: 15
--60688 -> LOGICAL READS: 15
--51022 -> LOGICAL READS: 15

DECLARE @SQL VARCHAR(8000) = '';
DECLARE @COL_PRIMARY VARCHAR(8000) = '';
DECLARE @COL_SHOW VARCHAR(8000) = '';
DECLARE @VL_TABLE VARCHAR(256);
DECLARE @VL_FILTRO VARCHAR(8000) = '';

-- Passo 1: Armazenar os valores divididos de @CODIGO_RESPOSTA
IF OBJECT_ID('tempdb..#SplitValues') IS NOT NULL DROP TABLE #SplitValues;

SELECT ELEMENTID, ELEMENT
INTO #SplitValues
FROM DBO.FUNC_SPLIT(@CODIGO_RESPOSTA, ';');

-- Passo 2: Obter os campos necessários com ordenação correta e RowNum
IF OBJECT_ID('tempdb..#DataSource') IS NOT NULL DROP TABLE #DataSource;

SELECT 
    LCZDR.CD_LCZDR,
    LCZDR.VL_TABLE,
    LCZDR.VL_FILTRO,
    FLDLC.CD_FLDLC,
    FLDLC.VL_FIELD,
    FLDLC.VL_TYPE,
    FLDLC.VL_HIDDEN,
    FLDLC.VL_PRIMARY,
    ROW_NUMBER() OVER (
        ORDER BY 
            FLDLC.VL_PRIMARY DESC, 
            FLDLC.VL_HIDDEN, 
            FLDLC.CD_FLDLC
    ) AS RowNum -- <-- Added here
INTO #DataSource
FROM LCZDR
INNER JOIN FLDLC ON FLDLC.CD_LCZDR = LCZDR.CD_LCZDR
INNER JOIN QSTLC ON QSTLC.CD_LCZDR = LCZDR.CD_LCZDR
INNER JOIN QUEST ON QUEST.CD_QUEST = QSTLC.CD_QUEST
WHERE QUEST.CD_QUEST = @CD_QUEST;

-- Passo 3: Extrair a tabela base e filtro
SELECT TOP 1 
    @VL_TABLE = VL_TABLE,
    @VL_FILTRO = VL_FILTRO
FROM #DataSource;

-- Passo 4: Montar @COL_PRIMARY com base nos campos marcados como PRIMARY
SELECT @COL_PRIMARY = STRING_AGG(VL_FIELD + ' = ' + s.ELEMENT, ' AND ')
FROM #DataSource d
JOIN #SplitValues s ON d.RowNum = s.ELEMENTID
WHERE d.VL_PRIMARY = 1;

-- Passo 5: Montar @COL_SHOW com base nos campos NÃO ocultos
SELECT @COL_SHOW = STRING_AGG('CONVERT(VARCHAR(8000), ' + VL_FIELD + ')', ' + '' / '' + ')
FROM #DataSource
WHERE VL_HIDDEN = 0;

-- Passo 6: Construir a query final
SET @SQL = 'SELECT ''' + CONVERT(VARCHAR,@CD_QUEST) + ''' CD_QUEST, ''' + @CODIGO_RESPOSTA + ''' VL_RESPC_TEXTO, ' +
           ISNULL(@COL_SHOW, 'NULL') + ' RESPOSTA FROM ' + @VL_TABLE + ' WHERE ' +
           CASE WHEN LEN(@VL_FILTRO) > 0 THEN @VL_FILTRO + ' AND ' ELSE '' END +
           ISNULL(@COL_PRIMARY, '1=1');

-- Exibir e executar
 PRINT '===================================';
 PRINT @SQL;
 PRINT '===================================';

EXEC (@SQL);


----------------------------------------
-- exemplo de sql gerado
----------------------------------------
SELECT '3444' CD_QUEST, '59416' VL_RESPC_TEXTO, CONVERT(VARCHAR(8000), DS_MDCMT_PRINC_ATIVO) + ' / ' + CONVERT(VARCHAR(8000), DS_MDCMT_PRODT) + ' / ' + CONVERT(VARCHAR(8000), DS_MDCMT_APRES) + ' / ' + CONVERT(VARCHAR(8000), DS_MDCMT_CLASS_TRPTC) RESPOSTA FROM MDCMT WHERE CD_MDCMT = 59416



SELECT * FROM #DataSource AS DS
SELECT * FROM #SplitValues AS SV



