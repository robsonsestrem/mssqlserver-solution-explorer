USE GesCooper90
GO

DECLARE @dataInicio datetime = '2016-01-01',
		@dataFinal datetime = '2016-01-31'		
		

SELECT deriva.CtbFilCod                                                    AS Filial, 
       f.FilNomReduzido                                                    AS Nome_Filial, 
	                          
       p.PlaHorCod														   AS Conta_Horizontal,        
       (SELECT Substring(n5.plahornom, 1, Len(n5.plahornom)) 
        FROM   plahor AS n5 WITH (nolock) 
        WHERE p.plahorcod = n5.plahorcod)								   AS Nome_ContaHorizontal,
        
       ( CONVERT(VARCHAR, deriva.ctbdatmov, 103) )                         AS Data, 

       --Isnull(setor.setcod, 0)                                           AS Setor, 
       --Isnull(setor.setnom,N'Indisponível')                              AS Nome_Setor, 
	   --Isnull(m.NfCenCusDestino, 0)									   AS CentroCusto,
	   --Isnull(ce.CenNom, N'Indisponível')						           AS Nome_CentroCusto,


	    ISNULL(m.NfSetCod,0)                                                                 'Set.',
        ISNULL(m.NfSecCod,0)                                                                 'Dep.',
	    ISNULL(m.NfCenCusDestino,0)                                                          'CC',


       deriva.ctbvercod                                                    AS Conta_Vertical, 
       vertical.placonnom                                                  AS Nome_ContaVertical, 

       deriva.ctbhisctbcod                                                 AS Cod_Hist, 
       Substring(h.hisctbnom, 1, Len(h.hisctbnom)) 
       + ' ' 
       + Isnull(Substring(t.tranom, 1, Isnull(Len(t.tranom), 0)), '') 
       + ' ' 
       + Substring(deriva.ctbhiscomple, 1, Len(deriva.ctbhiscomple))       AS Hist_Completo, 
       deriva.CtbVlrDeb				                                       AS Vlr_Deb, 
       deriva.ctbvlrcrd													   AS Vlr_Cred, 
       (deriva.CtbVlrDeb - deriva.CtbVlrCrd)				               AS Saldo, 

       deriva.ctbtracod                                                    AS Cod_Forn, 
       Isnull(t.tranom, N'Não informado')                                  AS Nome_Fornecedor,	 
	     	   	  		    	   
	   SUBSTRING(p.plahorcod,1,1)										   AS Classif_Nivel1,

	   SUBSTRING(p.plahorcod,2,1)										   AS Classif_Nivel2,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN SUBSTRING(p.plahorcod,3,1)
				ELSE SUBSTRING(p.plahorcod,3,2) 
			END															   AS Classif_Nivel3,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN SUBSTRING(p.plahorcod,4,2) 
				ELSE SUBSTRING(p.plahorcod,5,2) 
			END                                                            AS Classif_Nivel4,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN SUBSTRING(p.plahorcod,6,2) 
				ELSE SUBSTRING(p.plahorcod,7,3) 
			END                                                            AS Classif_Nivel5,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN SUBSTRING(p.plahorcod,8,3) 
				ELSE ''     
			END                                                            AS Classif_Nivel6,

       (SELECT n1.plahornom 
        FROM   plahor AS n1 WITH (nolock) 
        WHERE  Substring(p.plahorcod, 1, 1) = n1.plahorcod)				   AS Nom_Classif_N1,

       (select n2.PlaHorNom 
		   from plahor as n2 with (nolock) 
		   where SUBSTRING(p.plahorcod,1,2) = n2.PlaHorCod)				   AS Nom_Classif_N2,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN 
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,3) = n2.PlaHorCod) 
				ELSE 
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,4) = n2.PlaHorCod) 
			END															   AS Nom_Classif_N3,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN 
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,5) = n2.PlaHorCod) 
				ELSE
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,6) = n2.PlaHorCod) 
			END                                                            AS Nom_Classif_N4,

	   CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN 
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,7) = n2.PlaHorCod) 
				ELSE 
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,9) = n2.PlaHorCod) 
			END	                                                           AS Nom_Classif_N5,

       CASE WHEN SUBSTRING(p.plahorcod,1,1) IN (3,4) 
				THEN 
					(select n2.PlaHorNom from plahor as n2 with (nolock) where SUBSTRING(p.plahorcod,1,10) = n2.PlaHorCod)
				ELSE '' 
			END	                                                           AS Nom_Classif_N6,

	   deriva.CtbNfOpeEstCod                                               AS Nr_Ope_comercial,
	   deriva.CtbNfNumero                                                  AS Nr_doc_comercial,
	   isnull(m.NfNumDoc,0)												   AS Nr_doc_fiscal	      
      
