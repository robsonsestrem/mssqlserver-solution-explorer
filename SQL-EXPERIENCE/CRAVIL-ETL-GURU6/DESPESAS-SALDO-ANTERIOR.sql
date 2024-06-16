
DECLARE @saldoAtualInicio datetime = '2016-07-01',
		@saldoAtualFim    datetime = '2016-07-10',

		@saldoAnteriorInicio datetime = '2006-01-01',
		@saldoAnteriorFim datetime		
		set @saldoAnteriorFim =  cast(floor(cast(@saldoAtualInicio -1 as float))as datetime)	
		

	;WITH SALDO_ANTERIOR(Filial, Conta_Horizontal, CentroCusto, Setor, Conta_Vertical, Cod_Hist,--Cod_Forn, 
							Vlr_Deb_Anterior, Vlr_Cred_Anterior, SaldoAnterior)
	AS
	(
	SELECT 
		   deriva.CtbFilCod                                                    AS Filial, 
		   	                          
		   p.PlaHorCod														   AS Conta_Horizontal,        
		 				   	    	 	   
		   ISNULL(ce.Cencod,1)												   AS CentroCusto,
		  
		   setor.SetCod											               AS Setor,
		  	  		 	   
		   vertical.PlaConRed                                                  AS Conta_Vertical, 
		   
		   deriva.ctbhisctbcod                                                 AS Cod_Hist, 
		   --isnull(deriva.ctbtracod,0)                                          AS Cod_Forn,    

		   (deriva.CtbVlrDeb)				                               AS Vlr_Deb_Anterior, 
		   (deriva.ctbvlrcrd)											   AS Vlr_Cred_Anterior,       
		   (deriva.CtbVlrDeb - deriva.CtbVlrCrd)				               AS SaldoAnterior
	             
      
				--LANÇAMENTOS DE DEBITO     
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
			FROM  GesCooper90.dbo.CONTABIL AS A 
				   INNER JOIN GesCooper90.dbo.CONTABILLEVEL1 AS B WITH(nolock) 
						   ON A.CtbNumLot = B.CtbNumLot 
							  AND A.ctbdatmov = B.ctbdatmov 
							  AND A.ctbfilcod = B.ctbfilcod 
							  AND A.ctbnumseq = B.ctbnumseq 
			WHERE  A.ctbdatmov between @saldoAnteriorInicio AND @saldoAnteriorFim
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
			FROM   GesCooper90.dbo.CONTABIL AS A 
				   INNER JOIN GesCooper90.dbo.CONTABILLEVEL1 AS B WITH(nolock) 
						   ON A.CtbNumLot = B.CtbNumLot 
							  AND A.ctbdatmov = B.ctbdatmov 
							  AND A.ctbfilcod = B.ctbfilcod 
							  AND A.ctbnumseq = B.ctbnumseq 
			WHERE  A.ctbdatmov between @saldoAnteriorInicio AND @saldoAnteriorFim
				   AND A.CtbHorCrdCod <> 0
		) AS deriva                
		   LEFT JOIN GesCooper90.dbo.TRANSACIONADORES AS t WITH(nolock) 
						ON deriva.CtbTraCod = t.tracod INNER JOIN GesCooper90.dbo.PLAHOR AS p WITH(nolock) 
							ON deriva.CtaDebCrd = p.plahorred INNER JOIN GesCooper90.dbo.PLAVER AS vertical WITH(nolock) 
								ON deriva.CtbVerCod = vertical.PlaConRed INNER JOIN GesCooper90.dbo.HISCONTABIL AS h WITH(nolock) 
									ON deriva.CtbHisCtbCod = h.hisctbcod INNER JOIN GesCooper90.dbo.FILIAIS AS f								 
										ON f.FilCod = deriva.CtbFilCod LEFT JOIN GesCooper90.dbo.secao AS setor WITH(nolock) 
											ON substring(cast(deriva.CtbVerCod as varchar(3)),1,1) = setor.setcod LEFT JOIN TICRAVIL.dbo.CentroCustoTI as ce
												ON ce.CenConRed = deriva.CtbVerCod
												   and ce.Filcod = deriva.CtbFilCod	
	WHERE 
		  --AND ((SUBSTRING(p.plahorcod,1,3) in (311,312)) OR (SUBSTRING(P.PlaHorCod, 1, 1)	IN (1,2)))
		  deriva.CtbFilCod in (12)						  
		  AND p.plahorcod = '110101001'				-- conta horizontal

    --group by  deriva.CtbFilCod, p.PlaHorCod, ce.Cencod, setor.SetCod, vertical.PlaConRed, deriva.ctbhisctbcod--, deriva.ctbtracod

	) , SALDO_ATUAL(Filial, Nome_Filial, Conta_Horizontal, Nome_ContaHorizontal, Data_Mes, CentroCusto, Nome_Centro, Setor, Nome_Setor, Conta_Vertical
	                 ,Nome_ContaVertical, Cod_Hist, Vlr_Deb_Mes, Vlr_Cred_Mes, SaldoMes)--, Cod_Forn, Nr_Ope_comercial, Nr_doc_Numero, Nr_doc_NF)

	AS	
	
	(SELECT 
		   deriva.CtbFilCod                                                    AS Filial, 
		   f.FilNomReduzido                                                    AS Nome_Filial, 
	                          
		   p.PlaHorCod														   AS Conta_Horizontal,        
		   (SELECT Substring(n5.plahornom, 1, Len(n5.plahornom)) 
		    FROM   GesCooper90.dbo.plahor AS n5 WITH (nolock) 
		    WHERE p.plahorcod = n5.plahorcod)								   AS Nome_ContaHorizontal,
        
		   ( CONVERT(VARCHAR, deriva.ctbdatmov, 103) )                         AS Data_Mes,     	    	 
	   
		   ISNULL(ce.Cencod,1)												   AS CentroCusto,
		   ISNULL(ce.CenNom, 'ADMINISTRACAO CENTRAL')						   AS Nome_Centro,

		   setor.SetCod											               AS Setor,
		   setor.SetNom														   AS Nome_Setor,
	  		 	   
		   vertical.PlaConRed                                                  AS Conta_Vertical, 
		   vertical.placonnom                                                  AS Nome_ContaVertical, 

		   deriva.ctbhisctbcod                                                 AS Cod_Hist, 
	
		   deriva.CtbVlrDeb				                                       AS Vlr_Deb_Mes, 
		   deriva.ctbvlrcrd													   AS Vlr_Cred_Mes, 		          
		   (deriva.CtbVlrDeb - deriva.CtbVlrCrd)				               AS SaldoMes
	    --   isnull(deriva.ctbtracod,0)                                          AS Cod_Forn, 
	      
		   --isnull(deriva.CtbNfOpeEstCod,0)                                     AS Nr_Ope_comercial,
		   --isnull(deriva.CtbNfNumero,0)                                        AS Nr_doc_Numero,
		   --isnull(deriva.CtbNumDoc,0)										   AS Nr_doc_NF	      
      
			--LANÇAMENTOS DE DEBITO     
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
			FROM  GesCooper90.dbo.CONTABIL AS A 
				   INNER JOIN GesCooper90.dbo.CONTABILLEVEL1 AS B WITH(nolock) 
						   ON A.CtbNumLot = B.CtbNumLot 
							  AND A.ctbdatmov = B.ctbdatmov 
							  AND A.ctbfilcod = B.ctbfilcod 
							  AND A.ctbnumseq = B.ctbnumseq 
			WHERE  A.ctbdatmov between @saldoAtualInicio AND @saldoAtualFim
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
			FROM   GesCooper90.dbo.CONTABIL AS A 
				   INNER JOIN GesCooper90.dbo.CONTABILLEVEL1 AS B WITH(nolock) 
						   ON A.CtbNumLot = B.CtbNumLot 
							  AND A.ctbdatmov = B.ctbdatmov 
							  AND A.ctbfilcod = B.ctbfilcod 
							  AND A.ctbnumseq = B.ctbnumseq 
			WHERE  A.ctbdatmov between @saldoAtualInicio AND @saldoAtualFim
				   AND A.CtbHorCrdCod <> 0
		) AS deriva                
		   LEFT JOIN GesCooper90.dbo.TRANSACIONADORES AS t WITH(nolock) 
						ON deriva.CtbTraCod = t.tracod INNER JOIN GesCooper90.dbo.PLAHOR AS p WITH(nolock) 
							ON deriva.CtaDebCrd = p.plahorred INNER JOIN GesCooper90.dbo.PLAVER AS vertical WITH(nolock) 
								ON deriva.CtbVerCod = vertical.PlaConRed INNER JOIN GesCooper90.dbo.HISCONTABIL AS h WITH(nolock) 
									ON deriva.CtbHisCtbCod = h.hisctbcod INNER JOIN GesCooper90.dbo.FILIAIS AS f								 
										ON f.FilCod = deriva.CtbFilCod LEFT JOIN GesCooper90.dbo.secao AS setor WITH(nolock) 
											ON substring(cast(deriva.CtbVerCod as varchar(3)),1,1) = setor.setcod LEFT JOIN TICRAVIL.dbo.CentroCustoTI as ce
												ON ce.CenConRed = deriva.CtbVerCod
												   and ce.Filcod = deriva.CtbFilCod	
	WHERE 
		  --AND ((SUBSTRING(p.plahorcod,1,3) in (311,312)) OR (SUBSTRING(P.PlaHorCod, 1, 1)	IN (1,2)))
		  deriva.CtbFilCod in (12)						   
		  AND p.plahorcod = '110101001'				-- conta horizontal
		 
	)

	select a.Filial, a.Conta_Horizontal, a.Conta_Vertical, a.CentroCusto, a.Setor, a.Cod_Hist, --a.Cod_Forn, a.Nr_Ope_comercial, a.Nr_doc_Numero, a.Nr_Ope_comercial,

	@saldoAnteriorFim as DataSaldoAnterior, o.Vlr_Deb_Anterior, o.Vlr_Cred_Anterior, o.SaldoAnterior, a.Vlr_Deb_Mes, a.Vlr_Cred_Mes, a.SaldoMes, a.Data_Mes 


	from SALDO_ATUAL AS a INNER JOIN SALDO_ANTERIOR as o
	ON a.Filial = o.Filial 
	AND a.Conta_Horizontal = o.Conta_Horizontal 
	AND a.Conta_Vertical = o.Conta_Vertical 
	AND a.CentroCusto = o.CentroCusto
	AND a.Setor = o.Setor
	AND a.Cod_Hist = o.Cod_Hist



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

