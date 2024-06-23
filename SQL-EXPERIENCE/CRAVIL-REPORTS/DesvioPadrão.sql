 
select
      deriva.Item as Item
      , deriva.Dia as Dia
      , case  when deriva.Dia = 'Seg' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
                  when deriva.Dia = 'Ter' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
                  when deriva.Dia = 'Qua' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
                  when deriva.Dia = 'Qui' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
                  when deriva.Dia = 'Sex' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
                  when deriva.Dia = 'Sab' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
                  when deriva.Dia = 'Dom' then avg(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade))))
        end as MédiaQtdade
      , case  when deriva.Dia = 'Seg' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
                  when deriva.Dia = 'Ter' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
                  when deriva.Dia = 'Qua' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
                  when deriva.Dia = 'Qui' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
                  when deriva.Dia = 'Sex' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
                  when deriva.Dia = 'Sab' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
                  when deriva.Dia = 'Dom' then isnull(stdev(convert(Numeric(10,2),(convert(char(12),deriva.Qtdade)))), '')
        end as Desvio Padrão 
 
from
            (select
           REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(DATEPART(WEEKDAY,m.NfDatEmis)
           ,1,'Dom'),2,'Seg'),3,'Ter'),4,'Qua'),5,'Qui'),6,'Sex'),7,'Sab') as Dia
           ,mum.ItemProCod as Item
           ,mum.ItemQtdade as Qtdade
           from MOVESTOQUE as m with (nolock)inner join MOVESTOQUELEVEL1 as mum with (nolock)
                    on mum.NfFilCod = m.NfFilCod and mum.NfDatEmis = m.NfDatEmis and mum.nfnumero = m.nfnumero                 
           where m.NfeCStat not in (101, 102)                                --desconsidera notas canceladas
                 and m.NfOpeEstCod in (46)                                   --operação de transferência         
                     and m.NfDatEmis  between '2014-01-01' and '2014-08-31'  --filtrar data necessária                       
                         and m.NfSituacao in (2, 3)                        
                             and m.NfFilCod in(76)                           --verificar quais filiais vão             
     ) as deriva
group by deriva.Dia, deriva.Item
 
 
 
 
 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 

 


 


 

 

 
 
 