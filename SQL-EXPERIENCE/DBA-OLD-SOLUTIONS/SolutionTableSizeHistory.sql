/*
 *
    OBJETIVO: Rotina para armazenamento diário do tamanho das tabelas de todas as bases de dados,
              permitindo monitoramento de crescimento por dia, mês ou ano para planejamento de espaço em disco.
    PROJETO: mssqlserver-solution-explorer

    ESTRUTURA CRIADA:
    - Management.InstanceServer
    - Management.InstanceDatabases
    - Management.InstanceTables
    - Management.HistorySizeTables
    - Management.vw_SizeTables
    - Management.sp_LoadSizeTables

    REFERÊNCIA BASE: Fabrício Lima     
 *
 */
-- ================================================================================================================================
-- Com essas informações, o DBA pode identificar tendências de crescimento, projetar a demanda futura de armazenamento, 
-- detectar comportamentos anormais de expansão e estabelecer indicadores de capacidade. Esse histórico é essencial 
-- para atividades de Capacity Planning, auxiliando na definição de estratégias de expansão da infraestrutura, 
-- otimização do uso de armazenamento e previsão de investimentos necessários em recursos de disco antes 
-- que a capacidade disponível se torne um fator de risco para a operação.
-- ================================================================================================================================


-- ================================================================================================================================
-- CRIAÇÃO DAS TABELAS DE MONITORAMENTO
-- ================================================================================================================================
USE DBA_PerformanceHub
GO

IF OBJECT_ID('Management.HistorySizeTables') IS NOT NULL
    DROP TABLE Management.HistorySizeTables

IF OBJECT_ID('Management.InstanceDatabases') IS NOT NULL
    DROP TABLE Management.InstanceDatabases

IF OBJECT_ID('Management.InstanceTables') IS NOT NULL
    DROP TABLE Management.InstanceTables

IF OBJECT_ID('Management.InstanceServer') IS NOT NULL
    DROP TABLE Management.InstanceServer


