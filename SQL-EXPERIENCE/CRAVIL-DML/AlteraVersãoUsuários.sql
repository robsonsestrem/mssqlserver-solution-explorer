USE gescooper90 

BEGIN TRAN 

BEGIN try 
    UPDATE cadusuarios 
    SET    usuvercodigo = 2 
    WHERE  usufilcod <> 1 
           AND usuinativo NOT IN ( 'S', 'NULL' ) 

    PRINT 'DEU BOA' 

    COMMIT 
END try 

BEGIN catch 
    PRINT 'DEU MERDA' 

    SELECT Error_number()  AS Número de erro, 
           Error_message() AS Mensagem 

    ROLLBACK 
END catch 