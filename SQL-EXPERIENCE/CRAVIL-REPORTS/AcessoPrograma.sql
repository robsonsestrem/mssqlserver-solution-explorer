USE GesCooper90						--PRODUTO INDIVIDUAL DETALHADO 
GO

SELECT deriva.Usuario, 
       deriva.filial, 
       CASE 
         WHEN deriva.teste = 1 THEN 'Tem    Acesso' 
         WHEN deriva.teste = 0 THEN 'Acesso Negado' 
       END AS Produto Individual Detalhado, 
       deriva.TotalDeAcessos

FROM   (SELECT P.usucod         AS Usuario, 
               C.usufilcod      AS Filial,           
-----------------------------------------------------------------------------------
               Count(CASE 
                       WHEN P.prgcod1 IN ( 'WCONALOCADO' ) THEN ''					   
                     END)       AS teste,
-----------------------------------------------------------------------------------					  
               Count(P.prgcod1) AS TotalDeAcessos
-----------------------------------------------------------------------------------
        FROM   progusulevel1 AS P 
               INNER JOIN cadusuarios AS C 
                       ON P.usucod = C.usucod 
		WHERE C.usuinativo IN ( 'N' )
        GROUP  BY P.usucod, 
                  C.usufilcod
                  ) AS deriva 


-----------------------------------------------------------------------------------
--	OPÇÃO ALTERNATIVA
-----------------------------------------------------------------------------------
USE GesCooper90						
GO

SELECT x1.Filial, x1.Usuario, 'TEM ACESSO' AS PERMISSÕES
FROM
		(SELECT		   
				P.usucod         AS Usuario, 
                C.usufilcod      AS Filial,
				count(p.PrgCod1) AS TotalDeAcessos
        FROM   progusulevel1 AS P 
               INNER JOIN cadusuarios AS C 
                       ON P.usucod = C.usucod 
		WHERE C.usuinativo IN ( 'N' )
		and exists                      
						(select x.UsuCod from progusulevel1 as x
						 where x.PrgCod1 = 'WCONALOCADO'
						 and x.UsuCod = P.UsuCod
						)
		 GROUP  BY P.usucod, 
                   C.usufilcod) as x1

UNION

SELECT x2.Filial, x2.Usuario, 'ACESSO NEGADO'
FROM 
		(SELECT		   
				P.usucod         AS Usuario, 
                C.usufilcod      AS Filial,				
				count(p.PrgCod1) AS TotalDeAcessos
        FROM   progusulevel1 AS P 
               INNER JOIN cadusuarios AS C 
                       ON P.usucod = C.usucod 
		WHERE C.usuinativo IN ( 'N' )
		and not exists                      
						(select x.UsuCod from progusulevel1 as x
						 where x.PrgCod1 = 'WCONALOCADO'
						 and x.UsuCod = P.UsuCod
						)
		 GROUP  BY P.usucod, 
                   C.usufilcod				 
				   ) as x2