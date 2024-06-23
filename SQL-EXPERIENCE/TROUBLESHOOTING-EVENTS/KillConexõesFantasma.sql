-----------------------------------------------------------------------------------------------------------
--						Matar conexões fantasma
-----------------------------------------------------------------------------------------------------------
declare @killspidpreza varchar(30)

declare kill_proc_preza cursor for

select 'kill ' + cast(t1.spid as varchar(10))
from sys.sysprocesses as t1 inner join sys.dm_exec_sessions as t2
on t1.spid = t2.session_id
where t1.status = 'sleeping' 
and t1.open_tran = 0 
and t2.is_user_process = 1
and hostname <> 'CRVSQL01'

open kill_proc_preza
fetch next from kill_proc_preza into @killspidpreza

while @@fetch_status = 0
	begin
	   execute (@killspidpreza)
	   fetch next from kill_proc_preza into @killspidpreza
	end
close kill_proc_preza
deallocate kill_proc_preza



