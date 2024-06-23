--Eu tenho um campo que pode ser 

--2/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE
--12/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE
--122/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE

-- eu preciso que sempre pegar os dados antes da barra. Como faço?

declare @teste01 varchar(30) = '2/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE'
		,@teste02 varchar(30) = '12/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE'
		,@teste03 varchar(30) = '122/15_Ciclo 1_Todas_VAR_RTV_EMAIL_TOD_SE'

SELECT  
		CAST(CASE WHEN charindex('/',@teste01,0) > 0 
					THEN LEFT(@teste01, charindex('/',@teste01,0)-1) 
			 END AS INT)											as Filtro01
		--
		,CAST(CASE WHEN charindex('/',@teste02,0) > 0 
					THEN LEFT(@teste02, charindex('/',@teste02,0)-1) 
			 END AS INT)											as Filtro02
		--
		,CAST(CASE WHEN charindex('/',@teste03,0) > 0 
					THEN left(@teste03, charindex('/',@teste03,0)-1) 
			 END AS INT)											as Filtro03
		--
		,@teste01+'   ###   '+@teste02+'   ###   '+@teste03			as Dados



