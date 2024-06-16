use GesCooper90
go
SET NOCOUNT ON

	SELECT 
		   f.FilCod										   AS Código_Filial,
		   f.FilNomReduzido                                AS Nome_Filial,
		   p.ProCod                                        AS Código_Produto, 
		   p.ProNom                                        AS Nome_Produto, 
		   p.ProFamCod                                    AS Código_Família, 
		   p.ProGrpCod                                     AS Código_Grupo, 
		   p.ProSubCod                                     AS Código_Subgrupo, 
          (SELECT dbo.getEstoque(f.FilCod, p.ProCod, Getdate())) AS SaldoEstoque,
		   CASE 
			 WHEN prosituacao = 's' THEN 'Ativo' 
			 WHEN prosituacao = 'c' THEN 'Ativo - Compra Direta' 
			 WHEN prosituacao = 'n' THEN 'Desativado' 
		   END													 AS Situação,
	   
		   CASE 
		   WHEN ProFlag35 = 0 THEN 'Não Desativando'
		   when ProFlag35 = 1 THEN 'Desativando'
		   END													 AS Desativação
	    
	FROM PRODUTOS AS p WITH(NOLOCK)
	CROSS JOIN FILIAIS AS f WITH(NOLOCK)

	WHERE ProSituacao IN ('s','c') -- só ativos 
		  AND f.FilFlag2 = 0 -- somente filiais ativas
		  --AND f.FilCod = 1
		  --AND p.ProCod = 901


-- usada função escalar -> dbo.getEstoque 
-- devido a grande quantidade de processamento nesta query será viabilizado 
-- uma nova função para este cálculo de estoque