-- ================================================================================================================================
-- TABELA: InstanceTables
-- Armazena os nomes das tabelas monitoradas
-- ================================================================================================================================
CREATE TABLE Management.[InstanceTables]
(
    [IdTabela] [INT] IDENTITY(1, 1) NOT NULL,
    [NmTabela] [VARCHAR](1000) NULL,
    CONSTRAINT [PK_Tabelas] PRIMARY KEY CLUSTERED
    (
        [IdTabela] ASC
    ) WITH
    (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
) ON [PRIMARY]
GO


-- ================================================================================================================================
-- TABELA: InstanceServer
-- Armazena os nomes dos servidores monitorados
-- ================================================================================================================================
CREATE TABLE Management.[InstanceServer]
(
    [IdServidor] [SMALLINT] IDENTITY(1, 1) NOT NULL,
    [NmServidor] [VARCHAR](50) NOT NULL,
    CONSTRAINT [PK_Servidores] PRIMARY KEY CLUSTERED
    (
        [IdServidor] ASC
    ) WITH
    (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
) ON [PRIMARY]
GO


-- ================================================================================================================================
-- TABELA: InstanceDatabases
-- Armazena os nomes das bases de dados monitoradas
-- ================================================================================================================================
CREATE TABLE Management.[InstanceDatabases]
(
    [IdBaseDados] [INT] IDENTITY(1, 1) NOT NULL,
    [NmDatabase] [VARCHAR](100) NULL,
    CONSTRAINT [PK_BaseDeDados] PRIMARY KEY CLUSTERED
    (
        [IdBaseDados] ASC
    ) WITH
    (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
) ON [PRIMARY]
GO


-- ================================================================================================================================
-- TABELA: HistorySizeTables
-- Histórico de tamanho das tabelas por dia
-- ================================================================================================================================
CREATE TABLE Management.[HistorySizeTables]
(
    [IdHistoricoTamanho] [INT] IDENTITY(1, 1) NOT NULL,
    [IdServidor] [SMALLINT] NULL,
    [IdBaseDados] [INT] NULL,
    [IdTabela] [INT] NULL,
    [NmDrive] [CHAR](1) NULL,
    [NrTamanhoTotal] [NUMERIC](9, 2) NULL,
    [NrTamanhoDados] [NUMERIC](9, 2) NULL,
    [NrTamanhoIndice] [NUMERIC](9, 2) NULL,
    [QtLinhas] [BIGINT] NULL,
    [DtReferencia] [DATE] NULL,
    CONSTRAINT [PK_Historico_Tamanho_Tabelas] PRIMARY KEY CLUSTERED
    (
        [IdHistoricoTamanho] ASC
    ) WITH
    (
        PAD_INDEX = OFF,
        STATISTICS_NORECOMPUTE = OFF,
        IGNORE_DUP_KEY = OFF,
        ALLOW_ROW_LOCKS = ON,
        ALLOW_PAGE_LOCKS = ON
    ) ON [PRIMARY]
) ON [PRIMARY]
GO


-- ================================================================================================================================
-- CRIAÇÃO DAS FOREIGN KEYS
-- ================================================================================================================================
ALTER TABLE Management.[HistorySizeTables] WITH CHECK
    ADD CONSTRAINT [FK_Id_BaseDado] FOREIGN KEY ([IdBaseDados])
    REFERENCES Management.[InstanceDatabases] ([IdBaseDados])
GO

ALTER TABLE Management.[HistorySizeTables] CHECK CONSTRAINT [FK_Id_BaseDado]
GO

ALTER TABLE Management.[HistorySizeTables] WITH CHECK
    ADD CONSTRAINT [FK_Id_Servidores] FOREIGN KEY ([IdServidor])
    REFERENCES Management.[InstanceServer] ([IdServidor])
GO

ALTER TABLE Management.[HistorySizeTables] CHECK CONSTRAINT [FK_Id_Servidores]
GO

ALTER TABLE Management.[HistorySizeTables] WITH CHECK
    ADD CONSTRAINT [FK_Id_Tabelas] FOREIGN KEY ([IdTabela])
    REFERENCES Management.[InstanceTables] ([IdTabela])
GO

ALTER TABLE Management.[HistorySizeTables] CHECK CONSTRAINT [FK_Id_Tabelas]
GO


-- ================================================================================================================================
-- VIEW: vw_SizeTables
-- Facilita a visualização consolidada dos dados de tamanho
-- ================================================================================================================================
USE DBA_PerformanceHub
GO

IF OBJECT_ID('Management.vw_SizeTables') IS NOT NULL
    DROP VIEW Management.vw_SizeTables
GO

CREATE VIEW Management.vw_SizeTables
WITH ENCRYPTION
AS
SELECT
    A.DtReferencia
  , B.NmServidor
  , C.NmDatabase
  , D.NmTabela
  , A.NmDrive
  , A.NrTamanhoTotal
  , A.NrTamanhoDados
  , A.NrTamanhoIndice
  , A.QtLinhas
FROM
    Management.HistorySizeTables A
    JOIN Management.InstanceServer B
        ON A.IdServidor = B.IdServidor
    JOIN Management.InstanceDatabases C
        ON A.IdBaseDados = C.IdBaseDados
    JOIN Management.InstanceTables D
        ON A.IdTabela = D.IdTabela
GO


-- ================================================================================================================================
-- PROCEDURE: sp_LoadSizeTables
-- Realiza a coleta e armazenamento diário dos tamanhos das tabelas
-- ================================================================================================================================
USE DBA_PerformanceHub
GO

IF OBJECT_ID('Management.sp_LoadSizeTables') IS NOT NULL
    DROP PROCEDURE Management.sp_LoadSizeTables
GO

CREATE OR ALTER PROCEDURE Management.sp_LoadSizeTables
WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON

    -- Variáveis para controle do loop entre bases de dados
    DECLARE @Databases TABLE
    (
        Id_Database INT IDENTITY(1, 1),
        Nm_Database VARCHAR(120)
    )
    DECLARE @Total INT
          , @i INT
          , @Database VARCHAR(120)
          , @cmd VARCHAR(8000)

    BEGIN TRY
        BEGIN TRANSACTION

            -- Popula lista de bases de dados a serem monitoradas
            INSERT INTO @Databases (Nm_Database)
            SELECT
                name
            FROM
                sys.databases
            WHERE
                name NOT IN ('master', 'model', 'tempdb', 'msdb')
                AND name NOT LIKE '%homolog%'
                AND state_desc = 'online'

            SELECT
                @Total = MAX(Id_Database)
            FROM
                @Databases

            SET @i = 1

            -- Cria tabela temporária global para armazenar dados coletados
            IF OBJECT_ID('tempdb..##Tamanho_Tabelas') IS NOT NULL
                DROP TABLE ##Tamanho_Tabelas

            CREATE TABLE ##Tamanho_Tabelas
            (
                Nm_Servidor VARCHAR(256),
                Nm_Database VARCHAR(256),
                [Nm_Schema] [VARCHAR](8000) NULL,
                [Nm_Tabela] [VARCHAR](8000) NULL,
                [Nm_Index] [VARCHAR](8000) NULL,
                Nm_Drive CHAR(1),
                [Used_in_kb] [INT] NULL,
                [Reserved_in_kb] [INT] NULL,
                [Tbl_Rows] [BIGINT] NULL,
                [Type_Desc] [VARCHAR](20) NULL
            ) ON [PRIMARY]

            -- Loop por cada base de dados
            WHILE (@i <= @Total)
            BEGIN
                -- Verifica se a base ainda existe
                IF EXISTS (SELECT NULL FROM @Databases WHERE Id_Database = @i)
                BEGIN
                    SELECT
                        @Database = Nm_Database
                    FROM
                        @Databases
                    WHERE
                        Id_Database = @i

                    -- Constrói e executa comando dinâmico para coleta na base atual
                    SET @cmd = '
                        INSERT INTO ##Tamanho_Tabelas
                        SELECT
                            @@SERVERNAME
                          , ''' + @Database + ''' AS Nm_Database
                          , t.schema_name
                          , t.table_Name
                          , t.Index_name
                          , (
                                SELECT SUBSTRING(filename, 1, 1)
                                FROM [' + @Database + '].sys.sysfiles
                                WHERE fileid = 1
                            ) AS Nm_Drive
                          , SUM(t.used) AS used_in_kb
                          , SUM(t.reserved) AS Reserved_in_kb
                          , MAX(t.tbl_rows) AS rows
                          , type_Desc
                        FROM
                            (
                                SELECT
                                    s.name AS schema_name
                                  , o.name AS table_Name
                                  , COALESCE(i.name, ''heap'') AS Index_name
                                  , p.used_page_Count * 8 AS used
                                  , p.reserved_page_count * 8 AS reserved
                                  , p.row_count AS ind_rows
                                  , (
                                        CASE
                                            WHEN i.index_id IN (0, 1)
                                            THEN p.row_count
                                            ELSE 0
                                        END
                                    ) AS tbl_rows
                                  , i.type_Desc AS type_Desc
                                FROM
                                    [' + @Database + '].sys.dm_db_partition_stats p
                                    JOIN [' + @Database + '].sys.objects o
                                        ON o.object_id = p.object_id
                                    JOIN [' + @Database + '].sys.schemas s
                                        ON s.schema_id = o.schema_id
                                    LEFT JOIN [' + @Database + '].sys.indexes i
                                        ON i.object_id = p.object_id
                                        AND i.index_id = p.index_id
                                WHERE
                                    o.type_desc = ''user_Table''
                                    AND o.is_Ms_shipped = 0
                            ) AS t
                        GROUP BY
                            t.schema_name
                          , t.table_Name
                          , t.Index_name
                          , type_Desc
                        --with rollup -- no sql server 2005, essa linha deve ser habilitada
                        --order by grouping(t.schema_name),t.schema_name,grouping(t.table_Name),t.table_Name,grouping(t.Index_name),t.Index_name
                        '

                    EXEC(@cmd)
                    --print @cmd; -- para debug
                    --print '
                    --    ##################################################################################
                    --'; -- para debug
                END

                SET @i = @i + 1
            END

            -- Insere novos servidores na tabela de referência
            INSERT INTO Management.InstanceServer (NmServidor)
            SELECT DISTINCT
                A.Nm_Servidor
            FROM
                ##Tamanho_Tabelas A
                LEFT JOIN Management.InstanceServer B
                    ON A.Nm_Servidor = B.NmServidor COLLATE Latin1_General_CI_AS
            WHERE
                B.NmServidor IS NULL

            -- Insere novas bases de dados na tabela de referência
            INSERT INTO Management.InstanceDatabases (NmDatabase)
            SELECT DISTINCT
                A.Nm_Database
            FROM
                ##Tamanho_Tabelas A
                LEFT JOIN Management.InstanceDatabases B
                    ON A.Nm_Database = B.NmDatabase COLLATE Latin1_General_CI_AS
            WHERE
                B.NmDatabase IS NULL

            -- Insere novas tabelas na tabela de referência
            INSERT INTO Management.InstanceTables (NmTabela)
            SELECT DISTINCT
                A.Nm_Tabela
            FROM
                ##Tamanho_Tabelas A
                LEFT JOIN Management.InstanceTables B
                    ON A.Nm_Tabela = B.NmTabela COLLATE Latin1_General_CI_AS
            WHERE
                B.NmTabela IS NULL

            -- Insere os dados de tamanho no histórico
            INSERT INTO Management.HistorySizeTables
            (
                IdServidor
              , IdBaseDados
              , IdTabela
              , NmDrive
              , NrTamanhoTotal
              , NrTamanhoDados
              , NrTamanhoIndice
              , QtLinhas
              , DtReferencia
            )
            SELECT
                B.IdServidor
              , D.IdBaseDados
              , C.IdTabela
              , UPPER(A.Nm_Drive)
              , SUM(Reserved_in_kb) / 1024.00 AS [Reservado (KB)]
              , SUM(
                    CASE
                        WHEN Type_Desc IN ('CLUSTERED', 'HEAP')
                        THEN Reserved_in_kb
                        ELSE 0
                    END
                ) / 1024.00 AS [Dados (KB)]
              , SUM(
                    CASE
                        WHEN Type_Desc IN ('NONCLUSTERED')
                        THEN Reserved_in_kb
                        ELSE 0
                    END
                ) / 1024.00 AS [Indices (KB)]
              , MAX(Tbl_Rows) AS Qtd_Linhas
              , CONVERT(VARCHAR, GETDATE(), 112) AS DtReferencia
            FROM
                ##Tamanho_Tabelas A
                JOIN Management.InstanceServer B
                    ON A.Nm_Servidor = B.NmServidor COLLATE Latin1_General_CI_AS
                JOIN Management.InstanceTables C
                    ON A.Nm_Tabela = C.NmTabela COLLATE Latin1_General_CI_AS
                JOIN Management.InstanceDatabases D
                    ON A.Nm_Database = D.NmDatabase COLLATE Latin1_General_CI_AS
                LEFT JOIN Management.HistorySizeTables E
                    ON B.IdServidor = E.IdServidor
                    AND D.IdBaseDados = E.IdBaseDados
                    AND C.IdTabela = E.IdTabela
                    AND E.DtReferencia = CONVERT(VARCHAR, GETDATE(), 112)
            WHERE
                Nm_Index IS NOT NULL
                AND Type_Desc IS NOT NULL
                AND E.IdHistoricoTamanho IS NULL
            GROUP BY
                B.IdServidor
              , D.IdBaseDados
              , C.IdTabela
              , UPPER(A.Nm_Drive)
              , E.DtReferencia

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION

        -- Envia e-mail com detalhes do erro
        DECLARE @corpoFalha VARCHAR(MAX)
              , @subject VARCHAR(100)
              , @recipients VARCHAR(100)

        SET @subject = 'Falha na execução de Procedure: ' + @@SERVERNAME
        SET @recipients = 'robson@cravil.com.br'
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
                  <td height=20 colspan=7 style="height:20.0pt;text-align:left"><b>Falha na procedure [sp_LoadSizeTables]:<b> <br>
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
END
GO


-- ================================================================================================================================
-- EXECUÇÃO DA CARGA DIÁRIA
-- ================================================================================================================================
-- Carga diária para saber qual tamanho atual (Mb)
EXECUTE Management.sp_LoadSizeTables

-- ================================================================================================================================
-- CONSULTAS DE ANÁLISE
-- ================================================================================================================================

-- --------------------------------------------------------------------------------------------------------------------------------
-- Visualização diária com a View
-- --------------------------------------------------------------------------------------------------------------------------------
SELECT TOP 30
    v.DtReferencia
  , v.NmDatabase
  , v.NmDrive
  , v.NmServidor
  , v.NmTabela
  , (CAST(v.NrTamanhoDados AS VARCHAR) + ' Mb') + ' -> ' + (CAST((v.NrTamanhoDados / 1024) AS VARCHAR) + ' Gb') AS TotalDados
  , v.NrTamanhoIndice
  , v.NrTamanhoTotal
  , v.QtLinhas
FROM
    Management.vw_SizeTables AS v
ORDER BY
    NrTamanhoTotal DESC

-- --------------------------------------------------------------------------------------------------------------------------------
-- Outra forma de tratar a collation
-- --------------------------------------------------------------------------------------------------------------------------------
/*
SELECT ID
FROM ItemsTable
INNER JOIN AccountsTable
WHERE ItemsTable.Collation1Col COLLATE DATABASE_DEFAULT
= AccountsTable.Collation2Col COLLATE DATABASE_DEFAULT
*/

-- ================================================================================================================================
-- VIEW PARA ANÁLISE DE CRESCIMENTO EM BASES ESPECÍFICAS
-- ================================================================================================================================
-- Usada para análise de crescimento de tabelas em toda a instância.
USE DBA_PerformanceHub
GO

IF OBJECT_ID('Management.vw_SizeTables') IS NOT NULL
    DROP VIEW Management.vw_SizeTables
GO

CREATE VIEW Management.vw_SizeTables
WITH ENCRYPTION
AS
SELECT
    A.DtReferencia
  , B.NmServidor
  , C.NmDatabase
  , D.NmTabela
  , A.NmDrive
  , A.NrTamanhoTotal
  , A.NrTamanhoDados
  , A.NrTamanhoIndice
  , A.QtLinhas
FROM
    Management.HistorySizeTables A
    JOIN Management.InstanceServer B
        ON A.IdServidor = B.IdServidor
    JOIN Management.InstanceDatabases C
        ON A.IdBaseDados = C.IdBaseDados
    JOIN Management.InstanceTables D
        ON A.IdTabela = D.IdTabela
GO


-- ================================================================================================================================
-- CRESCIMENTO DIA A DIA DAS TABELAS (TOP 100)
-- ================================================================================================================================
USE YOUR_DATABASE
GO

SELECT TOP 100
    B2.NmServidor
  , A2.NmDrive
  , C2.NmDatabase
  , D2.NmTabela
  , (SELECT Management.fn_FormatIntToMoney(A2.NrTamanhoDados / 1024)) AS TamDadosAtual_Gb
  , (SELECT Management.fn_FormatIntToMoney(A2.NrTamanhoTotal / 1024)) AS TamAlocado_Gb
  , (SELECT Management.fn_FormatIntToMoney(A2.NrTamanhoIndice)) AS NrTamanhoIndice_Mb
  , (A2.NrTamanhoDados - A.NrTamanhoDados) AS DifTamDados_Mb
  , CONVERT(VARCHAR(20), A2.DtReferencia, 3) AS DataAtual
  , (SELECT Management.fn_FormatIntToThousands(A2.QtLinhas, 2)) AS Qt_LinhasAtual
  , (SELECT Management.fn_FormatIntToThousands(A.QtLinhas, 2)) AS Qt_LinhasDiaAnterior
  , CONVERT(VARCHAR(20), A.DtReferencia, 3) AS DataAnterior
FROM
    Management.HistorySizeTables AS A
    INNER JOIN Management.InstanceServer AS B
        ON A.IdServidor = B.IdServidor
    INNER JOIN Management.InstanceDatabases AS C
        ON A.IdBaseDados = C.IdBaseDados
    INNER JOIN Management.InstanceTables AS D
        ON A.IdTabela = D.IdTabela
    INNER JOIN Management.HistorySizeTables AS A2
        ON A2.IdServidor = A.IdServidor
        AND A2.IdBaseDados = A.IdBaseDados
        AND A2.IdTabela = A.IdTabela
    INNER JOIN Management.InstanceServer AS B2
        ON A2.IdServidor = B2.IdServidor
    INNER JOIN Management.InstanceDatabases AS C2
        ON A2.IdBaseDados = C2.IdBaseDados
    INNER JOIN Management.InstanceTables AS D2
        ON A2.IdTabela = D2.IdTabela
WHERE
    A2.DtReferencia = CAST(GETDATE() AS DATE)       -- DADOS ATUAIS
    AND A.DtReferencia = CAST(GETDATE() - 1 AS DATE) -- DADOS ANTERIORES
    AND C2.NmDatabase = 'YOUR_DATABASE'
    AND C.NmDatabase = 'YOUR_DATABASE'
ORDER BY
    A2.NrTamanhoDados DESC


-- ================================================================================================================================
-- ESPAÇO USADO EM DISCO (SEM LOGS E SEM ESPAÇO ALOCADO)
-- ================================================================================================================================
USE YOUR_DATABASE
GO

DECLARE @dateOld DATE = '2018-03-28'
      , @dateCurrent DATE = (CAST(GETDATE() AS DATE)) -- Último dia rodado pela Job
      , @database VARCHAR(20) = 'YOUR_DATABASE'

SELECT
    CONVERT(VARCHAR, x.DATE_OLD, 103) AS DATE_OLD
  , (CAST(x.SIZE_OLD AS VARCHAR) + ' Mb' + ' -> '
    + CAST(CAST(x.SIZE_OLD / 1024 AS DECIMAL(15, 2)) AS VARCHAR) + ' Gb') AS SIZE_OLD
  , CONVERT(VARCHAR, @dateCurrent, 103) AS DATE_CURRENT
  , (CAST(x.SIZE_CURRENT AS VARCHAR) + ' Mb' + ' -> '
    + CAST(CAST(x.SIZE_CURRENT / 1024 AS DECIMAL(15, 2)) AS VARCHAR) + ' Gb') AS SIZE_CURRENT
  , (CAST((x.SIZE_CURRENT - x.SIZE_OLD) AS VARCHAR) + ' Mb' + ' -> '
    + CAST(CAST((x.SIZE_CURRENT - x.SIZE_OLD) / 1024 AS DECIMAL(15, 2)) AS VARCHAR) + ' Gb') AS CRESCIMENTO
  , DATEDIFF(DAY, @dateOld, @dateCurrent) AS DIF_DAYS
FROM
    (
        SELECT
            v2.DtReferencia AS DATE_OLD
          , SUM(v2.NrTamanhoTotal) AS SIZE_OLD
          , (
                SELECT
                    SUM(v.NrTamanhoTotal)
                FROM
                    Management.vw_SizeTables AS v
                WHERE
                    v.DtReferencia = @dateCurrent
                    AND v.NmDatabase = @database
            ) AS SIZE_CURRENT
        FROM
            Management.vw_SizeTables v2
        WHERE
            v2.DtReferencia = @dateOld
            AND v2.NmDatabase = @database
        GROUP BY
            v2.DtReferencia
    ) AS x


-- ================================================================================================================================
-- TOTALIZAÇÃO POR SEMANA
-- ================================================================================================================================
DECLARE @decremento SMALLINT
      , @limite SMALLINT
      , @dia DATETIME

IF OBJECT_ID('tempdb.dbo.##semanas') IS NOT NULL
    DROP TABLE ##semanas

CREATE TABLE ##semanas
(
    DatabaseName VARCHAR(50),
    DataReferencia DATE,
    TotalSize_Gb VARCHAR(20)
)

SET @limite = (SELECT DATEDIFF(WEEK, '2016-05-02', GETDATE()) * -1) -- a data setada é a primeira registrada na rotina de coleta
SET @decremento = -1

WHILE (@limite <= @decremento)
BEGIN
    SET @dia = (SELECT DATEADD(WEEK, @decremento, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)))

    INSERT INTO ##semanas
    SELECT
        v.NmDatabase
      , v.DtReferencia
      , REPLACE(CAST(CAST(SUM(v.NrTamanhoTotal / 1024) AS MONEY) AS VARCHAR(20)), '.', ',')
    FROM
        DBA_PerformanceHub.Management.vw_SizeTables AS v
    WHERE
        v.DtReferencia = @dia
    GROUP BY
        v.NmDatabase
      , v.DtReferencia

    SET @decremento = @decremento - 1
END

SELECT
    s.DatabaseName
  , CONVERT(VARCHAR(12), s.DataReferencia, 103) AS DateReference
  , s.TotalSize_Gb
FROM
    ##semanas AS s
ORDER BY
    s.DataReferencia

IF OBJECT_ID('temdb.dbo.##semanas') IS NOT NULL
    DROP TABLE ##semanas


-- ================================================================================================================================
-- LINHA DE TENDÊNCIA - AUMENTO SEMANAL DAS BASES DE DADOS
-- ================================================================================================================================
DECLARE @decremento SMALLINT
      , @limite SMALLINT
      , @dia DATETIME

IF OBJECT_ID('tempdb.dbo.##semanas') IS NOT NULL
    DROP TABLE ##semanas

CREATE TABLE ##semanas
(
    DatabaseName VARCHAR(80),
    DataReferencia DATE,
    TotalSize_Gb VARCHAR(30)
)

SET @limite = (SELECT DATEDIFF(WEEK, '2017-01-02', GETDATE()) * -1) -- a data setada é a primeira registrada na rotina de coleta
SET @decremento = 1

WHILE (@limite <= @decremento)
BEGIN
    SET @dia = (SELECT DATEADD(WEEK, @decremento, CAST(FLOOR(CAST(GETDATE() AS FLOAT)) AS DATETIME)))

    INSERT INTO ##semanas
    SELECT
        v.NmDatabase
      , v.DtReferencia
      , REPLACE(CAST(CAST(SUM(v.NrTamanhoTotal / 1024) AS MONEY) AS VARCHAR(20)), '.', ',') AS Tamanho
    FROM
        YOUR_DATABASE.Management.vw_SizeTables AS v
    WHERE
        v.DtReferencia = @dia
    GROUP BY
        v.NmDatabase
      , v.DtReferencia

    SET @decremento = @decremento - 1
END

SELECT
    s.DatabaseName
  , CONVERT(VARCHAR(12), s.DataReferencia, 103) AS DateReference
  , s.TotalSize_Gb
FROM
    ##semanas AS s
ORDER BY
    s.DataReferencia

IF OBJECT_ID('temdb.dbo.##semanas') IS NOT NULL
    DROP TABLE ##semanas


-- ================================================================================================================================
-- CONSULTA PARA POWER BI - DADOS DE ATÉ UM ANO
-- ================================================================================================================================
-- Para o PowerBI não será necessário colocar limites de data já que terá controle de massa de dados em uma Job
-- no caso dessas coletas serão preservados os dados de no máximo um ano.
SELECT
    v.NmDatabase AS [Nome Database]
  , v.DtReferencia AS [Data de Referência]
  , CAST(SUM(v.NrTamanhoTotal / 1024) AS DECIMAL(9, 2)) AS Tamanho_Gb
FROM
    YOUR_DATABASE.Management.vw_SizeTables AS v
GROUP BY
    v.NmDatabase
  , v.DtReferencia
