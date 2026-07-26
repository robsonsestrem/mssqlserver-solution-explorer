/*
	OBJETIVO: Identificar bases de dados que possuem a tabela de versionamento
			  do Flyway (schema_version_v2, exemplo de solução do Java) e cuja quantidade de scripts aplicados
			  é inferior ao total esperado, auxiliando na correção de inconsistências no processo de migração.
	PROJETO: mssqlserver-solution-explorer
*/

-- ============================================================
-- Execução individual e manual para ajuste do Flyway
-- ============================================================
-- SELECT *
-- FROM schema_version_v2 svv
-- ORDER BY svv.installed_on DESC;

-- DELETE
-- FROM schema_version_v2
-- WHERE version_rank > 1
--       AND type <> 'BASELINE';

-- ============================================================
-- Execução DINÂMICA para ajuste do Flyway
-- A variável @TOTAL_SCRIPTS_NECESSARIOS deve ser atualizada com o
-- valor obtido da consulta de referência na base d_YOUR_OBJECT_admYOUR_OBJECT,
-- servidor rds.hmg.YOUR_OBJECT.com.br:
-- SELECT COUNT(*) AS TOTAL FROM schema_version_v2;
-- ============================================================

-- ============================================================
-- Declaração das variáveis e tabelas temporárias
-- ============================================================
DECLARE @DATABASES_VALIDOS TABLE
(
      id_database INT IDENTITY(1, 1)
    , nm_database VARCHAR(100)
);

DECLARE @TOTAL_DATABASES              INT;
DECLARE @I                            INT = 1;
DECLARE @DATABASE                     VARCHAR(100);
DECLARE @CMD                          VARCHAR(4000);
DECLARE @TOTAL_SCRIPTS_NECESSARIOS    VARCHAR(10) = '118';

-- ============================================================
-- Preencher a tabela com os bancos de dados válidos
-- (exclui bases de sistema e bases H_* que não são de interesse)
-- ============================================================
INSERT INTO @DATABASES_VALIDOS
(
      nm_database
)
SELECT name
FROM sys.databases
WHERE name NOT IN ('master', 'model', 'tempdb', 'msdb')
      AND name NOT LIKE 'H_%'
      AND state_desc = 'online';

-- ============================================================
-- Criar tabela temporária para armazenar a contagem por base
-- ============================================================
IF OBJECT_ID('tempdb..#qtd_scripts_databases') IS NOT NULL
BEGIN
    DROP TABLE #qtd_scripts_databases;
END;

CREATE TABLE #qtd_scripts_databases
(
      qtd_executada   INT
    , database_client VARCHAR(120)
);

-- ============================================================
-- Loop dinâmico para percorrer todas as bases válidas
-- ============================================================
SET @TOTAL_DATABASES = (SELECT MAX(id_database) FROM @DATABASES_VALIDOS);

WHILE (@I <= @TOTAL_DATABASES)
BEGIN
    SELECT @DATABASE = nm_database
    FROM @DATABASES_VALIDOS
    WHERE id_database = @I;

    SET @CMD =
        '
        IF ((SELECT COUNT(*)
             FROM [' + @DATABASE + '].sys.sysobjects so
             WHERE so.xtype = N''U''
                   AND so.name LIKE N''schema_version_v2'') > 0)
        BEGIN
            IF ((SELECT COUNT(*)
                 FROM [' + @DATABASE + '].dbo.schema_version_v2) < ' + @TOTAL_SCRIPTS_NECESSARIOS + ')
            BEGIN
                INSERT INTO #qtd_scripts_databases
                (
                      qtd_executada
                    , database_client
                )
                VALUES
                (
                      (SELECT COUNT(*)
                       FROM [' + @DATABASE + '].dbo.schema_version_v2)
                    , ''' + @DATABASE + '''
                );
            END
        END
        ';

    EXEC(@CMD);

    SET @I = @I + 1;
END;

-- ============================================================
-- Clientes com problema no Flyway
-- Verifica qual é a quantidade de scripts antes de deletar
-- ============================================================
SELECT *
FROM #qtd_scripts_databases;
