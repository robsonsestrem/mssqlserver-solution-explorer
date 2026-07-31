/*
 *
	OBJETIVO: Exportação de XMLs de NF-e armazenados em campos VARBINARY/XML do banco
			  para arquivos em disco, utilizando procedure sp_Escreve_Arquivo_FSO
			  via OLE Automation (sp_OACreate).
	PROJETO: mssqlserver-solution-explorer
	
	REFERÊNCIAS DE URL:
 *	https://learn.microsoft.com/pt-br/sql/relational-databases/system-stored-procedures/sp-oacreate-transact-sql?view=sql-server-ver17
 */
-- ============================================================
-- Exportação de XMLs de NF-e via OLE Automation
-- ============================================================

USE YOUR_DATABASE
GO

-- ============================================================
-- SEÇÃO 1: EXTRAÇÃO
-- Carrega XMLs em tabela temporária global
-- ============================================================

-- Extrai os XMLs convertidos para VARCHAR(MAX) e gera numeração sequencial
SELECT 
    t2.NfArqXMLFileName
    ,CAST(CAST(t2.NFArqXML AS XML) AS VARCHAR(MAX)) AS [xml]
    ,ROW_NUMBER() OVER (ORDER BY t1.NF) AS contador
INTO ##tempxml
FROM YOUR_DATABASE.dbo.vw_MovimentacaoReceita AS t1
INNER JOIN MOVESTOQUEARQUIVOS AS t2 WITH (NOLOCK)
    ON t1.filial = t2.NfFilCod
    AND t1.emissao = t2.NfDatEmis
    AND t1.numcontrole = t2.NfNumero
WHERE t1.item IN (42312, 42311, 54756, 54755)
    AND t1.Emissao BETWEEN '20180401' AND '20181128'

-- ============================================================
-- SEÇÃO 2: DEDUPLICAÇÃO
-- Remove XMLs duplicados via CTE
-- ============================================================

-- Valida e retira registros duplicados antes da exportação
WITH cte AS
(
    SELECT DISTINCT
        t.NfArqXMLFileName
        ,t.xml
    FROM ##tempxml AS t
)
SELECT 
    c.NfArqXMLFileName
    ,c.xml
    ,ROW_NUMBER() OVER (ORDER BY c.NfArqXMLFileName) AS contador
INTO ##xmldistinto
FROM cte AS c

-- Inspeciona o resultado deduplicado antes de exportar
SELECT * FROM ##xmldistinto AS x

/*
CONSULTA AUXILIAR — Identificação de duplicatas (descomente se necessário):
WITH repete AS
(
    SELECT 
        t.NF
        ,ROW_NUMBER() OVER (PARTITION BY t.NF ORDER BY t.NF) AS contador
    FROM ##tempxml AS t
)
SELECT ',' + CAST(r.NF AS VARCHAR(50))
FROM repete AS r
WHERE r.contador > 1
*/

-- ============================================================
-- SEÇÃO 3: EXPORTAÇÃO EM LOTE
-- Gera de 255 em 255 arquivos por limitação da solução
-- ============================================================

-- Declaração de variáveis de controle do loop de exportação
DECLARE @nomeArquivo VARCHAR(MAX)
DECLARE @stringValor VARCHAR(MAX)
DECLARE @contador INT = 766

-- Itera sobre o intervalo definido e exporta cada XML para disco
WHILE (@contador < 786)
BEGIN
    -- Obtém o conteúdo XML do registro atual
    SET @stringValor = 
    (
        SELECT t.[xml]
        FROM ##xmldistinto AS t
        WHERE t.contador = @contador
    )

    -- Monta o caminho completo do arquivo de destino
    SET @nomeArquivo = 
        'C:\Temp\' + 
        (
            SELECT t.NfArqXMLFileName
            FROM ##xmldistinto AS t
            WHERE t.contador = @contador
        ) + '.xml'

    -- Chama a procedure de escrita via OLE Automation
    EXEC YOUR_DATABASE.Management.[sp_Escreve_Arquivo_FSO]
        @String = @stringValor
        ,@Ds_Arquivo = @nomeArquivo

    SET @contador = @contador + 1
END

-- ============================================================
-- SEÇÃO 4: EXPORTAÇÃO INDIVIDUAL
-- Gera arquivo por NF específica
-- ============================================================

/*
Descomente para exportar um XML específico pelo número da NF:

DECLARE @nomeArquivo VARCHAR(MAX)
DECLARE @stringValor VARCHAR(MAX)

SET @stringValor = 
(
    SELECT t.[xml]
    FROM ##tempxml AS t
    WHERE t.NF = 61893
)

SET @nomeArquivo = 
    'C:\Temp\' + 
    (
        SELECT CAST(t.NF AS VARCHAR(20))
        FROM ##tempxml AS t
        WHERE t.NF = 61893
    ) + '.xml'

EXEC YOUR_DATABASE.Management.[sp_Escreve_Arquivo_FSO]
    @String = @stringValor
    ,@Ds_Arquivo = @nomeArquivo
*/
