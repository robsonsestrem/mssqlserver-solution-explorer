/*
    OBJETIVO: Exporta XMLs de NF-e armazenados em campos VARBINARY/XML do banco
              para arquivos em disco, utilizando a procedure sp_Escreve_Arquivo_FSO
              via OLE Automation. Ticket: 19107.
    PROJETO: mssqlserver-solution-explorer
*/

USE YOUR_DATABASE;
GO

-- ============================================================
-- SEÇÃO 1: EXTRAÇÃO — Carrega XMLs em tabela temporária global
-- ============================================================

-- Extrai os XMLs convertidos para VARCHAR(MAX) e gera numeração sequencial
SELECT
     t2.NfArqXMLFileName
    ,CAST(CAST(t2.NFArqXML AS XML) AS VARCHAR(MAX)) AS [xml]
    ,ROW_NUMBER() OVER (ORDER BY t1.NF)             AS contador
INTO ##tempxml
FROM YOUR_DATABASE.dbo.vw_MovimentacaoReceita AS t1
INNER JOIN MOVESTOQUEARQUIVOS AS t2 WITH (NOLOCK)
    ON  t1.filial      = t2.NfFilCod
    AND t1.emissao     = t2.NfDatEmis
    AND t1.numcontrole = t2.NfNumero
WHERE t1.item IN (42312, 42311, 54756, 54755)
    AND t1.Emissao BETWEEN '20180401' AND '20181128';

DROP TABLE ##tempxml;


-- ============================================================
-- SEÇÃO 2: DEDUPLICAÇÃO — Remove XMLs duplicados via CTE
-- ============================================================

-- Deve-se validar e retirar registros duplicados antes da exportação
-- (coletados apenas os repetidos que geraram 31 e foram renomeados)
;WITH cte AS (
    SELECT DISTINCT
         t.NfArqXMLFileName
        ,t.xml
    FROM ##tempxml AS t
)
SELECT
     *
    ,ROW_NUMBER() OVER (ORDER BY c.NfArqXMLFileName) AS contador
INTO ##xmldistinto
FROM cte AS c;

-- Inspeciona o resultado deduplicado antes de exportar
SELECT * FROM ##xmldistinto AS x;

DROP TABLE ##xmldistinto;

/*
    CONSULTA AUXILIAR — Identificação de duplicatas (descomente se necessário):

    ;WITH repete AS (
        SELECT
             t.NF
            ,ROW_NUMBER() OVER (PARTITION BY t.NF ORDER BY t.NF) AS contador
        FROM ##tempxml AS t
    )
    SELECT ',' + CAST(r.NF AS VARCHAR(50))
    FROM repete AS r
    WHERE r.contador > 1;
*/


-- ============================================================
-- SEÇÃO 3:
-- OBS.: Gerar de 255 em 255 arquivos por limitação da solução
-- ============================================================

-- Declara variáveis de controle do loop de exportação em lote
DECLARE
	 @nomeArquivo VARCHAR(MAX)
	,@stringValor VARCHAR(MAX)
	,@contador    INT = 766;

-- Itera sobre o intervalo definido e exporta cada XML para disco
WHILE (@contador < 786)
BEGIN

	-- Obtém o conteúdo XML do registro atual
	SET @stringValor = (
		SELECT t.[xml]
		FROM ##xmldistinto AS t
		WHERE t.contador = @contador
	);

	-- Monta o caminho completo do arquivo de destino
	SET @nomeArquivo =
		'C:\Temp\'
		+ (SELECT t.NfArqXMLFileName FROM ##xmldistinto AS t WHERE t.contador = @contador)
		+ '.xml';

	-- Chama a procedure de escrita via OLE Automation
	EXEC YOUR_DATABASE.Management.[sp_Escreve_Arquivo_FSO]
		  @String     = @stringValor
		, @Ds_Arquivo = @nomeArquivo;

	SET @contador = @contador + 1;

END;


-- ============================================================
-- SEÇÃO 4: EXPORTAÇÃO INDIVIDUAL — Gera arquivo por NF
-- ============================================================

/*
	Descomente para exportar um XML específico pelo número da NF:

	DECLARE
		 @nomeArquivo VARCHAR(MAX)
		,@stringValor VARCHAR(MAX);

	SET @stringValor = (
		SELECT t.[xml]
		FROM ##tempxml AS t
		WHERE t.NF = 61893
	);

	SET @nomeArquivo =
		'C:\Temp\'
		+ (SELECT CAST(t.NF AS VARCHAR(20)) FROM ##tempxml AS t WHERE t.NF = 61893)
		+ '.xml';

	EXEC YOUR_DATABASE.Management.[sp_Escreve_Arquivo_FSO]
		  @String     = @stringValor
		, @Ds_Arquivo = @nomeArquivo;
*/
