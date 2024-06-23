-----------------------------------------------------------------------------------------------------------------------------------------------
-- Referências -> https://www.dirceuresende.com/blog/mapeando-dependencias-entre-objetos-sql-server/
-- Essa procedure lista todas as dependências diretas de um objeto, de modo cross-database
-- EXEMPLO DE USO
use Maintenance
go
EXEC Management.sp_VerifyDirectDependencies 'GesCooper90.dbo.TRANSACIONADORES'
EXEC Management.sp_VerifyDirectDependencies 'GesCooper90.dbo.tr_Transacionadores_LogUD'
EXEC Management.sp_VerifyDirectDependencies 'IntegraTICravil.Management.DDLTransaction'
-----------------------------------------------------------------------------------------------------------------------------------------------


-----------------------------------------------------------------------------------------------------------------------------------------------
-- Referências -> https://www.dirceuresende.com/blog/mapeando-dependencias-entre-objetos-sql-server/
-- Procedure Cross-database e multi-nível
-- Com a procedure abaixo, que utiliza CTE e recursividade, é possível listar todos os 
-- objetos dependentes com vários níveis de hierarquia no banco de origem e as 
-- dependências diretas (1º nível) e cross-database.
-- EXEMPLO DE USO
use Maintenance
go
EXEC Management.sp_VerifyDependenciesFull 'IntegraTICravil.LogErp.TransacionadorLogDML'	-- mostra a trigger que alimenta
EXEC Management.sp_VerifyDependenciesFull 'GesCooper90.dbo.TRANSACIONADORES'
EXEC Management.sp_VerifyDependenciesFull 'GesCooper90.dbo.FILIAIS'						-- mostra a trigger e outros
EXEC Management.sp_VerifyDependenciesFull 'IntegraTICravil.Management.DDLTransaction'
-----------------------------------------------------------------------------------------------------------------------------------------------


----------------------------------------------------------------------------------------------------------
-- Relatório completo de dependências
-- A query abaixo vai mostrar uma linha para cada objeto do database que possua dependências, 
-- com os objetos dependentes separados por vírgula.
----------------------------------------------------------------------------------------------------------
USE GesCooper90
GO
SELECT
    DB_NAME() AS dbname,
    o.type_desc AS referenced_object_type,
    d1.referenced_entity_name,
    d1.referenced_id,
    STUFF((
            SELECT
                ', ' + OBJECT_NAME(d2.referencing_id)
            FROM
                sys.sql_expression_dependencies d2
            WHERE
                d2.referenced_id = d1.referenced_id
            ORDER BY
                OBJECT_NAME(d2.referencing_id)
            FOR XML PATH('')
          ), 1, 1, '') AS dependent_objects_list
FROM
    sys.sql_expression_dependencies d1
    JOIN sys.objects o ON d1.referenced_id = o.[object_id]
GROUP BY
    o.type_desc,
    d1.referenced_id,
    d1.referenced_entity_name
ORDER BY
    o.type_desc,
    d1.referenced_entity_name


-----------------------------------------------------------------------------------------------------------------------------------------------
-- Referência -> https://www.dirceuresende.com/blog/mapeando-dependencias-entre-objetos-sql-server/
-- Dependências de schema-bound
-- Com a query abaixo, é possível identificar a mapear as dependências do tipo schema-bound, 
-- como views indexadas (criadas com o hint SCHEMABINDING), colunas calculadas e check constraints:
-----------------------------------------------------------------------------------------------------------------------------------------------
use GesCooper90
go
SELECT
    OBJECT_NAME(d.referencing_id) AS referencing_name,
    o.type_desc referencing_object_type,
    d.referencing_minor_id AS referencing_column_id,
    cc2.name AS referencing_column_name,
    d.referenced_entity_name,
    d.referenced_minor_id AS referenced_column_id,
    cc.name AS referenced_column_name
FROM
    sys.sql_expression_dependencies d
    JOIN sys.all_columns cc ON d.referenced_minor_id = cc.column_id AND d.referenced_id = cc.[object_id]
    JOIN sys.objects o ON d.referencing_id = o.[object_id]
    LEFT JOIN sys.all_columns cc2 ON d.referencing_minor_id = cc2.column_id AND d.referencing_id = cc2.[object_id]
WHERE
    d.is_schema_bound_reference = 1
    AND d.referencing_minor_id > 0


----------------------------------------------------------------------------------------------------------
-- Mostrando dependências em vários níveis
-- Com a query abaixo é possível listar as dependências em vários níveis hierárquicos, 
-- da mesma forma que a interface do SQL Server Management Studio nos mostra:
----------------------------------------------------------------------------------------------------------
use GesCooper90
go
WITH Arvore_Dependencias ( referenced_id, referenced_name, referencing_id, referencing_name, NestLevel )
AS (
    SELECT
        A.[object_id] AS referenced_id,
        A.name AS referenced_name,
        A.[object_id] AS referencing_id,
        A.name AS referencing_name,
        0 AS NestLevel
   FROM
        sys.objects A
   WHERE
        A.name = 'TRANSACIONADORES'		--**********************coloque o objeto aqui
   
   UNION ALL
   
   SELECT
        A.referenced_id,
        OBJECT_NAME(A.referenced_id),
        A.referencing_id,
        OBJECT_NAME(A.referencing_id),
        NestLevel + 1
   FROM
        sys.sql_expression_dependencies		A
        JOIN Arvore_Dependencias		B	ON A.referenced_id = B.referencing_id
)
SELECT DISTINCT
    referenced_id,
    referenced_name,
    referencing_id,
    referencing_name,
    NestLevel
