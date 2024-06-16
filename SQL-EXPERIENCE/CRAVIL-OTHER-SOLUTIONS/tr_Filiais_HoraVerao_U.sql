---------------------------------------------------------------------------------
-- padroniza horário de verão para todas filiais quando alterado na filial 1.
---------------------------------------------------------------------------------
USE GesCooper90
GO

CREATE TRIGGER tr_Filiais_HoraVerao_U
ON filiais
WITH ENCRYPTION 
after UPDATE 
AS 
  BEGIN 
      SET nocount ON 

      DECLARE @horaVerao SMALLINT 

      IF UPDATE(filflag69) 
        BEGIN 
            (SELECT @horaVerao = filflag69 
             FROM   filiais 
             WHERE  filcod = 1) --padrão da matriz 

            UPDATE filiais 
            SET    filflag69 = @horaVerao 
            WHERE  filflag2 = 0 --filiais ativas 
        END 
  END 


GO








 
 
 
 
 
 
 
 
 
 