/*
 *
    OBJETIVO: Scripts de controle e monitoramento de conexões ativas no SQL Server:
              visualização de conexões abertas por banco de dados, contagem de
              sessões por usuário e alternância entre modos Single_User e Multi_User.
    PROJETO: mssqlserver-solution-explorer
 *  
 */
-- ============================================================
-- Controle e Monitoramento de Conexões
-- ============================================================

-- Exibe todas as conexões abertas para o banco de dados de homologação
SELECT
    *
FROM
    master.dbo.sysprocesses
WHERE
    dbid = DB_ID('YOUR_DATABASE_homolog')

-- Conta o número de conexões agrupadas por banco de dados e login do usuário
SELECT
      DB_NAME(dbid) AS Banco_de_Dados
    , COUNT(dbid) AS Qtd_Conexoes
FROM
    sys.sysprocesses
WHERE
    -- dbid > 50
    DB_NAME(dbid) = 'YOUR_DATABASE_homolog'
GROUP BY
      dbid
    , loginame -- agrupado por número de sessões abertas por usuário

/*************************************************************************************************************/

-- Coloca o banco de dados em modo Single_User com encerramento imediato de conexões ativas
ALTER DATABASE YOUR_DATABASE
SET SINGLE_USER WITH ROLLBACK IMMEDIATE

-- Retorna o banco de dados para modo Multi_User
ALTER DATABASE YOUR_DATABASE
SET MULTI_USER WITH ROLLBACK IMMEDIATE
