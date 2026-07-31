/*
 *
	OBJETIVO: Script T-SQL para consulta de valores atuais e reordenação (restart)
			  de Sequences do banco de dados com base no maior valor das tabelas de negócio.
	PROJETO: mssqlserver-solution-explorer
 *	
 */
-- ============================================================
-- Reordenação e Ajuste do Valor Atual de Sequences de Banco
-- ============================================================

-- Reinicialização dinâmica da sequence StreamEntrySequence
DECLARE @sth BIGINT;
SET @sth = 1000;

DECLARE @sql NVARCHAR(MAX);
SET @sql = N'ALTER SEQUENCE StreamEntrySequence RESTART WITH ' + CAST(@sth AS NVARCHAR(20)) + ';';

EXEC SP_EXECUTESQL @sql;
GO

-- ============================================================
-- Sequence: seq_cd_plaac
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_plaac
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_plaac';

-- Identificação do maior código na tabela PLAAC (plaac = 24539909 / max = 24534975)
SELECT
    MAX(P.CD_PLAAC) AS max_cd_plaac
FROM PLAAC AS P;

-- Reajuste do valor inicial da sequence seq_cd_plaac
ALTER SEQUENCE seq_cd_plaac
RESTART WITH 24534976;
GO

-- ============================================================
-- Sequence: seq_cd_acspa
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_acspa
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_acspa';

-- Identificação do maior código na tabela ACSPA (acspa = 2108888 / max = 3062626)
SELECT
    MAX(A.CD_ACSPA) AS max_cd_acspa
FROM ACSPA AS A;

-- Reajuste do valor inicial da sequence seq_cd_acspa
ALTER SEQUENCE seq_cd_acspa
RESTART WITH 3062627;
GO

-- ============================================================
-- Sequence: seq_cd_pssoa
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_pssoa
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_pssoa';

-- Identificação do maior código na tabela PSSOA (max = 1738983)
SELECT
    MAX(P.CD_PSSOA) AS max_cd_pssoa
FROM PSSOA AS P;

-- Reajuste do valor inicial da sequence seq_cd_pssoa
ALTER SEQUENCE seq_cd_pssoa
RESTART WITH 1738984;
GO

-- ============================================================
-- Sequence: seq_cd_cnsul
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_cnsul
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_cnsul';

-- Identificação do maior código na tabela CNSUL (max = 1315570)
SELECT
    MAX(C.CD_cnsul) AS max_cd_cnsul
FROM CNSUL AS C;

-- Reajuste do valor inicial da sequence seq_cd_cnsul
ALTER SEQUENCE seq_cd_cnsul
RESTART WITH 1315571;
GO

-- ============================================================
-- Sequence: seq_cd_avals
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_avals
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_avals';

-- Identificação do maior código na tabela AVALS (avals = 1478120 / max = 2478115)
SELECT
    MAX(A.CD_AVALS) AS max_cd_avals
FROM AVALS AS A;

-- Reajuste do valor inicial da sequence seq_cd_avals
ALTER SEQUENCE seq_cd_avals
RESTART WITH 2478116;
GO

-- ============================================================
-- Sequence: seq_cd_respc
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_respc
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_respc';

-- Identificação do maior código na tabela RESPC (respc = 7884097 / max = 25884084)
SELECT
    MAX(R.CD_RESPC) AS max_cd_respc
FROM RESPC AS R;

-- Reajuste do valor inicial da sequence seq_cd_respc
ALTER SEQUENCE seq_cd_respc
RESTART WITH 25884086;
GO

-- ============================================================
-- Sequence: seq_cd_hipdi
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_hipdi
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_hipdi';

-- Identificação do maior código na tabela HIPDI (max = 1070034)
SELECT
    MAX(H.CD_HIPDI) AS max_cd_hipdi
FROM HIPDI AS H;

-- Reajuste do valor inicial da sequence seq_cd_hipdi
ALTER SEQUENCE seq_cd_hipdi
RESTART WITH 1070035;
GO

-- ============================================================
-- Sequence: seq_cd_ctrnh
-- ============================================================

-- Consulta do valor atual da sequence seq_cd_ctrnh
SELECT
    S.current_value
FROM sys.sequences AS S
WHERE S.name = 'seq_cd_ctrnh';

-- Identificação do maior código na tabela CTRNH (ctrnh = 42541238 / max = 142093333)
SELECT
    MAX(C.CD_CTRNH) AS max_cd_ctrnh
FROM CTRNH AS C;

-- Reajuste do valor inicial da sequence seq_cd_ctrnh
ALTER SEQUENCE seq_cd_ctrnh
RESTART WITH 142093334;
GO
