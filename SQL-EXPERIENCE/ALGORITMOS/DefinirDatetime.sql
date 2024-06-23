
select  dateadd(MILLISECOND,+997,dateadd(SECOND,+59,dateadd(MINUTE,+59,dateadd(HOUR,+23,dateadd(day,-1,  
		
		cast(floor(cast(getdate()as float))as datetime)  -- floor usado para zerar e depois poder setar hora, minuto, etc
		)--dia
		)--hora
		)--minutos
		)--segundos
		)--milissegundos