---LANÇAMENTOS DE DEBITO     
FROM   (SELECT A.CtbFilCod
              ,A.CtbDatMov
              ,A.CtbNfNumero
			  ,A.CtbNumDoc
              ,A.CtbHorDebCod  AS CtaDebCrd -- debitos            
              ,A.CtbHisCtbCod
              ,A.CtbHisComple             
              ,B.CtbVerCod          			  
              ,B.CtbVerVlr AS CtbVlrDeb
              ,0           AS CtbVlrCrd          
              ,A.CtbTraCod              
			  ,A.CtbNfOpeEstCod
        FROM   CONTABIL AS A 
               INNER JOIN CONTABILLEVEL1 AS B WITH(nolock) 
                       ON A.CtbNumLot = B.CtbNumLot 
                          AND A.ctbdatmov = B.ctbdatmov 
                          AND A.ctbfilcod = B.ctbfilcod 
                          AND A.ctbnumseq = B.ctbnumseq 
        WHERE  A.ctbdatmov between @dataInicio AND @dataFinal
               AND A.ctbhordebcod <> 0

--LANÇAMENTOS DE CREDITO   
        UNION ALL

        SELECT A.CtbFilCod
              ,A.CtbDatMov
              ,A.CtbNfNumero
			  ,A.CtbNumDoc
              ,A.CtbHorCrdCod  -- Credito                 
              ,A.CtbHisCtbCod
              ,A.CtbHisComple             
              ,B.CtbVerCod  
              ,0                                  
              ,B.CtbVerVlr			 
              ,A.CtbTraCod           
			  ,A.CtbNfOpeEstCod
        FROM   CONTABIL AS A 
               INNER JOIN CONTABILLEVEL1 AS B WITH(nolock) 
                       ON A.CtbNumLot = B.CtbNumLot 
                          AND A.ctbdatmov = B.ctbdatmov 
                          AND A.ctbfilcod = B.ctbfilcod 
                          AND A.ctbnumseq = B.ctbnumseq 
        WHERE  A.ctbdatmov between @dataInicio AND @dataFinal
               AND A.CtbHorCrdCod <> 0
	) AS deriva                
       LEFT JOIN MOVESTOQUE AS m WITH(nolock)					-- só para trazer a NF
              ON deriva.CtbNfOpeEstCod = m.NfOpeEstCod
                 AND deriva.CtbDatMov = m.nfdatemis 
                 AND deriva.CtbNfNumero = m.nfnumero 
				 AND deriva.CtbNumDoc = m.nfnumdoc	LEFT JOIN TRANSACIONADORES AS t WITH(nolock) 
					ON deriva.CtbTraCod = t.tracod INNER JOIN PLAHOR AS p WITH(nolock) 
						ON deriva.CtaDebCrd = p.plahorred INNER JOIN PLAVER AS vertical WITH(nolock) 
							ON deriva.CtbVerCod = vertical.PlaConRed INNER JOIN HISCONTABIL AS h WITH(nolock) 
								ON deriva.CtbHisCtbCod = h.hisctbcod INNER JOIN FILIAIS AS f								 
									ON f.FilCod = deriva.CtbFilCod 

									--  LEFT JOIN secao AS setor WITH(nolock) 
									--	ON substring(cast(deriva.CtbVerCod as varchar(3)),1,1) = setor.setcod inner join centrocusto AS ce
									--  ON ce.CenCod = m.NfCenCusDestino

WHERE deriva.CtbDatMov between @dataInicio AND @dataFinal

-- 27/01/2015 filtro tornou-se obsoleto devida a alterações no plano de contas. 
-- foi alterado para:
-----------------------------------------------------------------------------------------------------------------
and (  SUBSTRING(p.plahorcod,1,3) in (312,322,332)
     or SUBSTRING(p.plahorcod,1,5) in (31103,31104,31105,32103,32104,32105,33103,33104,33105))
-----------------------------------------------------------------------------------------------------------------
	   -- FILTROS PARA TESTE

       AND deriva.CtbFilCod in (64)				
       -- AND deriva.CtbNfNumero = 247379
       -- AND p.plahorcod = 3120101001	        --conta horizontal
	   -- AND deriva.ctbvercod in (201)			--conta vertical

order by Conta_Horizontal
	  
