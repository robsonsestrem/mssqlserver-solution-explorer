select * from Management.vw_MonioringLogRecords as t1
where t1.database_transaction_log_record_count <> 0


select * from Management.vw_MonitoringLogRecordsPaul as t1
where t1.[Log Bytes] <> 0