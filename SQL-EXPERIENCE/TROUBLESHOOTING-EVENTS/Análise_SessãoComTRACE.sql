declare @rc int
declare @TraceID int
declare @maxfilesize bigint
set @maxfilesize = 10000 -- isso em megabytes

exec @rc = sp_trace_create @TraceID output, 0, N'C:\DBACravil\Trace\TraceFilter', @maxfilesize, NULL 
if (@rc != 0) goto error

-- Set the events
declare @on bit
set @on = 1
exec sp_trace_setevent @TraceID, 10, 1, @on 
			exec sp_trace_setevent @TraceID, 10, 6, @on 
			exec sp_trace_setevent @TraceID, 10, 8, @on 
			exec sp_trace_setevent @TraceID, 10, 10, @on
			exec sp_trace_setevent @TraceID, 10, 11, @on
			exec sp_trace_setevent @TraceID, 10, 12, @on
			exec sp_trace_setevent @TraceID, 10, 13, @on
			exec sp_trace_setevent @TraceID, 10, 14, @on
			exec sp_trace_setevent @TraceID, 10, 15, @on
			exec sp_trace_setevent @TraceID, 10, 16, @on
			exec sp_trace_setevent @TraceID, 10, 17, @on
			exec sp_trace_setevent @TraceID, 10, 18, @on
			exec sp_trace_setevent @TraceID, 10, 26, @on
			exec sp_trace_setevent @TraceID, 10, 35, @on
			exec sp_trace_setevent @TraceID, 10, 40, @on
			exec sp_trace_setevent @TraceID, 10, 48, @on
			exec sp_trace_setevent @TraceID, 10, 64, @on
			exec sp_trace_setevent @TraceID, 12, 1,  @on
			exec sp_trace_setevent @TraceID, 12, 6,  @on
			exec sp_trace_setevent @TraceID, 12, 8,  @on
			exec sp_trace_setevent @TraceID, 12, 10, @on
			exec sp_trace_setevent @TraceID, 12, 11, @on
			exec sp_trace_setevent @TraceID, 12, 12, @on
			exec sp_trace_setevent @TraceID, 12, 13, @on
			exec sp_trace_setevent @TraceID, 12, 14, @on
			exec sp_trace_setevent @TraceID, 12, 15, @on
			exec sp_trace_setevent @TraceID, 12, 16, @on
			exec sp_trace_setevent @TraceID, 12, 17, @on
			exec sp_trace_setevent @TraceID, 12, 18, @on
			exec sp_trace_setevent @TraceID, 12, 26, @on
			exec sp_trace_setevent @TraceID, 12, 35, @on
			exec sp_trace_setevent @TraceID, 12, 40, @on
			exec sp_trace_setevent @TraceID, 12, 48, @on
			exec sp_trace_setevent @TraceID, 12, 64, @on


-- Set the Filters
declare @intfilter int
declare @bigintfilter bigint

exec sp_trace_setfilter @TraceID, 1, 0, 6, N'%movestoque%'													-- like - TextData
exec sp_trace_setfilter @TraceID, 8, 0, 6, N'cti-000492'													-- like - HostName
exec sp_trace_setfilter @TraceID, 10, 0, 6, N'%net%'														-- like - ProgramName (no caso dotNet)
exec sp_trace_setfilter @TraceID, 10, 0, 7, N'%Profiler%'													-- not like - ProgramName
exec sp_trace_setfilter @TraceID, 11, 0, 6, N'cravil\ti-04'													-- like - LoginName

--set @bigintfilter = 10000000																				-- duração 10 segundos
--exec sp_trace_setfilter @TraceID, 13, 0, 4, @bigintfilter

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

goto finish

error: 
select ErrorCode=@rc

finish: 
go


------------------------------------------------------------------------------
-- Análise das coletas
------------------------------------------------------------------------------
Select 
Textdata, NTUserName, HostName, ApplicationName, LoginName, SPID, cast(Duration /1000/1000.00 as numeric(15,2)) as DurationSegundos,
	   Duration as DurationMicrossegundos, Starttime, EndTime, Reads, writes, CPU, Servername, DatabaseName, rowcounts, SessionLoginName
FROM :: fn_trace_gettable(N'C:\DBACravil\Trace\TraceFilter.trc', default)
where TextData like '%produtos%'
--order by Starttime


------------------------------------------------------------------------------
-- Antes de excluir arquivo rode query abaixo
------------------------------------------------------------------------------
Declare @Trace_Id int
SELECT @Trace_Id = TraceId
FROM fn_trace_getinfo(0)
where cast(value as varchar(100)) = N'C:\DBACravil\Trace\TraceFilter.trc'

exec sp_trace_setstatus  @traceid = @Trace_Id,  @status = 0  -- Interrompe o rastreamento especificado.
exec sp_trace_setstatus  @traceid = @Trace_Id,  @status = 2  -- Fecha o rastreamento especificado e exclui sua definição do se