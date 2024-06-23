USE [master]
GO

EXEC master.dbo.sp_addlinkedserver @server = N'LINK_SERVER_04', @srvproduct=N'', @provider=N'SQLNCLI', @datasrc='159.138.118.3';
GO

EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N'LINK_SERVER_04',@useself=N'True',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'collation compatible', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'data access', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'dist', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'pub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'rpc', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'rpc out', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'sub', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'connect timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'collation name', @optvalue=NULL
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'lazy schema validation', @optvalue=N'false'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'query timeout', @optvalue=N'0'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'use remote collation', @optvalue=N'true'
GO

EXEC master.dbo.sp_serveroption @server=N'LINK_SERVER_04', @optname=N'remote proc transaction promotion', @optvalue=N'false'
GO
