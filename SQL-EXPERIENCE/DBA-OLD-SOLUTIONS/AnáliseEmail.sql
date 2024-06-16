use Maintenance
go

select * from Management.vw_MonitoringEmail
where DataEnvio between '20170623 00:00:00.000' and '20170623 23:59:59.997'