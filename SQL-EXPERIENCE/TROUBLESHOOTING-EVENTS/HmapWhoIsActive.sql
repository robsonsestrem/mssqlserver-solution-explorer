EXECUTE sp_WhoIsActive 
  @show_own_spid = 0				   
, @show_system_spids = 0			
, @show_sleeping_spids = 1	 		 
, @get_outer_command = 1
--, @filter = 'P_HEALTHMAP_CAREPLUS'
--, @filter_type = 'database'	
--, @get_task_info = 2					
--, @get_locks = 1					
, @get_additional_info = 1			
--, @find_block_leaders = 1			
--, @sort_order = '[cpu] desc'		   
, @get_plans = 1					
, @output_column_list ='[additional_info], [status], [dd hh:mm:ss.mss], [session_id], [login_name], [host_name], [database_name], [CPU], [context_switches], [physical_io], [physical_reads], [reads], [writes], [used_memory], [tempdb_allocations], [tempdb_current], [tasks], [open_tran_count], [wait_info], [locks], [blocking_session_id], [blocked_session_count] [program_name], [start_time], [login_time], [collection_time], [percent_complete], [request_id], [sql_text], [sql_command], [additional_info], [query_plan]'


-- KILL 399 WITH STATUSONLY 




