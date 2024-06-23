USE GesCooper90
GO

DECLARE @datacontrol DATETIME = Month(Getdate()) 

IF @datacontrol < 12 
  BEGIN 
      SELECT Day(T.tradatnasc) Dia, 
             F.filnomreduzido  Filial, 
             T.tranom          Nome, 
             CASE 
               WHEN T.tranatsocial = 3 THEN 'Funcionario' 
               WHEN T.tranatsocial = 1 THEN 'Associado' 
             END               AS Natureza Social 
      FROM   transacionadores AS T 
             INNER JOIN filiais AS F 
                     ON T.trafilcod = F.filcod 
             INNER JOIN municipios AS M 
                     ON T.tramuncod = M.muncod 
      WHERE  Month(T.tradatnasc) = @datacontrol + 1 
             AND T.tranatjuridica = 1 
             AND ( T.tranatsocial IN ( 1, 3 ) ) 
             AND ( T.tranatsocial = 1 
                    OR T.tranatcomercial = 2 ) 
      ORDER  BY Day(T.tradatnasc), 
                T.tranom, 
                T.tranatsocial 
  END 
ELSE IF @datacontrol = 12 
  BEGIN 
      SELECT Day(T.tradatnasc) Dia, 
             F.filnomreduzido  Filial, 
             T.tranom          Nome, 
             CASE 
               WHEN T.tranatsocial = 3 THEN 'Funcionario' 
               WHEN T.tranatsocial = 1 THEN 'Associado' 
             END               AS Natureza Social 
      FROM   transacionadores AS T 
             INNER JOIN filiais AS F 
                     ON T.trafilcod = F.filcod 
             INNER JOIN municipios AS M 
                     ON T.tramuncod = M.muncod 
      WHERE  Month(T.tradatnasc) = @datacontrol 
             AND T.tranatjuridica = 1 
             AND ( T.tranatsocial IN ( 1, 3 ) ) 
             AND ( T.tranatsocial = 1 
                    OR T.tranatcomercial = 2 ) 
      ORDER  BY Day(T.tradatnasc), 
                T.tranom, 
                T.tranatsocial 
  END 