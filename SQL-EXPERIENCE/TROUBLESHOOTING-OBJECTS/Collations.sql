/*
 *
	OBJETIVO: Scripts de consulta e manipulação de Collations no SQL Server,
			  incluindo verificação de collation do servidor, banco de dados
			  e colunas, alteração de collation de database e tabelas, e
			  rotinas de carga com tratamento de collations diferentes entre
			  bases (uso de COLLATE em JOINs e CTEs).
	PROJETO: mssqlserver-solution-explorer
 *
 */
-- ============================================================
-- Verificação de Collations
-- ============================================================

-- Collation do servidor
EXEC sp_helpsort

-- Collation do banco de dados
SELECT DATABASEPROPERTYEX('INTEGRATICRAVIL', 'Collation')

-- Collation das colunas de uma tabela específica
USE IntegraTICravil
GO

SELECT
    TABLE_NAME
    , COLUMN_NAME
    , COLLATION_NAME
FROM IntegraTICravil.INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DevedoresSigaCred_01'


-- ============================================================
-- Alteração de Collation
-- ============================================================
-- Alterar collation de uma Database
-- Necessário dropar algumas constraints e recriar depois
ALTER DATABASE IntegraTICravil COLLATE SQL_Latin1_General_CP1_CI_AS

USE IntegraTICravil
GO

-- Alterar collation de uma coluna específica
ALTER TABLE Trace ALTER COLUMN TextData VARCHAR(max) COLLATE SQL_Latin1_General_CP1_CI_AS


-- ============================================================
-- Ajuste de Collation em JOINs entre tabelas de bases diferentes
-- ============================================================
-- Relacionamento de tabelas com collations diferentes
-- (usado na rotina de carga de tamanho de tabelas)
INSERT INTO Management.InstanceServer (NmServidor)
SELECT DISTINCT
    A.Nm_Servidor
FROM ##Tamanho_Tabelas AS A
LEFT JOIN Management.InstanceServer AS B
    ON A.Nm_Servidor = B.NmServidor COLLATE Latin1_General_CI_AS
WHERE B.NmServidor IS NULL


-- ============================================================
-- Carga de produtores com validação de CPF/CNPJ
-- ============================================================
-- Exemplo prático de carga com bases de diferentes Collations.
-- Tudo na base CooperSystem usa a Collation igual à do Server.
;WITH validar AS
(
    SELECT
        t.TraCod
        , t.TraNatJuridica
        , t.TraNom
        , ISNULL(t.TraNomFantasia, '') AS NomeFantasia
        , t.TraCpf
        , ISNULL(t.TraRg, '') AS Rg
        , ISNULL(t.TraCnpj, '') AS CNPJ
        , CASE
            WHEN (SELECT IntegraTICravil.Management.fn_ValidCPF_CNPJ(t.TraCnpj)) COLLATE Latin1_General_CI_AS = 'TRUE'
                AND (SELECT IntegraTICravil.Management.fn_ValidCPF_CNPJ(t.TraCpf)) COLLATE Latin1_General_CI_AS = 'TRUE' THEN
                'F'
            WHEN (SELECT IntegraTICravil.Management.fn_ValidCPF_CNPJ(t.TraCpf)) COLLATE Latin1_General_CI_AS = 'FALSE'
                AND (SELECT IntegraTICravil.Management.fn_ValidCPF_CNPJ(t.TraCnpj)) COLLATE Latin1_General_CI_AS = 'FALSE' THEN
                'F'
            ELSE
                'V'
          END AS Validado
        , t.TraInscEstadual
        , t.TraNumInscProdutor
        , t.TraDatEmissao
        , t.TraSit
        , t.TraMunCod
        , t.TraEstCod
        , t.TraPaiCod
        , ISNULL(t.TraBairro, '') AS Bairro
        , ISNULL(t.TraEnd, '') AS Logradouro
        , ISNULL(t.TraNumEnd, '') AS Numero
        , ISNULL(t.TraComplemento, '') AS Complemento
        , ISNULL(t.TraCep, '') AS CEP
        , t.TraEmail
        , t.TraCelular
        , t.TraFone
    FROM GesCooper90.dbo.TRANSACIONADORES AS t WITH(NOLOCK)
    WHERE t.TraSit = 1                              -- Ativo
        AND t.TraNatComercial = 1                   -- Produtor
        AND t.TraNumInscProdutor LIKE '%[0-9]%'     -- Só números, sem espaços ou caracteres especiais
        AND t.TraNumInscProdutor NOT IN ('0')       -- Nega quando é só zero
        AND t.TraNumInscProdutor NOT LIKE '%[A-Z]%' -- Nega letras
        AND t.TraCod NOT IN (
            SELECT
                t2.TraCod
            FROM GesCooper90.dbo.TRANSACIONADORES AS t2 WITH(NOLOCK)
            WHERE t2.TraSit = 1                     -- Ativo
                AND (
                    SUBSTRING(t.TraNumInscProdutor, 1, 1) = 0
                    AND SUBSTRING(t.TraNumInscProdutor, 2, 1) = 0
                )                                   -- Nega códigos com mais de 2 zeros no começo
        )
)
INSERT INTO CooperSystem.dbo.Produtor (Matricula, Nome)
SELECT
    d.TraCod
    , d.TraNom
FROM validar AS d
WHERE d.Validado = 'V'
