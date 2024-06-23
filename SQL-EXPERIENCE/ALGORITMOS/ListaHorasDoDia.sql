-- Listando todas as horas de um dia, com base, na data atual -

Select dateadd(hour,number,dateadd(day,datediff(day,0,getdate()),0))

from master..spt_values n with (nolock)

where number between 0 and 23 and type = 'p'

Go