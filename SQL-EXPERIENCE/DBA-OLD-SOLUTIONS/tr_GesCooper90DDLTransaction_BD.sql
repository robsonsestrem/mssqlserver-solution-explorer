USE GesCooper90
GO
 
ALTER TRIGGER [tr_GesCooper90DDLTransaction_BD]
On Database
WITH ENCRYPTION 
For DDL_DATABASE_LEVEL_EVENTS
As
 Begin
  Set NoCount On
  Declare @DadosXML XML
  Set @DadosXML=EVENTDATA()

  Insert Into IntegraTICravil.Management.DDLTransaction(
						EventType,
						ObjectName,
						ObjectType,
						Query)
						Values(
						@DadosXML.value('(EVENT_INSTANCE/EventType)[1]','NVarchar(200)') ,
						@DadosXML.value('(EVENT_INSTANCE/ObjectName)[1]','NVarchar(200)') ,
						@DadosXML.value('(EVENT_INSTANCE/ObjectType)[1]','NVarchar(200)') ,
						@DadosXML.value('(EVENT_INSTANCE/TSQLCommand/CommandText)[1]','NVarchar(Max)')				
						)
 End 
GO


----------------------------------------------------------------------------------------------------------------------
-- Tabela dedo duro
----------------------------------------------------------------------------------------------------------------------

--use IntegraTICravil
--go
--Create Table Management.DDLTransaction
--(
-- TransID Int Identity(1,1) Primary Key,
-- DateDDl smallDateTime Default GetDate(),
-- DatabaseUser VarChar(100) Default User_Name(),
-- LoginUser Varchar(100) Default Suser_Name(),
-- LoginUserSQLTransaction Varchar(100) Default Original_Login(),
-- Hostname varchar(100) Default host_name(),
-- EventType NVarchar(200) default '',
-- ObjectName NVarchar(200) default '',
-- ObjectType NVarchar(200) default '',
-- Query NVarchar(Max) default ''
 
-- )