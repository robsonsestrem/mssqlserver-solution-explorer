use GesCooper90
go

SELECT tit.titfilcod AS Filial, 
       tit.tittracod AS Cliente, 
       tit.titnumero AS Título, 
       tit.titdoccod AS Tipo, 
       tit.titdatdoc AS Data Lançamento, 
       tit.titvlrnom AS Valor, 
       tit.titconcod AS Conta Financeira, 
       tit.titcodctb AS Cód.Contabilização 
FROM   cadtit AS tit WITH(nolock) 
WHERE  tit.titdoccod IN ( 6, 9 ) 
       AND tit.titfilcod <> 81          -- para verifica nas outras filiais se o código da conta 
       AND tit.titdatdoc >= '2017-08-31' -- está registrado 
       AND tit.titconcod LIKE 'CX81'    -- conta à procurar nas outras filiais 


 