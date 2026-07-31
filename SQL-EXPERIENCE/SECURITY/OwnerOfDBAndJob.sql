/*
 *
    OBJETIVO: Scripts de auditoria de propriedade de objetos no SQL Server:
              lista de proprietários de bancos de dados (sys.databases) e
              lista de proprietários de jobs do SQL Server Agent (msdb.dbo.sysjobs).
              Utilizado para identificar owners que não seguem boas práticas.
    PROJETO: mssqlserver-solution-explorer

    REFERÊNCIAS DE URL:
 *  https://www.mssqltips.com/sql-server-video/952/dba-best-practices-how-to-be-a-smarter-dba/
 */
-- ============================================================
-- Auditoria de Proprietários de Bancos de Dados e Jobs
-- ============================================================

-- Lista os proprietários de todos os bancos de dados da instância
-- para identificar owners que não seguem boas práticas de segurança
SELECT
      d.[name] AS DBName
    , sp.[name] AS OwnerOfDB
FROM
    sys.databases AS d
    INNER JOIN sys.server_principals AS sp
        ON d.owner_sid = sp.sid;

-- Lista os proprietários de todos os jobs do SQL Server Agent
-- para identificar owners que não seguem boas práticas de segurança
-- OBS: Se um job pertencer a um usuário do Windows que não existe mais,
-- o job não iniciará.
SELECT
      sj.[name] AS DBName
    , sp.[name] AS OwnerOfDB
FROM
    msdb.dbo.sysjobs AS sj
    INNER JOIN sys.server_principals AS sp
        ON sj.owner_sid = sp.sid;
