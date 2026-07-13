---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- https://support.microsoft.com/en-us/help/918992/how-to-transfer-logins-and-passwords-between-instances-of-sql-server
-- O result da consulta em cima das procedures � para rodar a cria��o dos logins na outra inst�ncia
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
USE master
GO
IF OBJECT_ID ('sp_hexadecimal') IS NOT NULL
  DROP PROCEDURE sp_hexadecimal
GO
CREATE PROCEDURE sp_hexadecimal
    @binvalue varbinary(256),
    @hexvalue varchar (514) OUTPUT
AS
DECLARE @charvalue varchar (514)
DECLARE @i int
DECLARE @length int
DECLARE @hexstring char(16)
SELECT @charvalue = '0x'
SELECT @i = 1
SELECT @length = DATALENGTH (@binvalue)
SELECT @hexstring = '0123456789ABCDEF'
WHILE (@i <= @length)
BEGIN
  DECLARE @tempint int
  DECLARE @firstint int
  DECLARE @secondint int
  SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
  SELECT @firstint = FLOOR(@tempint/16)
  SELECT @secondint = @tempint - (@firstint*16)
  SELECT @charvalue = @charvalue +
    SUBSTRING(@hexstring, @firstint+1, 1) +
    SUBSTRING(@hexstring, @secondint+1, 1)
  SELECT @i = @i + 1
END

SELECT @hexvalue = @charvalue
GO

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

IF OBJECT_ID ('sp_help_revlogin') IS NOT NULL
  DROP PROCEDURE sp_help_revlogin
GO
CREATE PROCEDURE sp_help_revlogin @login_name sysname = NULL AS
DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC sp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC sp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0
GO


---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Exemplo usado na cravil
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
EXEC sp_help_revlogin

