-----------------------------------------------------------------------------------------------------------------------------------------------------------
/* Execução individual e manual para ajuste do Flyway */
-- SELECT * FROM schema_version_v2 svv ORDER BY svv.installed_on DESC
-- DELETE schema_version_v2 WHERE version_rank > 1 AND type <> 'BASELINE'
/* Execução DINÂMICA para ajuste do Flyway */
-- A variável @TOTAL_DATABASES_NECESSARIO deve ser atualizada com o valor da seguinte consulta
-- executada na base d_YOUR_OBJECT_admYOUR_OBJECT, server rds.hmg.YOUR_OBJECT.com.br:
-- SELECT COUNT(*) AS TOTAL FROM schema_version_v2
-----------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @DATABASES_VALIDOS TABLE(
                           id_database INT IDENTITY(1,1)
                         , nm_database VARCHAR(100)
                        )
DECLARE @TOTAL_DATABASES INT
      , @I INT
      , @DATABASE VARCHAR(100)
      , @CMD VARCHAR(4000)
      , @TOTAL_SCRIPTS_NECESSARIOS VARCHAR(10) = '118'

INSERT INTO @DATABASES_VALIDOS(nm_database)
SELECT name FROM sys.databases
WHERE name NOT IN ('master','model','tempdb', 'msdb')
AND name NOT LIKE 'H_%' 
AND state_desc = 'online'

IF OBJECT_ID('tempdb..#qtd_scripts_databases') IS NOT NULL 
    DROP TABLE #qtd_scripts_databases

CREATE TABLE #qtd_scripts_databases (qtd_executada INT, database_client VARCHAR(120))

SET @I = 1
SET @TOTAL_DATABASES = (SELECT MAX(Id_Database) FROM @DATABASES_VALIDOS)

WHILE(@I <= @TOTAL_DATABASES)
BEGIN 
    SELECT @DATABASE = nm_database FROM @DATABASES_VALIDOS WHERE id_database = @I       
        SET @CMD = 
        '
        IF ((SELECT COUNT(*) FROM [' + @DATABASE + '].sys.sysobjects so WHERE so.xtype = N''U'' AND so.name LIKE N''schema_version_v2'') > 0)
        BEGIN
            IF ((SELECT COUNT(*) FROM [' + @DATABASE + '].dbo.schema_version_v2) < ' + @TOTAL_SCRIPTS_NECESSARIOS + ')
            BEGIN
                INSERT INTO #qtd_scripts_databases (qtd_executada, database_client)
                VALUES( (SELECT COUNT(*) FROM [' + @DATABASE + '].dbo.schema_version_v2), ''' + @DATABASE + ''');
            END
        END
        '       
    EXEC(@CMD);
    SET @I = @I + 1
END 


-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Clientes com problema no flyway
-- verifica qual é a quantidade de scripts antes de deletar
-----------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT * FROM #qtd_scripts_databases


