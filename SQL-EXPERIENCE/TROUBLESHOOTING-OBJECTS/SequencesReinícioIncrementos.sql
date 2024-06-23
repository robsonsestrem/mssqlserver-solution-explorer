DECLARE @sth bigint;
SET @sth = 1000;
DECLARE @sql nvarchar(max);
SET @sql = N'ALTER SEQUENCE StreamEntrySequence RESTART WITH ' + cast(@sth as nvarchar(20)) + ';';
EXEC SP_EXECUTESQL @sql;

----------------------------------------------------------------------------------------------
-- seq_cd_plaac - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_plaac'
-- plaac = 24539909

select max(CD_PLAAC) from PLAAC -- 24534975

ALTER SEQUENCE seq_cd_plaac
RESTART WITH 24534976


----------------------------------------------------------------------------------------------
-- seq_cd_acspa - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_acspa'
-- acspa = 2108888

select max(CD_ACSPA) from ACSPA --3062626

ALTER SEQUENCE seq_cd_acspa
RESTART WITH 3062627


----------------------------------------------------------------------------------------------
-- seq_cd_pssoa - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_pssoa'

select max(CD_PSSOA) from PSSOA -- 1738983

ALTER SEQUENCE seq_cd_pssoa
RESTART WITH 1738984


----------------------------------------------------------------------------------------------
-- seq_cd_cnsul - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_cnsul' -- 1315570

select max(CD_cnsul) from CNSUL -- 1315570

ALTER SEQUENCE seq_cd_cnsul
RESTART WITH 1315571


----------------------------------------------------------------------------------------------
-- seq_cd_avals - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_avals' -- 1478120

select max(CD_AVALS) from AVALS -- 2478115 

ALTER SEQUENCE seq_cd_avals
RESTART WITH 2478116


----------------------------------------------------------------------------------------------
-- seq_cd_respc - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_respc'     -- 7884097

select max(CD_RESPC) from RESPC -- 25884084

ALTER SEQUENCE seq_cd_respc
RESTART WITH 25884086


----------------------------------------------------------------------------------------------
-- seq_cd_hipdi - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_hipdi'     -- 1070034

select max(CD_HIPDI) from HIPDI -- 1070034

ALTER SEQUENCE seq_cd_hipdi
RESTART WITH 1070035


----------------------------------------------------------------------------------------------
-- seq_cd_ctrnh - ok
----------------------------------------------------------------------------------------------
SELECT current_value
FROM sys.sequences
WHERE name = 'seq_cd_ctrnh'     -- 42541238

select max(CD_CTRNH) from CTRNH -- 142093333

ALTER SEQUENCE seq_cd_ctrnh
RESTART WITH 142093334





