DECLARE @datacontrol DATETIME = Month(Getdate()) 

IF @datacontrol < 12 
  BEGIN 
      SELECT Day(T.tradatnasc)                                  dia, 
             T.trafilcod                                        filial, 
             F.filnomreduzido                                   NomeFilial, 
             T.tracod                                           matrícula, 
             T.trasit                                           cadastro, 
             T.tranom                                           Nome, 
             T.traend                                           Rua, 
             Replace(Replace(T.tranumend, 'S/N', ''), 'SN', '') Número, 
             T.tracomplemento                                   Complemento, 
             Replace(T.trabairro, '.', '')                      Bairro, 
             T.tramuncod                                        Cod Município 
             , 
             M.munnom 
             Município, 
             T.tracep                                           Cep, 
             T.trafone                                          Telefone, 
             T.tracelular                                       Celular, 
             T.tranatjuridica                                   juridica, 
             T.tranatfiscal                                     fiscal, 
             T.tranatcomercial                                  comercial, 
             T.tranatsocial                                     social 
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
      SELECT Day(T.tradatnasc)                                  dia, 
             T.trafilcod                                        filial, 
             F.filnomreduzido                                   NomeFilial, 
             T.tracod                                           matrícula, 
             T.trasit                                           cadastro, 
             T.tranom                                           Nome, 
             T.traend                                           Rua, 
             Replace(Replace(T.tranumend, 'S/N', ''), 'SN', '') Número, 
             T.tracomplemento                                   Complemento, 
             Replace(T.trabairro, '.', '')                      Bairro, 
             T.tramuncod                                        Cod Município 
             , 
             M.munnom 
             Município, 
             T.tracep                                           Cep, 
             T.trafone                                          Telefone, 
             T.tracelular                                       Celular, 
             T.tranatjuridica                                   juridica, 
             T.tranatfiscal                                     fiscal, 
             T.tranatcomercial                                  comercial, 
             T.tranatsocial                                     social 
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

-------------------------------------------------------------------------------------------------------------------------------------------------------------------

--Abaixo método alternativo:

 

declare @mes int = MONTH(dateadd(m,1,getdate()))         -- função para data que serve de auto incremento para o mês neste caso

                                                         -- várias opções são dadas para os parâmetros da função  dateadd

SELECT                                     
       DAY(T.TraDatNasc) 'Dia',
       T.TraFilCod 'Filial',
       F.FilNomReduzido 'Nome Filial',
       T.TraCod 'Matrícula',
       case T.TraSit
            when 1 then 'Ativo'
            when 2 then 'Inativo'
            else 'Baixado'
       end as 'Cadastro',
       T.TraNom 'Nome',
       T.TraEnd 'Rua',
       Replace(Replace(T.TraNumEnd,'S/N',''),'SN','') 'Número',
       T.TraComplemento 'Complemento',
       Replace(T.TraBairro,'.','') 'Bairro',
       T.TraMunCod 'Cód. Município',
       M.MunNom 'Município',T.TraCep 'CEP',
       T.TraFone 'Telefone',
       T.TraCelular 'Celular',
       case T.TraNatJuridica
            when 1 then 'Física'
       end as 'Nat. Júridica',
       case T.TraNatFiscal
             when 1 then 'Trabalhador urbano'
             when 2 then 'Trabalhador rural'
             when 3 then 'Empresa rural'
             when 4 then 'Empresa rural não contribuinte'
             when 5 then 'Empresa rural contribuinte'
             when 6 then 'Empresa urbana contribuinte'
             when 7 then 'Entidade filantrópica'
             when 8 then 'Associação'    
             when 9 then 'Orgão Público'
             when 10 then 'Cooperativa'
             when 11 then 'Empresa urbana não contribuinte'  
       end as 'Nat. Fiscal',
       case T.TraNatComercial
            when 1 then 'Produtor Rural'  
            when 2 then 'Funcionário'  
            when 3 then 'Cliente'     
            when 4 then 'Fornecedor'    
            when 5 then 'Transportador'     
            when 6 then 'Motorista'          
            when 7 then 'Vendedor'         
            when 8 then 'Banco'    
            when 9 then 'Conveniado'
       end as 'Nat. Comercial',
       case T.TraNatSocial
            when 1 then 'Associado'
            when 3 then 'Não Associado'
       end as 'Nat. Social'
FROM TRANSACIONADORES AS T with (nolock)  INNER JOIN FILIAIS  AS F with (nolock)
                  ON T.TraFilCod = F.FilCod INNER JOIN MUNICIPIOS AS M with (nolock)
                        ON T.tramuncod = M.muncod
WHERE MONTH(T.TraDatNasc) = @mes 
	AND T.TraNatJuridica = 1 
	AND (T.TraNatSociAL IN (1,3))
	AND (T.TraNatSocial = 1 OR T.TraNatComercial = 2)
ORDER BY DAY(T.TraDatNasc), T.TraNom, T.TraNatSocial

 

 

 
 