------------------------------------------------------------------------------------------------------------------------------------
-- SOLU��O PARA EXPORTA��O DE XML CONTIDO EM CAMPOS DO SISTEMA, SEJA VARBINARY OU XML
-- Ticket 19107.
------------------------------------------------------------------------------------------------------------------------------------
USE YOUR_DATABASE
GO

SELECT 
t2.NfArqXMLFileName
, cast(cast(t2.NFArqXML AS xml) AS varchar(max)) AS [xml]
, ROW_NUMBER() Over(ORDER BY t1.NF) AS contador
INTO ##tempxml
FROM YOUR_DATABASE.dbo.vw_MovimentacaoReceita as t1
INNER JOIN MOVESTOQUEARQUIVOS AS t2 with(nolock)
ON t1.filial = t2.NfFilCod
AND t1.emissao = t2.NfDatEmis
AND t1.numcontrole = t2.NfNumero
WHERE t1.item IN (42312, 42311, 54756, 54755)
and t1.Emissao between '20180401' and '20181128'


--DROP TABLE ##tempxml
;WITH cte
AS
(
SELECT distinct t.NfArqXMLFileName, t.xml
FROM ##tempxml t
)
SELECT * , row_number() OVER (ORDER BY c.NfArqXMLFileName) AS contador 
INTO ##xmldistinto
FROM cte c

SELECT * FROM ##xmldistinto x

--DROP TABLE ##xmldistinto
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- DEVE-SE VALIDAR E RETIRAR REGISTROS DUPLICADOS
-- COLETADOS APENAS OS REPETIDOS QUE DEU 31 E GERADO NOVAMENTE COM NOME DIFERENTE

--;WITH repete
--as(
--SELECT t.NF, ROW_NUMBER() Over(partition by t.NF ORDER BY t.NF) AS contador
--FROM ##tempxml t
--)
--SELECT ','+ cast(r.NF AS varchar(50)) FROM repete r
--WHERE r.contador > 1


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/***********************************OBS.: DEVE-SE GERAR DE 255 EM 255 ARQUIVOS POR QUEST�ES DE LIMITA��O DA SOLU��O******************************/
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @nomeArquivo varchar(max)
	  , @stringValor varchar(max)
DECLARE @contador int = 766

while(@contador < 786)
BEGIN 

	SET @stringValor = (SELECT t.[xml] FROM ##xmldistinto t WHERE t.contador = @contador)

	SET @nomeArquivo = 'C:\Temp\'+ 

	(SELECT t.NfArqXMLFileName FROM ##xmldistinto t WHERE t.contador = @contador)

	+'.xml'

	EXEC YOUR_DATABASE.Management.[sp_Escreve_Arquivo_FSO] 
		  @String = @stringValor
		, @Ds_Arquivo = @nomeArquivo

	set @contador = @contador + 1

end 


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Gerando individualmente
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--DECLARE @nomeArquivo varchar(max)
--	  , @stringValor varchar(max)


--SET @stringValor = (SELECT t.[xml] FROM ##tempxml t WHERE t.NF = 61893)

--SET @nomeArquivo = 'C:\Temp\'+ (SELECT cast(t.NF AS varchar(20)) FROM ##tempxml t WHERE t.NF = 61893) +'.xml'

--EXEC YOUR_DATABASE.Management.[sp_Escreve_Arquivo_FSO] 
--		  @String = @stringValor
--		, @Ds_Arquivo = @nomeArquivo