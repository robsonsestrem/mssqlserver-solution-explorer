DECLARE @dataInicio DATETIME = '2016-01-01' 
DECLARE @dataFim DATETIME = '2016-06-02' 

SELECT M1.nffilcod                         AS Cod_Filial, 
       F.filnomreduzido                    AS Nome_Filial, 
       M.nfopeestcod                       AS Op, 
       CONVERT(VARCHAR, M1.nfdatemis, 105) AS Data_Emissao, 
       M1.nfnumero                         AS Numero_Ctrl, 
       M1.itemprocod                       AS Cod_Prod, 
       P.pronom                            AS Descricao_Prod, 
       M1.itemqtdade                       AS Qtdade, 
       Cast(M1.itemvlrunitario AS MONEY)   AS Vlr_Unit, 
       M.nfnumdoc                          AS Nota, 
       M.nfforcod                          AS Cod_Produtor, 
       T.tranom                            AS Nome_Produtor, 
       T.tracpf                            AS CPF, 
       CONVERT(VARCHAR, M.nfentsaid, 105)  AS Data_Mov, 
       M.nfhorentsaid                      AS Hora_Mov, 
       C.munnom                            AS Mun_End_Produtor, 
       ISNULL(C.muncep, 0)                 AS CEP_End_Produtor 
FROM   movestoquelevel1 M1 WITH(nolock) 
       INNER JOIN movestoque M WITH(nolock) 
               ON M1.nffilcod = M.nffilcod 
                  AND M1.nfdatemis = M.nfdatemis 
                  AND M1.nfnumero = M.nfnumero 
       INNER JOIN operacao OP WITH(nolock) 
               ON M.nfopeestcod = OP.opeestcod 
       INNER JOIN produtos P WITH(nolock) 
               ON M1.itemprocod = P.procod 
       INNER JOIN filiais F WITH(nolock) 
               ON M1.nffilcod = F.filcod 
       INNER JOIN transacionadores T WITH(nolock) 
               ON M.nfforcod = T.tracod 
       INNER JOIN municipios C WITH(nolock) 
               ON T.trapaicod = C.paicod 
                  AND T.traestcod = C.estcod 
                  AND T.tramuncod = C.muncod 
WHERE  M1.nfdatemis BETWEEN @dataInicio AND @dataFim 
       AND ( M1.itemprocod IN ( 90004 ) ) 
       -- Usuário informa produto de sua escolha  
       AND ( M.nfopeestcod IN ( 27, 79 ) ) 
       AND M.nfsituacao <> 4 