FROM
    Arvore_Dependencias
WHERE
    NestLevel > 0
ORDER BY
    NestLevel,
    referencing_id


----------------------------------------------------------------------------------------------------------
-- Encontrando dependências por tipo de dado
-- Como você deve saber, os tipos de dados TEXT, NTEXT e IMAGE serão descontinuados e não mais 
-- suportados em futuras versões do SQL Server. Se você planeja realizar o upgrade da sua aplicação e 
-- substituir esses tipos, a query abaixo pode ser um bom ponto de partida. A query abaixo vai 
-- mostrar todos os objetos que utilizam esses tipos de dados e suas dependências:
----------------------------------------------------------------------------------------------------------
use rhcravil
go
WITH Arvore_Dependencias
AS (
    SELECT DISTINCT
        A.name,
        A.[object_id] AS referenced_id,
        A.name AS referenced_name,
        A.[object_id] AS referencing_id,
        A.name AS referencing_name,
        0 AS NestLevel
    FROM
        sys.objects						A
        JOIN sys.columns					B	ON	A.[object_id] = B.[object_id]
    WHERE
        A.is_ms_shipped = 0 
        AND B.system_type_id IN ( 34, 99, 35 ) --<<<<<<< TEXT, NTEXT e IMAGE - Id do tipo da coluna, coloque aqui
    
    UNION ALL
    
    SELECT
        B.name,
        A.referenced_id,
        OBJECT_NAME(A.referenced_id),
        A.referencing_id,
        OBJECT_NAME(A.referencing_id),
        NestLevel + 1
    FROM
        sys.sql_expression_dependencies		A
        JOIN Arvore_Dependencias		B	ON	A.referenced_id = B.referencing_id
 )
SELECT
    name AS parent_object_name,
    referenced_id,
    referenced_name,
    referencing_id,
    referencing_name,
    NestLevel
FROM
    Arvore_Dependencias t1
WHERE
    NestLevel > 0
ORDER BY
    name,
    NestLevel


----------------------------------------------------------------------------------------------------------------------------------
--Read more: http://www.linhadecodigo.com.br/artigo/3018/como-encontrar-objetos-no-sql-server.aspx#ixzz4kfKBWpyi
----------------------------------------------------------------------------------------------------------------------------------
use CooperSystem
go
SET NOCOUNT ON

/* MOSTRAR TODAS TABELAS DO SCHEMA VENDAS [SALES] */ 
print('*********************************************************') 
print('MOSTRAR TODAS TABELAS DO SCHEMA VENDAS [SALES]')
SELECT T.NAME 'TABELAS' 
FROM sys.tables T 
INNER JOIN sys.schemas S 
ON T.schema_id = S.schema_id 
WHERE S.name = 'dbo' 
DECLARE @TABELA VARCHAR(50) 
SET @TABELA = '%ProdutorERP%'

/* RELACIONAMENTOS DE 1 NIVEL DA TABELA */ 
print('*********************************************************') 
print('RELACIONAMENTOS DE 1 NIVEL DA TABELA')
SELECT PK.TABLE_NAME 'PAI', 
FK.TABLE_NAME 'FILHO' 
FROM INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C 
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS PK 
ON C.CONSTRAINT_NAME = PK.CONSTRAINT_NAME 
INNER JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK 
ON C.UNIQUE_CONSTRAINT_NAME = FK.CONSTRAINT_NAME 
WHERE FK.TABLE_NAME = REPLACE(@TABELA,'%','') 
OR PK.TABLE_NAME = REPLACE(@TABELA,'%','')
/* TODOS OS OBJETOS DA TABELA */ 

print('*********************************************************') 
print('TODOS OS OBJETOS DA TABELA')
SELECT O.NAME 'NOME', 
REPLACE(O.type_desc,'_',' ') 'TIPO' 
FROM SYS.OBJECTS O 
INNER JOIN SYSCOMMENTS C 
ON O.object_id = C.ID 
WHERE C.TEXT LIKE @TABELA
/* TODAS AS CONSTRAINTS DA TABELA */ 

print('*********************************************************') 
print('TODAS AS CONSTRAINTS DA TABELA')
SELECT O2.NAME 'TABELA', 
CL.NAME 'COLUNA', 
O.NAME 'CONSTRAINT', 
COM.TEXT 'CONDIÇÃO' 
FROM SYSCONSTRAINTS C 
INNER JOIN SYSOBJECTS O 
ON O.ID = C.CONSTID 
INNER JOIN SYSOBJECTS O2 
ON O2.ID = C.ID 
INNER JOIN SYSCOLUMNS CL 
ON CL.ID = O2.ID 
AND CL.COLID = C.COLID 
INNER JOIN SYSCOMMENTS COM 
ON O.ID = COM.ID 
WHERE O2.NAME LIKE REPLACE(@TABELA,'%','') 
AND O2.XTYPE = 'U' 
ORDER BY O2.NAME, CL.NAME, O.NAME
SET NOCOUNT OFF









