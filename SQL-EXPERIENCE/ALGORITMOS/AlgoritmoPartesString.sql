/*
================================================================================
OBJETIVO: Demonstrar a extração de substring antes do delimitador '/' usando
		  CHARINDEX e LEFT, com conversão explícita para INT via CAST.
PROJETO: mssqlserver-solution-explorer
================================================================================
*/

-- Declaração das variáveis de teste com prefixos numéricos de comprimento variado
DECLARE @teste01 VARCHAR(30) = '2/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE'
	   ,@teste02 VARCHAR(30) = '12/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE'
	   ,@teste03 VARCHAR(30) = '122/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE';

-- Extração do valor numérico anterior à barra '/' em cada variável;
-- concatenação dos dados brutos para validação visual
SELECT
	CAST(
		CASE WHEN CHARINDEX('/', @teste01, 0) > 0
			THEN LEFT(@teste01, CHARINDEX('/', @teste01, 0) - 1)
		END
	AS INT)                                                         AS Filtro01
   ,CAST(
		CASE WHEN CHARINDEX('/', @teste02, 0) > 0
			THEN LEFT(@teste02, CHARINDEX('/', @teste02, 0) - 1)
		END
	AS INT)                                                         AS Filtro02
   ,CAST(
		CASE WHEN CHARINDEX('/', @teste03, 0) > 0
			THEN LEFT(@teste03, CHARINDEX('/', @teste03, 0) - 1)
		END
	AS INT)                                                         AS Filtro03
   ,@teste01 + '   ###   ' + @teste02 + '   ###   ' + @teste03     AS Dados;


