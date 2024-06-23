USE GesCooper90
GO

DECLARE @data DATETIME = '20180801'

if(OBJECT_ID('tempdb..#fechamentoCx') is not null)
  drop table #fechamentoCx

CREATE TABLE #fechamentoCx 
  ( 
     Filial   SMALLINT, 
     Caixa    SMALLINT, 
     Situacao VARCHAR(30) 
  ) 
------------------------------------------------------------------------------------------------
INSERT INTO #fechamentoCx 
            (Filial, 
             Caixa, 
             Situacao
			 ) 
(SELECT c.filcod        AS Filial, 
        c.caicod        AS Caixa, 
        'SEM MOVIMENTO' AS Situacao 
 FROM   caixas AS c 
 WHERE  c.caisituacao = 0 
        AND NOT EXISTS(SELECT v.cupcodigo 
                       FROM   vendasecf AS v   --tabela vazia - status sem movimento 
                       WHERE  v.caicod = c.caicod 
                              AND v.filcod = c.filcod 
                              AND v.cupdatmov = @data
					   )
) 
------------------------------------------------------------------------------------------------ 
INSERT INTO #fechamentoCx 
            (Filial, 
             Caixa, 
             Situacao
			 ) 
(SELECT c.filcod AS Filial, 
        c.caicod AS Caixa, 
        'ABERTO' AS Situacao 
 FROM   caixas AS c 
 WHERE  c.caisituacao = 0 -- ativo, desativado é 2 
 --
 EXCEPT 
 --
 SELECT v.intpdvfilcod AS Filial, 
        v.intpdvcaicod AS Caixa, 
        'ABERTO'       AS Situacao 
 FROM   intpdv AS v 
 WHERE  v.intpdvdat = @data
 ) 
------------------------------------------------------------------------------------------------             
INSERT INTO #fechamentoCx 
            (Filial, 
             Caixa, 
             Situacao
			 ) 
(SELECT v.intpdvfilcod AS Filial, 
        v.intpdvcaicod AS Caixa, 
        'FECHADO'      AS Situacao 
 FROM   intpdv AS v 
 WHERE  v.intpdvdat = @data
 ) 
------------------------------------------------------------------------------------------------          
;WITH combinacoes 
     AS (SELECT DISTINCT Filial, 
                         Caixa 
         FROM   #fechamentoCx AS TOut
		 ) 
SELECT Filial, 
       Caixa, 
       (SELECT TOP 1 Situacao 
        FROM   #fechamentoCx AS TInt 
        WHERE  TOut.Filial = TInt.Filial 
               AND TOut.Caixa = TInt.Caixa      
       ) AS Situacao 
FROM   combinacoes AS TOut 

