
-- Usado pelo Adriel
--SELECT
--       c.name
--       ,c.collation       
--  FROM SYSCOLUMNS c
--  WHERE COLLATION <> 'SQL_Latin1_General_CP1_CI_AS';

SELECT TABLE_NAME, COLUMN_NAME, COLLATION_NAME
FROM H_HEALTHMAP_QAS.INFORMATION_SCHEMA.COLUMNS
WHERE COLLATION_NAME <> 'SQL_Latin1_General_CP1_CI_AS' 
ORDER BY TABLE_NAME ASC 

SELECT TABLE_NAME, COLUMN_NAME, COLLATION_NAME
FROM XPTO.INFORMATION_SCHEMA.COLUMNS
WHERE COLLATION_NAME <> 'SQL_Latin1_General_CP1_CI_AS' 
ORDER BY TABLE_NAME ASC 


CREATE TABLE ##dados_collate
  (
  id INT IDENTITY(1,1) PRIMARY KEY,
  DATABASENAME VARCHAR(200),
  TABLE_NAME VARCHAR(200),
  COLUMN_NAME VARCHAR(200),
  COLLATION_NAME VARCHAR(200)
  )

CREATE TABLE ##databases_online
  (
  id INT IDENTITY(1,1) PRIMARY KEY,
  name VARCHAR(200)
  )

INSERT INTO ##databases_online
SELECT d.name
FROM sys.databases d WHERE d.state = 0

DECLARE @todas INT = (SELECT COUNT(*) FROM ##databases_online);
DECLARE @contador INT = 0;

WHILE(@contador < @todas)
  BEGIN 
    SELECT @contador += 1;
    PRINT @contador
    
    DECLARE @databasename VARCHAR(200) = (SELECT d.name FROM ##databases_online d WHERE d.id = @contador)
    PRINT @databasename
    DECLARE @comando VARCHAR(MAX);
  
    SET @comando = 
    '
    INSERT INTO ##dados_collate 
    SELECT ''' + @databasename + ''', TABLE_NAME, COLUMN_NAME, COLLATION_NAME
    FROM ' + @databasename + '.INFORMATION_SCHEMA.COLUMNS
    WHERE COLLATION_NAME <> ''SQL_Latin1_General_CP1_CI_AS'' 
    ORDER BY TABLE_NAME ASC
    ' 
  
    EXECUTE (@comando)

  END 

SELECT * FROM ##dados_collate dc

