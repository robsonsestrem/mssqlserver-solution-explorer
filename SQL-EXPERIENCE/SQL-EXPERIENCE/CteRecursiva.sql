create table #Atendimentos 
(id_Status_Entrega int identity primary Key,
id_Aviso_Receb int,
Situacao int, 
DataHoraRegistro datetime default getdate(),
Quem_Recebeu varchar(20))

insert into #Atendimentos
(id_Aviso_Receb, Situacao, DataHoraRegistro, Quem_Recebeu)
values (52505,0,'2014-12-29 11:36', 'julio.mallioti'),
(52505,1,'2014-12-29 13:05', 'julio.mallioti'),
(52505,2,'2014-12-29 14:05', 'julio.mallioti')


;with cte 
as
(select * , row_number()over(partition by id_Aviso_Receb order by Situacao) as rownum
 from #Atendimentos
),
cte2 
as
(select *, cast(NULL as datetime) Diferenca from cte where rownum = 1 --anchor
  union all
 select cte.*, cast((cte.DataHoraRegistro - cte2.DataHoraRegistro) as Datetime) Diferenca
 from cte join cte2 
  on cte.rownum = cte2.rownum+1 
  and cte.id_Aviso_Receb = cte2.id_Aviso_Receb)

select *, cast(diferenca as time) Diferenca_Time
from cte2
order by id_Aviso_Receb, Situacao 


drop table #Atendimentos