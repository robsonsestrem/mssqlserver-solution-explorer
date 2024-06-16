USE GesCooper90
GO

DECLARE @dataInicio datetime = '2018-10-01 00:00:00.000',
		@dataFinal datetime = '2019-05-31 23:59:59.997'		
		

SELECT deriva.CtbFilCod                                                    AS Filial, 
       f.FilNomReduzido                                                    AS Nome_Filial, 
	                          
       p.PlaHorCod														   AS Conta_Horizontal,        
       (SELECT Substring(n5.plahornom, 1, Len(n5.plahornom)) 
        FROM   plahor AS n5 WITH (nolock) 
        WHERE p.plahorcod = n5.plahorcod)								   AS Nome_ContaHorizontal,
        
       ( CONVERT(VARCHAR, deriva.ctbdatmov, 103) )                         AS Data,     	    	 
	   
	   ISNULL(ce.Cencod,1)												   AS CentroCusto,
	   ISNULL(ce.CenNom, 'ADMINISTRACAO CENTRAL')						   AS Nome_Centro,

	   setor.SetCod											               AS Setor,
	   setor.SetNom														   AS Nome_Setor,
	  		 	   
       vertical.PlaConRed                                                  AS Conta_Vertical, 
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

       isnull(deriva.ctbtracod,0)                                          AS Cod_Forn, 
       isnull(t.tranom, N'Não informado')                                  AS Nome_Fornecedor,	 
	     	   	  		    	   
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

	   isnull(deriva.CtbNfOpeEstCod,0)                                     AS Nr_Ope_comercial,
	   isnull(deriva.CtbNfNumero,0)                                        AS Nr_doc_Numero,
	   isnull(deriva.CtbNumDoc,0)										   AS Nr_doc_NF	      
      
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
			   and A.CtbTipLot <> 1 -- negar lançamentos deste lote (zeramento de contas)

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
			   and A.CtbTipLot <> 1 -- negar lançamentos deste lote (zeramento de contas)
			  
	) AS deriva                
       LEFT JOIN TRANSACIONADORES AS t WITH(nolock) 
					ON deriva.CtbTraCod = t.tracod INNER JOIN PLAHOR AS p WITH(nolock) 
						ON deriva.CtaDebCrd = p.plahorred INNER JOIN PLAVER AS vertical WITH(nolock) 
							ON deriva.CtbVerCod = vertical.PlaConRed INNER JOIN HISCONTABIL AS h WITH(nolock) 
								ON deriva.CtbHisCtbCod = h.hisctbcod INNER JOIN FILIAIS AS f								 
									ON f.FilCod = deriva.CtbFilCod LEFT JOIN secao AS setor WITH(nolock) 
										ON substring(cast(deriva.CtbVerCod as varchar(3)),1,1) = setor.setcod LEFT JOIN IntegraTICravil.Bi.CentroCustoTI as ce
											ON ce.CenConRed = deriva.CtbVerCod
											   and ce.Filcod = deriva.CtbFilCod

WHERE deriva.CtbDatMov between @dataInicio AND @dataFinal
	  -- AND (SUBSTRING(p.plahorcod,1,3) in (311,312)) 
      -- AND deriva.CtbFilCod = 1				
      -- AND deriva.CtbNfNumero = 247379
      -- AND p.plahorcod = '3120606023'	    -- conta horizontal
	  -- AND deriva.ctbvercod = 103			-- conta vertical
	  -- and vertical.PlaConRed = 108
	  -- and t.tranom like '%networkbrasil%'

-----------------------------------------------------------------------------------------------------------------
-- GAMBIARRAS FEITAS PARA SE CONSEGUIR CENTRO DE CUSTO
-----------------------------------------------------------------------------------------------------------------  
/*
use TICRAVIL
go

create table CentroCusto
(
Cencod int not null primary key,
CenNom char(30),
CenConRed int,
Filcod smallint
)
*/


-- Povoamento
/*
insert into TICRAVIL.dbo.CentroCusto
(
Cencod, 
CenNom, 
CenConRed
)
select 
ce.CenCod,
ce.CenNom,
ce.CenConRed
from GesCooper90.dbo.CENTROCUSTO as ce
where ce.CenCod <> 0
*/


-- Ajustes das filiais
/*
USE TICRAVIL
GO

SELECT * FROM CentroCusto

--------------------------------------------------------------------

USE TICRAVIL
GO

UPDATE CentroCusto set Filcod = 84
where Cencod = 84
*/