/*********************** RESULTADO ********************************/
/* sp_help_revlogin script 
** Generated Feb 22 2018  1:56PM on SQL01 */
 
 
-- Login: ##MS_PolicyTsqlExecutionLogin##
CREATE LOGIN [##MS_PolicyTsqlExecutionLogin##] WITH PASSWORD = 0x010040D12157103502C8BF90C20E371BABFB2BA9D82A68C90A0B HASHED, SID = 0x014EA8886B841C4CA1F7ED32489BBF62, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF; ALTER LOGIN [##MS_PolicyTsqlExecutionLogin##] DISABLE
 
-- Login: NT AUTHORITY\SYSTEM
CREATE LOGIN [NT AUTHORITY\SYSTEM] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NT SERVICE\MSSQLSERVER
CREATE LOGIN [NT SERVICE\MSSQLSERVER] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: CRAVIL\sqlserver
CREATE LOGIN [CRAVIL\sqlserver] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: NT SERVICE\SQLSERVERAGENT
CREATE LOGIN [NT SERVICE\SQLSERVERAGENT] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: CRAVIL\backupexec
CREATE LOGIN [CRAVIL\backupexec] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: YOUR_DATABASE
CREATE LOGIN [YOUR_DATABASE] WITH PASSWORD = 0x0100C4BFE3A684E571EB68C195ECA41406E131374D73E439F292 HASHED, SID = 0xAB7475E57741BF47B1C3F8B45C2333F6, DEFAULT_DATABASE = [YOUR_DATABASE], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: consulta
CREATE LOGIN [consulta] WITH PASSWORD = 0x0100BA0923E7051861B40026917A4D02D88F323A449E6CDC0D41 HASHED, SID = 0x2A4D3CAB98D32941BA64370F5C06973F, DEFAULT_DATABASE = [YOUR_DATABASE], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: suptcadm
CREATE LOGIN [suptcadm] WITH PASSWORD = 0x01007D2C289D7F4BC5029493604DBABA191263A5BD9D6A495734 HASHED, SID = 0x2D94FBF46B351440A91C07AF1DD80F6E, DEFAULT_DATABASE = [master], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: guru
CREATE LOGIN [guru] WITH PASSWORD = 0x0100B2921A1A144DED7A88D5E4D5200BB5DA5BCFEF23DEBFB57B HASHED, SID = 0xDBAC4BD9BEDDDA4AA630E75ED0FE5EF7, DEFAULT_DATABASE = [Guru5], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: YOUR_DATABASE
CREATE LOGIN [YOUR_DATABASE] WITH PASSWORD = 0x010029CCDEBE4D158BED24FA9C1B71AF7E62F2651A3CDA39F247 HASHED, SID = 0xB29AA6CBC18B954FBA0739A7D2DDA00E, DEFAULT_DATABASE = [YOUR_DATABASE], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: CRAVIL\administrator
CREATE LOGIN [CRAVIL\administrator] FROM WINDOWS WITH DEFAULT_DATABASE = [master]
 
-- Login: CRAVIL\YOUR_DATABASEERP
CREATE LOGIN [CRAVIL\YOUR_DATABASEERP] FROM WINDOWS WITH DEFAULT_DATABASE = [YOUR_DATABASE]
 
-- Login: ##MS_PolicyEventProcessingLogin##
CREATE LOGIN [##MS_PolicyEventProcessingLogin##] WITH PASSWORD = 0x0100592F8E3FA51646B76F66CCA1F8ADD24919CF4480D84D05BC HASHED, SID = 0xC39AEABDA262964183388760A0C5B8E3, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF; ALTER LOGIN [##MS_PolicyEventProcessingLogin##] DISABLE
 
-- Login: vpxuser
CREATE LOGIN [vpxuser] WITH PASSWORD = 0x0100EE85B33AEA96E02B3FCB445A5ABF5A9560A2DB95FB1488D6 HASHED, SID = 0x1EDC75ECF9231E4B9128DC64E11A75FC, DEFAULT_DATABASE = [VCDB], CHECK_POLICY = OFF, CHECK_EXPIRATION = OFF
 
-- Login: CRAVIL\vcenter
CREATE LOGIN [CRAVIL\vcenter] FROM WINDOWS WITH DEFAULT_DATABASE = [VCDB]
 
-- Login: admcravil
CREATE LOGIN [admcravil] WITH PASSWORD = 0x0100F61B2B27573080932D07059654A8650598616D658EEE525B HASHED, SID = 0xAE80B3EAA80DD746BE69EA434B4095E0, DEFAULT_DATABASE = [IntegraTICravil], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infjoabel
CREATE LOGIN [infjoabel] WITH PASSWORD = 0x0100F83617AEF2E34680E8E16EEB9F3109BFA7D9CBFD427E686D HASHED, SID = 0xBED930F0B3A79F4895B98533B6E0E1CC, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: inftiago
CREATE LOGIN [inftiago] WITH PASSWORD = 0x0100205D779457AAE27EA7353551B4E3A9612AA9CACBACDC6F4C HASHED, SID = 0x90F08809DE524440A93C72B814A888FD, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infmarcelo
CREATE LOGIN [infmarcelo] WITH PASSWORD = 0x0100DE15C9AF9143F7DF3839193E7664708C53D6567502524905 HASHED, SID = 0xC976AD0432E52C438876F82D5F0E3937, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infedivan
CREATE LOGIN [infedivan] WITH PASSWORD = 0x0100CBC60827CBD0DCA3CFF3684E11A0DDDC9FA8DA203FC2921F HASHED, SID = 0x8CDCDE9F7060E34BBCA59E26DAC092E3, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infivan
CREATE LOGIN [infivan] WITH PASSWORD = 0x01003DD7DD61EE793F9380F9EBFC097F2D10962E056CDDC87D94 HASHED, SID = 0x054CE4610E81DF46A8EA3378F835EDFB, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infadriano
CREATE LOGIN [infadriano] WITH PASSWORD = 0x0100B64745A9C18183565B4A32AE9832ECD40DF2D7B30BE23B4A HASHED, SID = 0x733D4B351AED33429566EB65C30E09D8, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infedivaldo
CREATE LOGIN [infedivaldo] WITH PASSWORD = 0x01001F4476F77F184FAA474116D2BDC7D8AEA7D16D91A2786B9A HASHED, SID = 0x4430DB9445D2B5459825B1556DF84063, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infjehan
CREATE LOGIN [infjehan] WITH PASSWORD = 0x0100BDEDB6584DF8F44DA450668E6D7A5EF6AC0CF11FA7A89C3F HASHED, SID = 0x0FBB518877815748BDB79D735B366F2A, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infeliezer
CREATE LOGIN [infeliezer] WITH PASSWORD = 0x010099FE6009AFB1D0A3CD188C840C158B6BD9B6DF797EDB4170 HASHED, SID = 0x385C47D7390F5941BFB82C00CD7FB34C, DEFAULT_DATABASE = [master], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: agrosystem
CREATE LOGIN [agrosystem] WITH PASSWORD = 0x01006662583E116ECC08CB5AA795EE0D56C27C00AC50D2A3CBD6 HASHED, SID = 0xCA9F5559E34A4948A3CC39E9F6EB3EA6, DEFAULT_DATABASE = [YOUR_DATABASE], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF
 
-- Login: infneimar
CREATE LOGIN [infneimar] WITH PASSWORD = 0x01007A0440EFCE5C82BF484EBD785183C85146AAF869E0A715EC HASHED, SID = 0xA21CDDE48A95124BA0DF5C9C5A1CB033, DEFAULT_DATABASE = [YOUR_DATABASE], CHECK_POLICY = ON, CHECK_EXPIRATION = OFF

