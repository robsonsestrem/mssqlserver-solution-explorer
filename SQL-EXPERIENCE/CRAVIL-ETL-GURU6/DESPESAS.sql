USE GesCooper90
GO

DECLARE @dataInicio datetime = '2015-05-13',
		@dataFinal datetime = '2015-05-13'		
		
SELECT deriva.CtbFilCod                                                    AS Filial, 
       FIL.FilNomReduzido                                                  AS Nome_Filial, 
       (SELECT n1.plahornom 
        FROM   plahor AS n1 WITH (nolock) 
        WHERE  Substring(Cast(E.plahorcod AS CHAR), 1, 1) = n1.plahorcod)  AS Class_Despesa, 
       E.PlaHorCod														   AS Conta_Horizontal, 
       (SELECT Substring(n5.plahornom, 1, Len(n5.plahornom)) 
        FROM   plahor AS n5 WITH (nolock) 
        WHERE  Cast(E.plahorcod AS CHAR) = n5.plahorcod)                   AS Nome_ContaHorizontal, 
       ( CONVERT(VARCHAR, deriva.ctbdatmov, 103) )                         AS Data, 
       Isnull(setor.setcod, 0)                                             AS Setor, 
       Isnull(setor.setnom,N'Indisponível')                                AS Nome_Setor, 
	   Isnull(ce.CenCod, 0)												   AS CentroCusto,
	   Isnull(ce.CenNom, N'Indisponível')								   AS Nome_CentroCusto,
       deriva.ctbvercod                                                    AS Conta_Vertical, 
       F.placonnom                                                         AS Nome_ContaVertical, 
       deriva.ctbhisctbcod                                                 AS Cod_Hist, 
       Substring(G.hisctbnom, 1, Len(G.hisctbnom)) 
       + ' ' 
       + Isnull(Substring(D.tranom, 1, Isnull(Len(D.tranom), 0)), '') 
       + ' ' 
       + Substring(deriva.ctbhiscomple, 1, Len(deriva.ctbhiscomple))       AS Hist_Completo, 
       Cast(deriva.CtbVlrDeb AS MONEY)                                     AS Vlr_Deb, 
       Cast(deriva.ctbvlrcrd AS MONEY)                                     AS Vlr_Cred, 
       Cast(deriva.CtbVlrDeb - deriva.CtbVlrCrd AS MONEY)                  AS Saldo, 
       deriva.ctbtracod                                                    AS Cod_Forn, 
       Isnull(D.tranom, N'Não informado')                                  AS Nome_Fornecedor
      
---LANÇAMENTOS DE DEBITO     
FROM   (SELECT A.CtbFilCod
              ,A.CtbDatMov
              ,A.CtbNfNumero
              ,A.CtbHorDebCod 'CtbHorCtaCod' --debitos            
              ,A.CtbHisCtbCod
              ,A.CtbHisComple             
              ,B.CtbVerCod          			  
              ,B.CtbVerVlr 'CtbVlrDeb'
              ,0           'CtbVlrCrd'          
              ,A.CtbTraCod              
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
              ,A.CtbHorCrdCod  --Credito                 
              ,A.CtbHisCtbCod
              ,A.CtbHisComple             
              ,B.CtbVerCod                                    
              ,B.CtbVerVlr
			  ,0
              ,A.CtbTraCod           
        FROM   CONTABIL AS A 
               INNER JOIN CONTABILLEVEL1 AS B WITH(nolock) 
                       ON A.CtbNumLot = B.CtbNumLot 
                          AND A.ctbdatmov = B.ctbdatmov 
                          AND A.ctbfilcod = B.ctbfilcod 
                          AND A.ctbnumseq = B.ctbnumseq 
        WHERE  A.ctbdatmov between @dataInicio AND @dataFinal
               AND A.CtbHorCrdCod <> 0
	) AS deriva 
               
       LEFT JOIN MOVESTOQUE AS MOV WITH(nolock) 
              ON deriva.CtbFilCod = MOV.nffilcod 
                 AND deriva.CtbDatMov = MOV.nfdatemis 
                 AND deriva.CtbNfNumero = MOV.nfnumero 
       LEFT JOIN TRANSACIONADORES AS D WITH(nolock) 
              ON deriva.CtbTraCod = D.tracod 
       INNER JOIN PLAHOR AS E WITH(nolock) 
               ON deriva.CtbHorCtaCod = E.plahorred 
       INNER JOIN PLAVER AS F WITH(nolock) 
               ON deriva.CtbVerCod = f.placoncod 
       INNER JOIN HISCONTABIL AS G WITH(nolock) 
               ON deriva.CtbHisCtbCod = G.hisctbcod                
       INNER JOIN FILIAIS AS FIL 
               ON FIL.FilCod = deriva.CtbFilCod      
       LEFT JOIN centrocusto AS ce 
               ON MOV.NfCenCusDestino = ce.cencod 
       LEFT JOIN secao AS setor WITH(nolock) 
               ON MOV.NfSetCod = setor.setcod 
       
WHERE  deriva.CtbDatMov between @dataInicio AND @dataFinal
	   --FILTROS PARA TESTE
       --AND deriva.CtbFilCod = 1				--filial 
       --AND E.plahorcod = 3120606001			--conta horizontal
	   --AND deriva.ctbvercod = 102				--conta vertical