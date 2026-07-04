/*
================================================================================
OBJETIVO: Tratar coordenadas geográficas duplicadas (Latitude/Longitude) usando
		  CTE com ROW_NUMBER, aplicando concatenação ou STUFF para diferenciar
		  registros com coordenadas idênticas.
PROJETO: mssqlserver-solution-explorer
================================================================================
*/

-- CTE: enumera registros por Latitude usando ROW_NUMBER para identificar duplicatas
;WITH coord AS
(
	SELECT
		t1.Latitude
	   ,t1.Longitude
	   ,t1.NomeRazaoSocial
	   ,ROW_NUMBER() OVER (PARTITION BY t1.Latitude ORDER BY t1.Latitude) AS Contador
	FROM System.vw_MapsAssociados AS t1
	WHERE t1.Latitude IS NOT NULL
		AND t1.Latitude <> ''
)
-- Seleção final: aplica ajuste de coordenada duplicada conforme comprimento do campo
SELECT
	t2.NomeRazaoSocial
   ,CASE
		-- Concatenação simples quando o campo tem menos de 10 caracteres
		WHEN t2.Contador > 1 AND LEN(t2.Latitude) < 10
			THEN (t2.Latitude + CAST(t2.Contador AS VARCHAR(5)))
		-- Substituição via STUFF quando o campo tem 10 ou mais caracteres
		WHEN t2.Contador > 1 AND LEN(t2.Latitude) >= 10
			THEN STUFF(t2.Latitude, 10, 5, CAST(t2.Contador AS VARCHAR(5)))
		ELSE t2.Latitude
	END                                                             AS Latitude
   ,CASE
		-- Concatenação simples quando o campo tem menos de 10 caracteres
		WHEN t2.Contador > 1 AND LEN(t2.Longitude) < 10
			THEN (t2.Longitude + CAST(t2.Contador AS VARCHAR(5)))
		-- Substituição via STUFF quando o campo tem 10 ou mais caracteres
		WHEN t2.Contador > 1 AND LEN(t2.Longitude) >= 10
			THEN STUFF(t2.Longitude, 10, 5, CAST(t2.Contador AS VARCHAR(5)))
		ELSE t2.Longitude
	END                                                             AS Longitude
FROM coord AS t2;